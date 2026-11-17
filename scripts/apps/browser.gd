class_name BrowserApp
extends Control

## Ретро-браузер и встроенный веб-мессенджер.
##
## История и переписка читаются из data/files.json. Клик по записи
## «Мессенджер: Юджин Рейвенс (Брат)» открывает чат братьев; остальные
## записи показывают заглушку локального кэша.

const C_FACE := Color(0.752941, 0.752941, 0.752941, 1.0)
const C_NAVY := Color(0, 0, 0.501961, 1.0)
const C_DARK_NAVY := Color(0, 0, 0.35, 1.0)
const C_WHITE := Color(1, 1, 1, 1)
const C_GRAY := Color(0.501961, 0.501961, 0.501961, 1.0)
const C_DARK_GRAY := Color(0.25, 0.25, 0.25, 1.0)
const C_PAPER := Color(1, 1, 0.94, 1.0)
const AVATAR_PATH := "res://assets/portraits/eugene_ravens.jpg"

@onready var menu_row: HBoxContainer = $VBox/MenuBar/MenuRow
@onready var back_button: Button = $VBox/Toolbar/ToolbarRow/BackButton
@onready var home_button: Button = $VBox/Toolbar/ToolbarRow/HomeButton
@onready var address: LineEdit = $VBox/Toolbar/ToolbarRow/Address
@onready var go_button: Button = $VBox/Toolbar/ToolbarRow/GoButton
@onready var history_button: Button = $VBox/Toolbar/ToolbarRow/HistoryButton
@onready var content: MarginContainer = $VBox/ContentMargin/Content
@onready var status_label: Label = $VBox/StatusBar/StatusMargin/StatusLabel

var history: Array = []
var messages: Array = []
var contact_name: String = "Юджин Рейвенс (Брат)"
var contact_status: String = "Был в сети 20 минут назад"
var current_view: String = "home"
var history_rows: VBoxContainer = null
var message_rows: VBoxContainer = null
var messenger_banner: Label = null

var _bold_font: SystemFont
var _mono_font: SystemFont

func _ready() -> void:
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

	_add_menu_items()
	_load_data()
	back_button.pressed.connect(_on_back_pressed)
	home_button.pressed.connect(show_home)
	go_button.pressed.connect(_on_go_pressed)
	history_button.pressed.connect(show_history)
	address.text_submitted.connect(_on_address_submitted)
	show_home()

func _add_menu_items() -> void:
	for text in ["Файл", "Правка", "Вид", "Избранное", "Справка"]:
		var item := _make_label(text, 11, Color.BLACK)
		item.mouse_filter = Control.MOUSE_FILTER_IGNORE
		menu_row.add_child(item)

func _load_data() -> void:
	if not FileAccess.file_exists("res://data/files.json"):
		_set_status("Ошибка: data/files.json не найден")
		return
	var file := FileAccess.open("res://data/files.json", FileAccess.READ)
	if file == null:
		_set_status("Ошибка чтения data/files.json")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		_set_status("Ошибка разбора data/files.json")
		return
	var raw_history: Variant = parsed.get("browser_history", [])
	if raw_history is Array:
		for entry in raw_history:
			if entry is Dictionary:
				history.append(entry)
	var messenger: Variant = parsed.get("messenger", {})
	if messenger is Dictionary:
		contact_name = str(messenger.get("contact", contact_name))
		contact_status = str(messenger.get("status", contact_status))
		var raw_messages: Variant = messenger.get("messages", [])
		if raw_messages is Array:
			for message in raw_messages:
				if message is Dictionary:
					messages.append(message)

