class_name ExplorerApp
extends Control

## Интерактивный Проводник («Мой компьютер») и «Корзина» в стиле Windows 98/2000.
## Поддерживает навигацию по папкам, парольную защиту для папки «Работа»
## через GameState и просмотр удалённых файлов в Корзине (включая накладную с фурой 6752).

signal directory_changed(new_path: String)
signal file_opened(file_name: String)

@export var initial_path: String = "C:\\ROOT_ACCESS"
@export var mode: String = "computer" # "computer" или "recycle"

# Узлы тулбара и адреса
@onready var btn_back: Button = $VBox/Toolbar/ToolbarRow/BtnBack
@onready var btn_forward: Button = $VBox/Toolbar/ToolbarRow/BtnForward
@onready var btn_up: Button = $VBox/Toolbar/ToolbarRow/BtnUp
@onready var btn_open: Button = $VBox/Toolbar/ToolbarRow/BtnOpen
@onready var address_label: Label = $VBox/AddressBar/AddressMargin/AddressRow/AddressEdit

# Сайдбар
@onready var sidebar_container: VBoxContainer = $VBox/ContentMargin/Split/Sidebar/SidebarMargin/SidebarVBox/SidebarItems

# Список файлов
@onready var file_list_container: VBoxContainer = $VBox/ContentMargin/Split/FilePanel/FileScroll/FileListVBox

# Статус бар
@onready var status_left: Label = $VBox/StatusBar/StatusMargin/StatusRow/StatusLeft
@onready var status_right: Label = $VBox/StatusBar/StatusMargin/StatusRow/StatusRight

# Модальное окно пароля
@onready var password_overlay: Control = $PasswordOverlay
@onready var password_input: LineEdit = $PasswordOverlay/Center/PasswordDialog/DialogVBox/ContentRow/InputVBox/PasswordInput
@onready var password_error: Label = $PasswordOverlay/Center/PasswordDialog/DialogVBox/ContentRow/InputVBox/ErrorLabel
@onready var btn_password_ok: Button = $PasswordOverlay/Center/PasswordDialog/DialogVBox/ButtonRow/BtnOk
@onready var btn_password_cancel: Button = $PasswordOverlay/Center/PasswordDialog/DialogVBox/ButtonRow/BtnCancel

# Модальное окно просмотра файла
@onready var preview_overlay: Control = $PreviewOverlay
@onready var preview_title: Label = $PreviewOverlay/Center/PreviewDialog/DialogVBox/TitleBar/TitleLabel
@onready var preview_text: RichTextLabel = $PreviewOverlay/Center/PreviewDialog/DialogVBox/TextPanel/Margin/PreviewText
@onready var btn_preview_notes: Button = $PreviewOverlay/Center/PreviewDialog/DialogVBox/ButtonRow/BtnOpenNotes
@onready var btn_preview_close: Button = $PreviewOverlay/Center/PreviewDialog/DialogVBox/ButtonRow/BtnClose

# Модальное окно аудиоплеера (record.wav)
@onready var audio_overlay: Control = $AudioOverlay
@onready var audio_time_label: Label = $AudioOverlay/Center/AudioDialog/DialogVBox/ContentMargin/VBox/WaveformPanel/WaveformMargin/WaveformVBox/WaveHeader/TimeLabel
@onready var audio_wave_visual: RichTextLabel = $AudioOverlay/Center/AudioDialog/DialogVBox/ContentMargin/VBox/WaveformPanel/WaveformMargin/WaveformVBox/WaveVisual
@onready var audio_progress: ProgressBar = $AudioOverlay/Center/AudioDialog/DialogVBox/ContentMargin/VBox/WaveformPanel/WaveformMargin/WaveformVBox/AudioProgress
@onready var audio_subtitles: RichTextLabel = $AudioOverlay/Center/AudioDialog/DialogVBox/ContentMargin/VBox/SubtitlesPanel/SubtitlesMargin/SubtitlesText
@onready var btn_play_audio: Button = $AudioOverlay/Center/AudioDialog/DialogVBox/ButtonRow/BtnPlayAudio
@onready var btn_stop_audio: Button = $AudioOverlay/Center/AudioDialog/DialogVBox/ButtonRow/BtnStopAudio
@onready var btn_close_audio: Button = $AudioOverlay/Center/AudioDialog/DialogVBox/ButtonRow/BtnCloseAudio