func show_home() -> void:
	_clear_content()
	current_view = "home"
	address.text = "local://home"
	_set_status("Локальная домашняя страница")

	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 8)
	content.add_child(page)

	var title := _make_heading("FARA NET", 22, C_NAVY)
	page.add_child(title)
	var subtitle := _make_label("Локальный архив браузера · только сохранённые страницы", 11, C_DARK_GRAY)
	page.add_child(subtitle)

	var panel := _make_white_panel()
	page.add_child(panel)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 8)
	panel.add_child(inner)

	var welcome := _make_label("Добро пожаловать в локальный архив.", 12, Color.BLACK)
	inner.add_child(welcome)
	var history_btn := _make_action_button("История посещений")
	history_btn.pressed.connect(show_history)
	inner.add_child(history_btn)
	var messenger_btn := _make_action_button("Мессенджер: Юджин Рейвенс (Брат)")
	messenger_btn.tooltip_text = "Открыть сохранённую сессию веб-мессенджера"
	messenger_btn.pressed.connect(open_messenger)
	inner.add_child(messenger_btn)

	var note := _make_label("Страницы открываются из локального кэша. Внешняя сеть недоступна.", 10, C_DARK_GRAY)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner.add_child(note)

func show_history() -> void:
	_clear_content()
	current_view = "history"
	address.text = "local://history"
	_set_status("История посещений · %d записей" % history.size())

	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 6)
	content.add_child(page)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	page.add_child(header)
	var title := _make_heading("История посещений", 15, C_NAVY)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var count := _make_label("%d записей" % history.size(), 11, C_DARK_GRAY)
	header.add_child(count)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(scroll)

	history_rows = VBoxContainer.new()
	history_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	history_rows.add_theme_constant_override("separation", 2)
	scroll.add_child(history_rows)

	if history.is_empty():
		history_rows.add_child(_make_label("История пуста.", 11, C_DARK_GRAY))
	else:
		for index in range(history.size()):
			_add_history_row(index, history[index])

	var archive := PanelContainer.new()
	var archive_style := StyleBoxFlat.new()
	archive_style.bg_color = Color(0.94, 0.94, 0.9, 1.0)
	archive_style.border_width_left = 1
	archive_style.border_width_top = 1
	archive_style.border_width_right = 1
	archive_style.border_width_bottom = 1
	archive_style.border_color = C_GRAY
	archive_style.content_margin_left = 6.0
	archive_style.content_margin_top = 4.0
	archive_style.content_margin_right = 6.0
	archive_style.content_margin_bottom = 4.0
	archive.add_theme_stylebox_override("panel", archive_style)
	var archive_label := _make_label("Архив за прошлые периоды повреждён", 10, C_DARK_GRAY)
	archive_label.tooltip_text = "Более старые записи истории недоступны"
	archive.add_child(archive_label)
	page.add_child(archive)

func _add_history_row(index: int, entry: Dictionary) -> void:
	if history_rows == null:
		return
	var title := str(entry.get("title", "Без названия"))
	var time := str(entry.get("time", ""))
	var is_messenger := title.to_lower().contains("мессенджер") or title.to_lower().contains("юджин")

	var row := Button.new()
	row.flat = true
	row.text = "%s    %s%s" % [time, title, "    [открыть чат]" if is_messenger else ""]
	row.alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.clip_text = true
	row.focus_mode = Control.FOCUS_NONE
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	row.custom_minimum_size = Vector2(0, 30)
	row.add_theme_font_size_override("font_size", 11)
	row.tooltip_text = "Открыть сохранённую страницу" if not is_messenger else "Открыть чат с Юджином"

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.86, 0.92, 1.0, 1.0) if is_messenger else Color(1, 1, 1, 0)
	normal.content_margin_left = 6.0
	normal.content_margin_top = 3.0
	normal.content_margin_right = 6.0
	normal.content_margin_bottom = 3.0
	normal.border_width_left = 3 if is_messenger else 0
	normal.border_color = C_NAVY
	row.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = C_NAVY
	hover.content_margin_left = 6.0
	hover.content_margin_top = 3.0
	hover.content_margin_right = 6.0
	hover.content_margin_bottom = 3.0
	row.add_theme_stylebox_override("hover", hover)
	var pressed := hover.duplicate() as StyleBoxFlat
	pressed.bg_color = C_DARK_NAVY
	row.add_theme_stylebox_override("pressed", pressed)
	row.add_theme_color_override("font_color", C_NAVY if is_messenger else Color.BLACK)
	row.add_theme_color_override("font_hover_color", C_WHITE)
	row.add_theme_color_override("font_pressed_color", C_WHITE)
	row.pressed.connect(_on_history_row_pressed.bind(index))
	history_rows.add_child(row)