# Иконки
const ICON_DRIVE := preload("res://assets/icons/drive.svg")
const ICON_FOLDER := preload("res://assets/icons/folder.svg")
const ICON_FILE := preload("res://assets/icons/file_text.svg")
const ICON_PHOTO := preload("res://assets/icons/photo.svg")
const ICON_LOCK := preload("res://assets/icons/lock.svg")
const ICON_RECYCLE := preload("res://assets/icons/recycle_bin.svg")
const ICON_COMPUTER := preload("res://assets/icons/computer.svg")
const ICON_SPEAKER := preload("res://assets/icons/speaker.svg")

# Цвета ретро-интерфейса
const C_NAVY := Color(0, 0, 0.501961, 1.0)
const C_WHITE := Color(1, 1, 1, 1)
const C_BLACK := Color(0, 0, 0, 1)
const C_GRAY := Color(0.501961, 0.501961, 0.501961, 1.0)
const C_DARK_GRAY := Color(0.25, 0.25, 0.25, 1.0)

var current_path: String = "C:\\ROOT_ACCESS"
var _history_back: Array[String] = []
var _history_forward: Array[String] = []
var _selected_item: Dictionary = {}
var _selected_row_control: Control = null
var _last_clicked_name: String = ""
var _last_click_time: float = 0.0

var _bold_font: SystemFont
var _mono_font: SystemFont
var _sans_font: SystemFont

var _is_audio_playing: bool = false
var _audio_playback_time: float = 0.0
const AUDIO_DURATION: float = 8.0

func _ready() -> void:
	_init_fonts()
	_connect_signals()
	
	password_overlay.visible = false
	preview_overlay.visible = false
	if audio_overlay:
		audio_overlay.visible = false
	
	if mode == "recycle":
		current_path = "C:\\ROOT_ACCESS\\Корзина"
	elif initial_path != "":
		current_path = initial_path
	
	if GameState:
		if not GameState.location_decrypted.is_connected(_on_location_decrypted):
			GameState.location_decrypted.connect(_on_location_decrypted)
		if not GameState.folder_unlocked.is_connected(_on_folder_unlocked):
			GameState.folder_unlocked.connect(_on_folder_unlocked)
	
	_build_sidebar()
	navigate_to(current_path, false)

func _process(delta: float) -> void:
	if _is_audio_playing:
		_audio_playback_time += delta
		if audio_progress:
			audio_progress.value = minf(_audio_playback_time, AUDIO_DURATION)
		if audio_time_label:
			var sec := int(_audio_playback_time)
			audio_time_label.text = "%02d:%02d / 00:08" % [sec / 60, sec % 60]
		
		if audio_wave_visual:
			var t := int(_audio_playback_time * 10) % 4
			match t:
				0: audio_wave_visual.text = " ▂▃▅▆▇██▇▆▅▃▂  ▂▃▄▅▆▇████▇▆▅▄▃▂   ▂▃▄▅▆▇██▇▆▅▃▂"
				1: audio_wave_visual.text = "▃▅▆▇████▇▆▅▃▂   ▂▃▄▅▆▇██▇▆▅▄▃▂  ▂▃▄▅▆▇████▇▆▅▃"
				2: audio_wave_visual.text = "▇████▇▆▅▄▃▂  ▂▃▄▅▆▇████▇▆▅▄▃▂   ▂▃▄▅▆▇██▇▆▅▄▃▂"
				3: audio_wave_visual.text = "▅▆▇██▇▆▅▃▂   ▂▃▄▅▆▇████▇▆▅▄▃▂  ▂▃▄▅▆▇████▇▆▅▃▂"
		
		if _audio_playback_time >= AUDIO_DURATION:
			_on_audio_finished()

func _init_fonts() -> void:
	_sans_font = SystemFont.new()
	_sans_font.font_names = PackedStringArray(["Tahoma", "MS Sans Serif", "Segoe UI", "Arial"])
	_sans_font.antialiasing = 0
	_sans_font.subpixel_positioning = 0
	_sans_font.hinting = 1

	_bold_font = SystemFont.new()
	_bold_font.font_names = PackedStringArray(["Tahoma", "MS Sans Serif", "Segoe UI", "Arial"])
	_bold_font.font_weight = 700
	_bold_font.antialiasing = 0
	_bold_font.subpixel_positioning = 0
	_bold_font.hinting = 1

	_mono_font = SystemFont.new()
	_mono_font.font_names = PackedStringArray(["Lucida Console", "Consolas", "Courier New", "DejaVu Sans Mono"])
	_mono_font.antialiasing = 0
	_mono_font.subpixel_positioning = 0
	_mono_font.hinting = 1

func _connect_signals() -> void:
	btn_back.pressed.connect(_go_back)
	btn_forward.pressed.connect(_go_forward)
	btn_up.pressed.connect(_go_up)
	btn_open.pressed.connect(_on_btn_open_pressed)
	
	btn_password_ok.pressed.connect(_on_password_ok_pressed)
	btn_password_cancel.pressed.connect(_on_password_cancel_pressed)
	password_input.text_submitted.connect(func(_t): _on_password_ok_pressed())
	
	btn_preview_close.pressed.connect(func(): preview_overlay.visible = false)
	btn_preview_notes.pressed.connect(_on_preview_open_in_notes)
	
	if btn_play_audio:
		btn_play_audio.pressed.connect(_play_audio_record)
	if btn_stop_audio:
		btn_stop_audio.pressed.connect(_stop_audio_record)
	if btn_close_audio:
		btn_close_audio.pressed.connect(func():
			_stop_audio_record()
			if audio_overlay:
				audio_overlay.visible = false
		)

func _build_sidebar() -> void:
	for child in sidebar_container.get_children():
		child.queue_free()

	_add_sidebar_item("Локальный диск (C:)", "C:\\ROOT_ACCESS", ICON_DRIVE)
	_add_sidebar_item("Документы", "C:\\ROOT_ACCESS\\Документы", ICON_FOLDER)
	
	var is_locked = not (GameState and GameState.is_work_folder_unlocked)
	_add_sidebar_item("Работа", "C:\\ROOT_ACCESS\\Работа", ICON_FOLDER, is_locked)
	
	_add_sidebar_item("Изображения", "C:\\ROOT_ACCESS\\Изображения", ICON_PHOTO)
	_add_sidebar_item("Корзина", "C:\\ROOT_ACCESS\\Корзина", ICON_RECYCLE)

func _add_sidebar_item(title: String, target_path: String, icon: Texture2D, show_lock: bool = false) -> void:
	var btn := Button.new()
	btn.text = "  " + title
	btn.icon = icon
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.custom_minimum_size = Vector2(0, 24)
	btn.add_theme_font_override("font", _sans_font)
	btn.add_theme_font_size_override("font_size", 11)
	btn.add_theme_constant_override("icon_max_width", 16)
	
	if show_lock:
		var lock_tex := TextureRect.new()
		lock_tex.texture = ICON_LOCK
		lock_tex.custom_minimum_size = Vector2(14, 14)
		lock_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lock_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lock_tex.anchor_left = 1.0
		lock_tex.anchor_right = 1.0
		lock_tex.anchor_top = 0.5
		lock_tex.anchor_bottom = 0.5
		lock_tex.offset_left = -20
		lock_tex.offset_top = -7
		lock_tex.offset_right = -6
		lock_tex.offset_bottom = 7
		btn.add_child(lock_tex)
	
	btn.pressed.connect(func():
		_on_sidebar_item_clicked(title, target_path)
	)
	sidebar_container.add_child(btn)

func _on_sidebar_item_clicked(title: String, target_path: String) -> void:
	if title == "Работа" or target_path.ends_with("\\Работа"):
		if GameState and not GameState.is_work_folder_unlocked:
			_show_password_dialog()
			return
	navigate_to(target_path)

## Главный метод навигации по путям
func navigate_to(path: String, add_to_history: bool = true) -> void:
	# Проверка на закрытую папку Работа
	if (path.ends_with("\\Работа") or path == "Работа") and GameState and not GameState.is_work_folder_unlocked:
		_show_password_dialog()
		return

	if add_to_history and current_path != path:
		_history_back.append(current_path)
		_history_forward.clear()

	current_path = path
	_update_nav_buttons()
	_update_address_bar()
	_render_directory_contents()
	directory_changed.emit(current_path)
	
	# Сюжетные триггеры
	if current_path.ends_with("\\Корзина") and GameState:
		GameState.is_trash_inspected = true
		if GameState.current_difficulty == GameState.Difficulty.EASY:
			GameState.trigger_thought("Ник: «Корзина... Саймон писал в заметке, что удалил накладную. Надо проверить!»", true)

func _update_nav_buttons() -> void:
	btn_back.disabled = _history_back.is_empty()
	btn_forward.disabled = _history_forward.is_empty()
	btn_up.disabled = (current_path == "C:\\ROOT_ACCESS" or current_path == "C:\\")