func _on_history_row_pressed(index: int) -> void:
	if index < 0 or index >= history.size():
		return
	var entry: Dictionary = history[index]
	var title := str(entry.get("title", ""))
	if title.to_lower().contains("мессенджер") or title.to_lower().contains("юджин"):
		open_messenger()
	else:
		_show_page_stub(entry)

func _show_page_stub(entry: Dictionary) -> void:
	_clear_content()
	current_view = "page"
	address.text = "local://history/cached-page"
	_set_status("Содержимое страницы не сохранилось в локальном кэше")
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 8)
	content.add_child(page)
	page.add_child(_make_heading(str(entry.get("title", "Страница")), 15, C_NAVY))
	page.add_child(_make_label(str(entry.get("time", "")), 10, C_DARK_GRAY))
	var panel := _make_white_panel()
	page.add_child(panel)
	var body := _make_label("Локальный кэш этой страницы повреждён.\nВ истории сохранились только заголовок и время посещения.", 12, C_DARK_GRAY)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(body)

func open_messenger() -> void:
	_clear_content()
	current_view = "messenger"
	address.text = "local://messenger/eugene"
	_set_status("Веб-мессенджер · %s" % contact_name)

	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 6)
	content.add_child(page)

	var contact_panel := PanelContainer.new()
	var contact_style := StyleBoxFlat.new()
	contact_style.bg_color = Color(0.94, 0.94, 0.94, 1.0)
	contact_style.border_width_left = 1
	contact_style.border_width_top = 1
	contact_style.border_width_right = 1
	contact_style.border_width_bottom = 1
	contact_style.border_color = C_GRAY
	contact_style.content_margin_left = 6.0
	contact_style.content_margin_top = 4.0
	contact_style.content_margin_right = 6.0
	contact_style.content_margin_bottom = 4.0
	contact_panel.add_theme_stylebox_override("panel", contact_style)
	page.add_child(contact_panel)

	var contact_row := HBoxContainer.new()
	contact_row.add_theme_constant_override("separation", 8)
	contact_panel.add_child(contact_row)
	contact_row.add_child(_make_avatar())
	var contact_info := VBoxContainer.new()
	contact_info.add_theme_constant_override("separation", 1)
	contact_row.add_child(contact_info)
	var name_label := _make_heading(contact_name, 12, Color.BLACK)
	contact_info.add_child(name_label)
	var status := _make_label(contact_status, 10, Color(0.2, 0.5, 0.2, 1.0))
	contact_info.add_child(status)

	var banner_panel := PanelContainer.new()
	var banner_style := StyleBoxFlat.new()
	banner_style.bg_color = C_PAPER
	banner_style.border_width_left = 1
	banner_style.border_width_top = 1
	banner_style.border_width_right = 1
	banner_style.border_width_bottom = 1
	banner_style.border_color = C_GRAY
	banner_style.content_margin_left = 6.0
	banner_style.content_margin_top = 4.0
	banner_style.content_margin_right = 6.0
	banner_style.content_margin_bottom = 4.0
	banner_panel.add_theme_stylebox_override("panel", banner_style)
	page.add_child(banner_panel)
	messenger_banner = _make_label("!  Сообщения старше 30 дней были автоматически удалены пользователем", 10, Color(0.35, 0.25, 0.05, 1.0))
	messenger_banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	banner_panel.add_child(messenger_banner)

	var chat_scroll := ScrollContainer.new()
	chat_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chat_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	chat_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(chat_scroll)

	message_rows = VBoxContainer.new()
	message_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	message_rows.add_theme_constant_override("separation", 5)
	chat_scroll.add_child(message_rows)

	if messages.is_empty():
		message_rows.add_child(_make_label("Переписка недоступна.", 11, C_DARK_GRAY))
	else:
		for message in messages:
			_add_message_row(message)

	var input := LineEdit.new()
	input.editable = false
	input.placeholder_text = "Чат доступен только для чтения — архив переписки"
	input.custom_minimum_size = Vector2(0, 24)
	page.add_child(input)
	call_deferred("_scroll_chat_to_bottom")