func _update_address_bar() -> void:
	if current_path.ends_with("\\Корзина"):
		address_label.text = "Корзина"
	elif current_path == "C:\\ROOT_ACCESS":
		address_label.text = "C:\\ROOT_ACCESS"
	else:
		address_label.text = current_path

func _go_back() -> void:
	if _history_back.is_empty():
		return
	var prev = _history_back.pop_back()
	_history_forward.append(current_path)
	navigate_to(prev, false)

func _go_forward() -> void:
	if _history_forward.is_empty():
		return
	var next_path = _history_forward.pop_back()
	_history_back.append(current_path)
	navigate_to(next_path, false)

func _go_up() -> void:
	if current_path == "C:\\ROOT_ACCESS" or current_path == "C:\\":
		return
	navigate_to("C:\\ROOT_ACCESS")

func _render_directory_contents() -> void:
	for child in file_list_container.get_children():
		child.queue_free()
	
	_selected_item = {}
	_selected_row_control = null
	
	var vfs = VFS.get_vfs() if VFS else null
	var items: Array = []
	if vfs:
		items = vfs.list_dir(current_path)
	
	# Фильтрация технических дубликатов верхнего регистра если есть русские аналоги
	var filtered: Array = []
	var has_doc_ru = false
	var has_work_ru = false
	var has_pic_ru = false
	var has_rec_ru = false
	for it in items:
		if it["name"] == "Документы": has_doc_ru = true
		if it["name"] == "Работа": has_work_ru = true
		if it["name"] == "Изображения": has_pic_ru = true
		if it["name"] == "Корзина": has_rec_ru = true
	
	for it in items:
		var n = it["name"]
		if has_doc_ru and n == "DOCUMENTS": continue
		if has_work_ru and n == "WORK": continue
		if has_pic_ru and n == "PICTURES": continue
		if has_rec_ru and n == "RECYCLE_BIN": continue
		# В корне показываем только папки и ключевые файлы, чтобы вид был чистым
		filtered.append(it)

	for i in range(filtered.size()):
		var it = filtered[i]
		var row := _create_file_row(it, i % 2 == 1)
		file_list_container.add_child(row)

	status_left.text = "%d объектов" % filtered.size()
	if current_path.ends_with("\\Корзина"):
		status_right.text = "1,8 КБ"
	else:
		status_right.text = "12,4 ГБ свободно"

func _create_file_row(item_data: Dictionary, alt_bg: bool) -> PanelContainer:
	var row := PanelContainer.new()
	row.set_meta("item_data", item_data)
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.96, 0.96, 0.96) if alt_bg else C_WHITE
	style.content_margin_left = 4.0
	style.content_margin_top = 2.0
	style.content_margin_right = 4.0
	style.content_margin_bottom = 2.0
	style.border_width_bottom = 1
	style.border_color = Color(0.9, 0.9, 0.9, 1)
	row.add_theme_stylebox_override("panel", style)
	
	var hbox := HBoxContainer.new()
	hbox.custom_minimum_size = Vector2(0, 24)
	hbox.add_theme_constant_override("separation", 6)
	row.add_child(hbox)
	
	# Иконка
	var icon_tex := _get_icon_for_item(item_data)
	var icon_rect := TextureRect.new()
	icon_rect.texture = icon_tex
	icon_rect.custom_minimum_size = Vector2(18, 18)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(icon_rect)
	
	# Имя
	var name_label := Label.new()
	name_label.text = item_data["name"]
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_override("font", _sans_font)
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", C_BLACK)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(name_label)
	
	# Если это заблокированная папка Работа
	if item_data["name"] == "Работа" and GameState and not GameState.is_work_folder_unlocked:
		var lock := TextureRect.new()
		lock.texture = ICON_LOCK
		lock.custom_minimum_size = Vector2(14, 14)
		lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lock.tooltip_text = "Папка защищена паролем"
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(lock)

	# Тип
	var type_label := Label.new()
	type_label.text = item_data.get("type_str", "Папка" if item_data["is_dir"] else "Документ")
	type_label.custom_minimum_size = Vector2(130, 0)
	type_label.add_theme_font_override("font", _sans_font)
	type_label.add_theme_font_size_override("font_size", 11)
	type_label.add_theme_color_override("font_color", C_DARK_GRAY)
	type_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(type_label)
	
	# Размер
	var size_label := Label.new()
	size_label.text = item_data.get("size_str", "")
	size_label.custom_minimum_size = Vector2(80, 0)
	size_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	size_label.add_theme_font_override("font", _sans_font)
	size_label.add_theme_font_size_override("font_size", 11)
	size_label.add_theme_color_override("font_color", C_DARK_GRAY)
	size_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(size_label)

	# Дата
	var date_label := Label.new()
	date_label.text = item_data.get("date_str", "02.10.2009 01:45")
	date_label.custom_minimum_size = Vector2(120, 0)
	date_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	date_label.add_theme_font_override("font", _sans_font)
	date_label.add_theme_font_size_override("font_size", 10)
	date_label.add_theme_color_override("font_color", C_GRAY)
	date_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(date_label)
	
	row.gui_input.connect(func(event: InputEvent):
		_on_row_gui_input(event, row, item_data)
	)
	
	return row

func _get_icon_for_item(item_data: Dictionary) -> Texture2D:
	var name: String = item_data["name"]
	if item_data.get("is_dir", false):
		if name == "Корзина" or name == "RECYCLE_BIN":
			return ICON_RECYCLE
		return ICON_FOLDER
	if name.ends_with(".enc"):
		return ICON_LOCK
	if name.ends_with(".wav"):
		return ICON_SPEAKER
	if name.ends_with(".jpg") or name.ends_with(".png"):
		return ICON_PHOTO
	return ICON_FILE

func _on_row_gui_input(event: InputEvent, row: PanelContainer, item_data: Dictionary) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse := event as InputEventMouseButton
	if not mouse.pressed or mouse.button_index != MOUSE_BUTTON_LEFT:
		return
		
	var now = Time.get_ticks_msec() / 1000.0
	var is_double = (_last_clicked_name == item_data["name"] and (now - _last_click_time) < 0.4)
	_last_clicked_name = item_data["name"]
	_last_click_time = now
	
	_select_row(row, item_data)
	
	if is_double or mouse.double_click:
		_activate_item(item_data)

func _select_row(row: PanelContainer, item_data: Dictionary) -> void:
	if is_instance_valid(_selected_row_control) and _selected_row_control != row:
		_unstyle_row(_selected_row_control)
		
	_selected_row_control = row
	_selected_item = item_data
	
	# Стиль выделения Windows 98 (тёмно-синий фон, белый текст)
	var style := StyleBoxFlat.new()
	style.bg_color = C_NAVY
	style.content_margin_left = 4.0
	style.content_margin_top = 2.0
	style.content_margin_right = 4.0
	style.content_margin_bottom = 2.0
	row.add_theme_stylebox_override("panel", style)
	
	var hbox = row.get_child(0) as HBoxContainer
	for child in hbox.get_children():
		if child is Label:
			child.add_theme_color_override("font_color", C_WHITE)
			
	status_left.text = "Выбран объект: %s (%s)" % [item_data["name"], item_data.get("type_str", "")]