func _add_message_row(message: Dictionary) -> void:
	if message_rows == null:
		return
	var sender := str(message.get("sender", ""))
	var text := str(message.get("text", ""))
	var timestamp := str(message.get("timestamp", ""))
	var is_simon := sender.to_lower() == "simon"

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	message_rows.add_child(row)

	var bubble := PanelContainer.new()
	bubble.custom_minimum_size = Vector2(390, 0)
	bubble.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var bubble_style := StyleBoxFlat.new()
	bubble_style.bg_color = C_NAVY if is_simon else C_WHITE
	bubble_style.border_width_left = 1
	bubble_style.border_width_top = 1
	bubble_style.border_width_right = 1
	bubble_style.border_width_bottom = 1
	bubble_style.border_color = C_DARK_NAVY if is_simon else C_GRAY
	bubble_style.content_margin_left = 8.0
	bubble_style.content_margin_top = 5.0
	bubble_style.content_margin_right = 8.0
	bubble_style.content_margin_bottom = 5.0
	bubble.add_theme_stylebox_override("panel", bubble_style)

	var bubble_box := VBoxContainer.new()
	bubble_box.add_theme_constant_override("separation", 2)
	bubble.add_child(bubble_box)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	bubble_box.add_child(header)
	var name_label := _make_heading("Саймон" if is_simon else "Юджин", 10, C_WHITE if is_simon else C_NAVY)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)
	var time_label := _make_label(timestamp, 9, Color(0.8, 0.85, 1.0, 1.0) if is_simon else C_DARK_GRAY)
	header.add_child(time_label)
	var text_label := _make_label(text, 11, C_WHITE if is_simon else Color.BLACK)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.custom_minimum_size = Vector2(360, 0)
	bubble_box.add_child(text_label)

	if is_simon:
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(spacer)
		row.add_child(bubble)
	else:
		row.add_child(bubble)
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(spacer)

func _make_avatar() -> Control:
	var holder := PanelContainer.new()
	holder.custom_minimum_size = Vector2(42, 42)
	var style := StyleBoxFlat.new()
	style.bg_color = C_FACE
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = C_GRAY
	holder.add_theme_stylebox_override("panel", style)

	if ResourceLoader.exists(AVATAR_PATH):
		var texture := load(AVATAR_PATH) as Texture2D
		if texture:
			var image := TextureRect.new()
			image.texture = texture
			image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			image.custom_minimum_size = Vector2(40, 40)
			holder.add_child(image)
			return holder
	var initials := _make_heading("Ю", 18, C_NAVY)
	initials.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	initials.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	holder.add_child(initials)
	return holder

func _scroll_chat_to_bottom() -> void:
	var scroll := (message_rows.get_parent() as ScrollContainer) if message_rows else null
	if scroll:
		scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)

func _on_back_pressed() -> void:
	if current_view == "messenger":
		show_history()
	elif current_view == "history" or current_view == "page":
		show_home()
	else:
		show_home()

func _on_go_pressed() -> void:
	_on_address_submitted(address.text)

func _on_address_submitted(value: String) -> void:
	var target := value.strip_edges().to_lower()
	if target.contains("messenger") or target.contains("eugene") or target.contains("юджин"):
		open_messenger()
	elif target.contains("history") or target.contains("история"):
		show_history()
	elif target.contains("home") or target.contains("главная"):
		show_home()
	else:
		_set_status("Локальная страница не найдена: %s" % value)
		address.text = "local://" + value.strip_edges()

func _clear_content() -> void:
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	history_rows = null
	message_rows = null
	messenger_banner = null

func _set_status(text: String) -> void:
	status_label.text = text

func _make_label(text: String, font_size: int = 12, color: Color = Color.BLACK) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label

func _make_heading(text: String, font_size: int = 12, color: Color = Color.BLACK) -> Label:
	var label := _make_label(text, font_size, color)
	label.add_theme_font_override("font", _bold_font)
	return label

func _make_action_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(0, 28)
	button.add_theme_font_size_override("font_size", 11)
	return button

func _make_white_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = C_WHITE
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = C_GRAY
	style.content_margin_left = 8.0
	style.content_margin_top = 8.0
	style.content_margin_right = 8.0
	style.content_margin_bottom = 8.0
	panel.add_theme_stylebox_override("panel", style)
	return panel