func _unstyle_row(row: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = C_WHITE
	style.content_margin_left = 4.0
	style.content_margin_top = 2.0
	style.content_margin_right = 4.0
	style.content_margin_bottom = 2.0
	style.border_width_bottom = 1
	style.border_color = Color(0.9, 0.9, 0.9, 1)
	row.add_theme_stylebox_override("panel", style)
	
	var hbox = row.get_child(0) as HBoxContainer
	for child in hbox.get_children():
		if child is Label:
			child.add_theme_color_override("font_color", C_BLACK)

func _activate_item(item_data: Dictionary) -> void:
	var name: String = item_data["name"]
	
	if item_data.get("is_dir", false):
		if name == "Работа" or name == "WORK":
			if GameState and not GameState.is_work_folder_unlocked:
				_show_password_dialog()
				return
		var next_path = current_path + "\\" + name
		navigate_to(next_path)
		return
		
	# Если это файл
	var file_path = current_path + "\\" + name
	if name.ends_with(".enc"):
		_show_preview("Ошибка чтения: " + name, 
			"[color=#800000][b]НЕВОЗМОЖНО ОТКРЫТЬ ФАЙЛ[/b][/color]\n\n" +
			"Формат файла не распознан или данные зашифрованы (заголовок 0x7F454C46).\n" +
			"Отображение содержимого в текстовом режиме недоступно.\n\n" +
			"[b]Подсказка:[/b] Для дешифрования контейнера используйте Терминал: [code]decrypt location.enc -k <ключ>[/code]. См. файл «инструкция_шифрование.txt» в текущей папке.",
			false
		)
		return

	if name.ends_with(".wav"):
		_show_audio_player()
		file_opened.emit(name)
		return
		
	if name.ends_with(".txt"):
		var vfs = VFS.get_vfs() if VFS else null
		var text_content = ""
		if vfs:
			var res = vfs.read_file(file_path)
			text_content = res.get("content", "Не удалось прочесть файл.")
			
		_show_preview(name, text_content, true)
		file_opened.emit(name)
		
		if name.contains("накладная_доставка") and GameState:
			GameState.is_trash_inspected = true

func _on_btn_open_pressed() -> void:
	if not _selected_item.is_empty():
		_activate_item(_selected_item)

# ---------------------------------------------------------------------------
# Модальное окно ввода пароля от папки «Работа»
# ---------------------------------------------------------------------------

func _show_password_dialog() -> void:
	password_input.text = ""
	password_error.text = ""
	password_overlay.visible = true
	password_input.grab_focus()

func _on_password_ok_pressed() -> void:
	var pwd = password_input.text.strip_edges()
	if pwd == "":
		password_error.text = "Введите пароль!"
		return
		
	var is_valid = false
	if GameState:
		is_valid = GameState.verify_work_password(pwd)
	else:
		is_valid = (pwd == "2409" or pwd == "24.09" or pwd == "24092009")
		
	if is_valid:
		password_overlay.visible = false
		_build_sidebar()
		navigate_to("C:\\ROOT_ACCESS\\Работа")
		if GameState and GameState.current_difficulty == GameState.Difficulty.EASY:
			GameState.trigger_thought("Ник: «Пароль подошёл! Папка «Работа» открыта. Посмотрим на улики...»", true)
	else:
		password_error.text = "Неверный пароль. Доступ запрещен!"
		password_input.select_all()

func _on_password_cancel_pressed() -> void:
	password_overlay.visible = false

# ---------------------------------------------------------------------------
# Модальное окно быстрого просмотра текста
# ---------------------------------------------------------------------------

var _preview_current_file: String = ""

func _show_preview(title: String, content: String, can_open_in_notes: bool) -> void:
	_preview_current_file = title
	preview_title.text = "Просмотр файла — " + title
	preview_text.text = content
	btn_preview_notes.visible = can_open_in_notes
	preview_overlay.visible = true

func _on_preview_open_in_notes() -> void:
	preview_overlay.visible = false
	# Находим рабочий стол и открываем Заметки
	var desktop = _find_desktop()
	if desktop:
		desktop.open_app("notes")
		var notes_window = desktop._find_window("notes")
		if notes_window and notes_window.content_container.get_child_count() > 0:
			var notes_app = notes_window.content_container.get_child(0) as NotesApp
			if notes_app:
				notes_app.open_note(_preview_current_file)

func _find_desktop() -> Desktop:
	var node: Node = self
	while node:
		if node is Desktop:
			return node
		node = node.get_parent()
	return null

# ---------------------------------------------------------------------------
# Модальное окно аудиоплеера (record.wav)
# ---------------------------------------------------------------------------

func _show_audio_player() -> void:
	if not audio_overlay:
		return
	audio_overlay.visible = true
	_play_audio_record()

func _play_audio_record() -> void:
	_is_audio_playing = true
	_audio_playback_time = 0.0
	if btn_play_audio:
		btn_play_audio.disabled = true
	if btn_stop_audio:
		btn_stop_audio.disabled = false
	if audio_progress:
		audio_progress.value = 0.0
	if audio_time_label:
		audio_time_label.text = "00:00 / 00:08"
	if audio_subtitles:
		audio_subtitles.text = "[color=#000000][b]Саймон:[/b] «...время почти вышло. Грузовик 6-7-5-2... Она останется здесь навсегда...»[/color]"

func _stop_audio_record() -> void:
	_is_audio_playing = false
	if btn_play_audio:
		btn_play_audio.disabled = false
	if btn_stop_audio:
		btn_stop_audio.disabled = true

func _on_audio_finished() -> void:
	_stop_audio_record()
	if audio_progress:
		audio_progress.value = AUDIO_DURATION
	if audio_time_label:
		audio_time_label.text = "00:08 / 00:08"
	if GameState:
		GameState.mark_audio_listened()

## Быстрый вызов завершения аудио для автотестов
func simulate_audio_finish() -> void:
	_show_audio_player()
	_on_audio_finished()

func _on_location_decrypted() -> void:
	_render_directory_contents()

func _on_folder_unlocked(_folder: String) -> void:
	_build_sidebar()
	_render_directory_contents()

