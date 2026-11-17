class_name AppPreview
extends Control

## Лёгкие макеты содержимого шести приложений рабочего стола.
##
## Это именно заглушки для Issue #10: настоящие Проводник, Терминал, Карты,
## Галерея, Заметки и Корзина будут подключены отдельными задачами. Каждая
## заглушка повторяет композицию будущего приложения и использует общий
## ретро-хром, чтобы окно выглядело целостно уже на этапе каркаса.

@export_enum("computer", "terminal", "maps", "gallery", "notes", "recycle")
var kind: String = "computer"

const C_FACE := Color(0.752941, 0.752941, 0.752941, 1.0)
const C_NAVY := Color(0, 0, 0.501961, 1.0)
const C_GRAY := Color(0.501961, 0.501961, 0.501961, 1.0)
const C_DARK_GRAY := Color(0.25, 0.25, 0.25, 1.0)
const C_WHITE := Color(1, 1, 1, 1)
const C_RED := Color(0.72, 0.12, 0.12, 1.0)
const C_GREEN := Color(0.2, 1.0, 0.2, 1.0)

const ICON_DRIVE := preload("res://assets/icons/drive.svg")
const ICON_FOLDER := preload("res://assets/icons/folder.svg")
const ICON_FILE := preload("res://assets/icons/file_text.svg")
const ICON_PHOTO := preload("res://assets/icons/photo.svg")
const ICON_LOCK := preload("res://assets/icons/lock.svg")
const ICON_NOTES := preload("res://assets/icons/notes.svg")
const ICON_RECYCLE := preload("res://assets/icons/recycle_bin.svg")
const ICON_TERMINAL := preload("res://assets/icons/terminal.svg")

const PHOTO_TRUCK := preload("res://assets/previews/photo_truck.png")
const PHOTO_PICKUP := preload("res://assets/previews/photo_pickup.png")
const PHOTO_GAS := preload("res://assets/previews/photo_gas.png")
const PHOTO_CAT := preload("res://assets/previews/photo_cat.png")
const PHOTO_PICNIC := preload("res://assets/previews/photo_picnic.png")
const PHOTO_RAIN := preload("res://assets/previews/photo_rain.png")

const INFO_CARD := preload("res://scenes/ui/InfoCard.tscn")

const PHOTOS := [
	{
		"texture": PHOTO_TRUCK,
		"file": "IMG_2042.jpg",
		"date": "24.09.2009",
		"time": "18:42",
		"camera": "Canon PowerShot A590 IS",
		"resolution": "3264 × 2448",
		"size": "2,8 МБ",
	},
	{
		"texture": PHOTO_PICKUP,
		"file": "IMG_2041.jpg",
		"date": "24.09.2009",
		"time": "18:17",
		"camera": "Canon PowerShot A590 IS",
		"resolution": "3264 × 2448",
		"size": "2,6 МБ",
	},
	{
		"texture": PHOTO_GAS,
		"file": "IMG_2038.jpg",
		"date": "17.09.2009",
		"time": "22:05",
		"camera": "Canon PowerShot A590 IS",
		"resolution": "3264 × 2448",
		"size": "3,1 МБ",
	},
	{
		"texture": PHOTO_CAT,
		"file": "IMG_2026.jpg",
		"date": "02.09.2009",
		"time": "23:12",
		"camera": "Canon PowerShot A590 IS",
		"resolution": "3264 × 2448",
		"size": "2,2 МБ",
	},
	{
		"texture": PHOTO_PICNIC,
		"file": "IMG_2019.jpg",
		"date": "16.08.2009",
		"time": "14:30",
		"camera": "Canon PowerShot A590 IS",
		"resolution": "3264 × 2448",
		"size": "2,9 МБ",
	},
	{
		"texture": PHOTO_RAIN,
		"file": "IMG_2007.jpg",
		"date": "05.08.2009",
		"time": "02:14",
		"camera": "Canon PowerShot A590 IS",
		"resolution": "3264 × 2448",
		"size": "2,4 МБ",
	},
]

@onready var menu_row: HBoxContainer = $VBox/MenuBar/MenuRow
@onready var toolbar_row: HBoxContainer = $VBox/Toolbar/ToolbarRow
@onready var content: Control = $VBox/ContentMargin/Content
@onready var status_row: HBoxContainer = $VBox/StatusBar/StatusMargin/StatusRow

var _bold_font: SystemFont
var _mono_font: SystemFont
var _toolbar_buttons: Dictionary = {}
var _gallery_cards: Array[PanelContainer] = []
var _gallery_captions: Array[Label] = []
var _selected_photo_index: int = 0
var _map_info_card: InfoCard
var _photo_info_card: InfoCard

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

	match kind:
		"terminal":
			_build_terminal()
		"maps":
			_build_maps()
		"gallery":
			_build_gallery()
		"notes":
			_build_notes()
		"recycle":
			_build_recycle()
		_:
			_build_computer()

# ---------------------------------------------------------------------------
# Общий «хром» приложения
# ---------------------------------------------------------------------------

func _build_chrome(menus: Array, tools: Array, status_left: String, status_right: String, toolbar_right: String = "") -> void:
	_toolbar_buttons.clear()
	for menu_text in menus:
		var label := _make_label(menu_text, 11, Color.BLACK)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		menu_row.add_child(label)

	for item in tools:
		if item.get("sep", false):
			var sep := VSeparator.new()
			sep.custom_minimum_size = Vector2(7, 0)
			toolbar_row.add_child(sep)
		else:
			var button := _make_toolbar_button(item.get("text", ""))
			toolbar_row.add_child(button)
			_toolbar_buttons[button.text] = button

	if toolbar_right != "":
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		toolbar_row.add_child(spacer)
		var right := _make_label(toolbar_right, 11, C_DARK_GRAY)
		right.mouse_filter = Control.MOUSE_FILTER_IGNORE
		toolbar_row.add_child(right)

	var left := _make_label(status_left, 11, Color.BLACK)
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_row.add_child(left)
	var status_spacer := Control.new()
	status_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_row.add_child(status_spacer)
	var right := _make_label(status_right, 11, Color.BLACK)
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_row.add_child(right)

func _make_toolbar_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.custom_minimum_size = Vector2(0, 23)
	button.add_theme_font_size_override("font_size", 11)
	button.tooltip_text = "Макет: функция появится в следующей задаче"
	return button

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

func _make_sidebar(parent: HBoxContainer, width: float) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(width, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = C_FACE
	style.border_width_right = 1
	style.border_color = C_GRAY
	style.content_margin_left = 6.0
	style.content_margin_top = 6.0
	style.content_margin_right = 6.0
	style.content_margin_bottom = 6.0
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)
	return box

func _sidebar_header(box: VBoxContainer, text: String) -> void:
	var label := _make_heading(text.to_upper(), 10, C_NAVY)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(label)
	var line := HSeparator.new()
	box.add_child(line)

func _sidebar_item(box: VBoxContainer, icon: Texture2D, text: String, selected: bool = false, lock: bool = false) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 22)
	row.add_theme_constant_override("separation", 4)
	if selected:
		var panel := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = C_NAVY
		style.content_margin_left = 3.0
		style.content_margin_right = 3.0
		panel.add_theme_stylebox_override("panel", style)
		box.add_child(panel)
		panel.add_child(row)
	else:
		box.add_child(row)

	if icon:
		var texture := TextureRect.new()
		texture.texture = icon
		texture.custom_minimum_size = Vector2(16, 16)
		texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(texture)

	var label := _make_label(text, 11, C_WHITE if selected else Color.BLACK)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)

	if lock:
		var lock_icon := TextureRect.new()
		lock_icon.texture = ICON_LOCK
		lock_icon.custom_minimum_size = Vector2(14, 14)
		lock_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lock_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lock_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(lock_icon)

func _make_white_panel(parent: Container, expand: bool = true) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = C_WHITE
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = C_GRAY
	style.content_margin_left = 2.0
	style.content_margin_top = 2.0
	style.content_margin_right = 2.0
	style.content_margin_bottom = 2.0
	panel.add_theme_stylebox_override("panel", style)
	if expand:
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	return panel

func _row_style(bg: Color, border_bottom: bool = true) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.content_margin_left = 4.0
	style.content_margin_top = 1.0
	style.content_margin_right = 4.0
	style.content_margin_bottom = 1.0
	if border_bottom:
		style.border_width_bottom = 1
		style.border_color = Color(0.88, 0.88, 0.88, 1)
	return style

# ---------------------------------------------------------------------------
# Мой компьютер
# ---------------------------------------------------------------------------

func _build_computer() -> void:
	_build_chrome(
		["Файл", "Правка", "Вид", "Избранное", "Справка"],
		[{"text": "Назад"}, {"text": "Вперёд"}, {"text": "Вверх"}, {"sep": true}, {"text": "Поиск"}],
		"6 объектов",
		"12,4 ГБ свободно",
		"Значки"
	)

	var root := HBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(root)

	var sidebar := _make_sidebar(root, 168.0)
	_sidebar_header(sidebar, "Быстрый доступ")
	_sidebar_item(sidebar, ICON_FOLDER, "Рабочий стол")
	_sidebar_item(sidebar, ICON_FOLDER, "Документы")
	_sidebar_item(sidebar, ICON_PHOTO, "Изображения")
	_sidebar_item(sidebar, ICON_FOLDER, "Загрузки")
	_sidebar_item(sidebar, ICON_RECYCLE, "Корзина")
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sidebar.add_child(spacer)
	_sidebar_item(sidebar, ICON_FOLDER, "Работа", false, true)
	var hint := _make_label("Защищённая папка", 10, C_DARK_GRAY)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sidebar.add_child(hint)

	var list_panel := _make_white_panel(root)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 0)
	list_panel.add_child(list)

	var header := PanelContainer.new()
	header.add_theme_stylebox_override("panel", _row_style(Color(0.84, 0.84, 0.84)))
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 6)
	var header_name := _make_heading("Имя", 11, Color.BLACK)
	header_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(header_name)
	var header_type := _make_heading("Тип", 11, Color.BLACK)
	header_type.custom_minimum_size = Vector2(96, 0)
	header_row.add_child(header_type)
	var header_size := _make_heading("Размер", 11, Color.BLACK)
	header_size.custom_minimum_size = Vector2(84, 0)
	header_size.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header_row.add_child(header_size)
	header.add_child(header_row)
	list.add_child(header)

	_add_file_row(list, ICON_DRIVE, "Локальный диск (C:)", "Локальный диск", "12,4 ГБ", {})
	_add_file_row(list, ICON_DRIVE, "Локальный диск (D:)", "Локальный диск", "4,1 ГБ", {"alt": true})
	_add_file_row(list, ICON_FOLDER, "Работа", "Папка", "Защищено", {"lock": true})
	_add_file_row(list, ICON_FOLDER, "Документы", "Папка", "8 объектов", {"alt": true})
	_add_file_row(list, ICON_PHOTO, "Изображения", "Папка", "18 объектов", {})
	_add_file_row(list, ICON_RECYCLE, "Корзина", "Корзина", "3 объекта", {"alt": true})

func _add_file_row(list: VBoxContainer, icon: Texture2D, name: String, type: String, size_text: String, opts: Dictionary) -> void:
	var selected: bool = opts.get("selected", false)
	var alt: bool = opts.get("alt", false)
	var lock: bool = opts.get("lock", false)
	var row := PanelContainer.new()
	var bg := C_NAVY if selected else (Color(0.97, 0.97, 0.97) if alt else C_WHITE)
	row.add_theme_stylebox_override("panel", _row_style(bg))
	var row_box := HBoxContainer.new()
	row_box.custom_minimum_size = Vector2(0, 26)
	row_box.add_theme_constant_override("separation", 6)
	row.add_child(row_box)

	var texture := TextureRect.new()
	texture.texture = icon
	texture.custom_minimum_size = Vector2(20, 20)
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row_box.add_child(texture)

	var name_label := _make_label(name, 12, C_WHITE if selected else Color.BLACK)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row_box.add_child(name_label)

	if lock:
		var lock_icon := TextureRect.new()
		lock_icon.texture = ICON_LOCK
		lock_icon.custom_minimum_size = Vector2(14, 14)
		lock_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lock_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lock_icon.tooltip_text = "Папка защищена паролем"
		row_box.add_child(lock_icon)

	var type_label := _make_label(type, 11, C_WHITE if selected else C_DARK_GRAY)
	var type_width: float = opts.get("type_width", 96.0)
	type_label.custom_minimum_size = Vector2(type_width, 0)
	type_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row_box.add_child(type_label)

	var size_label := _make_label(size_text, 11, C_WHITE if selected else C_DARK_GRAY)
	var size_width: float = opts.get("size_width", 84.0)
	size_label.custom_minimum_size = Vector2(size_width, 0)
	size_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	size_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row_box.add_child(size_label)

	list.add_child(row)

# ---------------------------------------------------------------------------
# Терминал
# ---------------------------------------------------------------------------

func _build_terminal() -> void:
	_build_chrome(
		["Файл", "Правка", "Вид", "Терминал", "Справка"],
		[{"text": "Очистить"}, {"text": "Шрифт"}, {"text": "Свойства"}],
		"Готово к вводу  |  Tab — дополнение",
		"C:\\ROOT_ACCESS",
		"DOS / WIN98"
	)

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 1)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.25, 0.25, 0.25, 1)
	style.content_margin_left = 10.0
	style.content_margin_top = 8.0
	style.content_margin_right = 8.0
	style.content_margin_bottom = 8.0
	panel.add_theme_stylebox_override("panel", style)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(panel)

	var output := RichTextLabel.new()
	output.bbcode_enabled = true
	output.scroll_following = true
	output.selection_enabled = true
	output.fit_content = false
	output.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	output.size_flags_vertical = Control.SIZE_EXPAND_FILL
	output.add_theme_font_override("normal_font", _mono_font)
	output.add_theme_font_override("mono_font", _mono_font)
	output.add_theme_font_size_override("normal_font_size", 13)
	output.add_theme_font_size_override("mono_font_size", 13)
	output.add_theme_color_override("default_color", C_GREEN)
	output.text = """[color=#33ff33]RootAccess Terminal v2.4[/color]
[color=#1f9f1f](C) 1998-2009 FARA Systems. All rights reserved.[/color]

C:\\ROOT_ACCESS> [color=#ffffff]dir[/color]
 Том в устройстве C имеет метку ROOT_ACCESS
 Содержимое папки C:\\ROOT_ACCESS

[color=#33ff33][DIR][/color]          WORK
[color=#33ff33][DIR][/color]          PHOTOS
               NOTES.TXT          1 024  02.10.2009 01:47
               LOCATION.ENC       4 096  02.10.2009 02:03

C:\\ROOT_ACCESS> [color=#ffffff]decrypt location.enc -k <ключ>[/color]
[color=#33ff33][████████████████████] 100% COMPLETE[/color]
[color=#33ff33][OK][/color] Файл расшифрован.

C:\\ROOT_ACCESS> [color=#ffffff]█[/color]
"""
	panel.add_child(output)

# ---------------------------------------------------------------------------
# Карты
# ---------------------------------------------------------------------------

func _build_maps() -> void:
	_build_chrome(
		["Файл", "Правка", "Вид", "Маршрут", "Справка"],
		[{"text": "Найти"}, {"text": "Маршрут"}, {"sep": true}, {"text": "Слои"}],
		"7 точек интереса",
		"Масштаб 100%",
		"СЕВЕРНАЯ ПРОМЗОНА"
	)

	var root := HBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(root)

	var map := MapPreview.new()
	map.custom_minimum_size = Vector2(360, 260)
	map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map.marker_clicked.connect(_on_map_marker_clicked)
	root.add_child(map)

	var sidebar := _make_sidebar(root, 214.0)
	_sidebar_header(sidebar, "Точки интереса")
	_sidebar_item(sidebar, null, "Дом Саймона")
	_sidebar_item(sidebar, null, "Дом брата")
	_sidebar_item(sidebar, null, "Гаражи")
	_sidebar_item(sidebar, null, "Адрес Мишель")
	_sidebar_item(sidebar, null, "Бокс № 6752")
	var key_item := PanelContainer.new()
	var key_style := StyleBoxFlat.new()
	key_style.bg_color = Color(1.0, 0.88, 0.88, 1.0)
	key_style.border_width_left = 2
	key_style.border_color = C_RED
	key_style.content_margin_left = 4.0
	key_style.content_margin_top = 2.0
	key_style.content_margin_right = 4.0
	key_style.content_margin_bottom = 2.0
	key_item.add_theme_stylebox_override("panel", key_style)
	var key_label := _make_label("Склад № 3", 11, C_RED)
	key_label.add_theme_font_override("font", _bold_font)
	key_item.add_child(key_label)
	sidebar.add_child(key_item)
	_sidebar_item(sidebar, null, "Свалка")

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sidebar.add_child(spacer)
	var hint := _make_label("Колёсико — масштаб,\nклик по метке — карточка места", 10, C_DARK_GRAY)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sidebar.add_child(hint)

	_map_info_card = INFO_CARD.instantiate()
	add_child(_map_info_card)

func _on_map_marker_clicked(marker: Dictionary) -> void:
	if _map_info_card == null:
		return
	var title: String = marker["name"]
	var address: String = marker.get("card_address", "Адрес: " + marker["address"])
	var note: String = marker.get("note", "")
	var body := "[b]%s[/b]\n\n%s" % [address, note]
	_map_info_card.open(
		title,
		body,
		marker.get("action", ""),
		marker.get("action_result", "")
	)

# ---------------------------------------------------------------------------
# Галерея
# ---------------------------------------------------------------------------

func _build_gallery() -> void:
	_build_chrome(
		["Файл", "Правка", "Вид", "Слайд-шоу", "Справка"],
		[
			{"text": "Все фото"},
			{"text": "Недавние"},
			{"sep": true},
			{"text": "Слайд-шоу"},
			{"sep": true},
			{"text": "Свойства / Подробнее"},
		],
		"6 из 48 фото",
		"Сортировка: дата съёмки",
		"Зум 100%"
	)

	var root := HBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(root)

	var sidebar := _make_sidebar(root, 154.0)
	_sidebar_header(sidebar, "Библиотека")
	_sidebar_item(sidebar, ICON_PHOTO, "Все фото  48", true)
	_sidebar_item(sidebar, ICON_PHOTO, "Недавние  6")
	_sidebar_header(sidebar, "Альбомы")
	_sidebar_item(sidebar, ICON_FOLDER, "Дом")
	_sidebar_item(sidebar, ICON_FOLDER, "Гаражи")
	_sidebar_item(sidebar, ICON_FOLDER, "Склад")
	_sidebar_item(sidebar, ICON_FOLDER, "Поездки")
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sidebar.add_child(spacer)
	var hint := _make_label("Клик — выбрать фото,\n«Подробнее» — свойства", 10, C_DARK_GRAY)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sidebar.add_child(hint)

	var panel := _make_white_panel(root)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(margin)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(grid)

	for index in range(PHOTOS.size()):
		_add_photo_card(grid, index)
	_apply_photo_selection()

	var properties_button := _toolbar_buttons.get("Свойства / Подробнее") as Button
	if properties_button:
		properties_button.tooltip_text = "Свойства выбранного фото"
		properties_button.pressed.connect(_open_photo_properties)

	_photo_info_card = INFO_CARD.instantiate()
	add_child(_photo_info_card)

func _photo_card_style(selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = C_WHITE
	style.border_width_left = 2 if selected else 1
	style.border_width_top = 2 if selected else 1
	style.border_width_right = 2 if selected else 1
	style.border_width_bottom = 2 if selected else 1
	style.border_color = C_NAVY if selected else C_GRAY
	style.content_margin_left = 3.0
	style.content_margin_top = 3.0
	style.content_margin_right = 3.0
	style.content_margin_bottom = 3.0
	return style

func _add_photo_card(grid: GridContainer, index: int) -> void:
	var data: Dictionary = PHOTOS[index]
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _photo_card_style(false))
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.tooltip_text = "%s · %s" % [data["file"], data["date"]]
	card.gui_input.connect(_on_photo_card_gui_input.bind(index))
	grid.add_child(card)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	card.add_child(box)

	var texture := TextureRect.new()
	texture.texture = data["texture"]
	texture.custom_minimum_size = Vector2(0, 116)
	texture.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texture.size_flags_vertical = Control.SIZE_EXPAND_FILL
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(texture)

	var caption := _make_label("%s  ·  %s" % [data["file"], data["date"]], 10, C_DARK_GRAY)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(caption)

	_gallery_cards.append(card)
	_gallery_captions.append(caption)

func _on_photo_card_gui_input(event: InputEvent, index: int) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse := event as InputEventMouseButton
	if mouse.button_index == MOUSE_BUTTON_LEFT and mouse.pressed:
		_selected_photo_index = index
		_apply_photo_selection()

func _apply_photo_selection() -> void:
	for index in range(_gallery_cards.size()):
		var selected := index == _selected_photo_index
		_gallery_cards[index].add_theme_stylebox_override("panel", _photo_card_style(selected))
		_gallery_captions[index].add_theme_color_override("font_color", C_NAVY if selected else C_DARK_GRAY)

func _open_photo_properties() -> void:
	if _photo_info_card == null or PHOTOS.is_empty():
		return
	var data: Dictionary = PHOTOS[_selected_photo_index]
	var body := "[b]Файл:[/b] %s\n[b]Тип:[/b] JPEG\n[b]Размер:[/b] %s\n\n[b]Дата съёмки:[/b] [bgcolor=#fff59d]%s[/bgcolor] в %s\n[b]Камера:[/b] %s\n[b]Разрешение:[/b] %s" % [
		data["file"],
		data["size"],
		data["date"],
		data["time"],
		data["camera"],
		data["resolution"],
	]
	_photo_info_card.open("Свойства изображения", body)

# ---------------------------------------------------------------------------
# Заметки
# ---------------------------------------------------------------------------

func _build_notes() -> void:
	_build_chrome(
		["Файл", "Правка", "Формат", "Вид", "Справка"],
		[{"text": "Открыть"}, {"text": "Сохранить"}, {"sep": true}, {"text": "Найти"}],
		"Строка 4, столбец 12",
		"UTF-8",
		"Блокнот"
	)

	var page := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = C_WHITE
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = C_GRAY
	style.content_margin_left = 12.0
	style.content_margin_top = 10.0
	style.content_margin_right = 12.0
	style.content_margin_bottom = 10.0
	page.add_theme_stylebox_override("panel", style)
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(page)

	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.fit_content = false
	text.selection_enabled = true
	text.scroll_active = true
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text.add_theme_font_override("normal_font", _mono_font)
	text.add_theme_font_size_override("normal_font_size", 14)
	text.add_theme_color_override("default_color", Color(0.1, 0.1, 0.1, 1))
	text.text = """[color=#000080]C:\\ROOT_ACCESS\\NOTES\\пароли.txt[/color]

Пароль от папки Работа — [bgcolor=#fff59d]др Юджина[/bgcolor]
(день и месяц, 4 цифры: ДДММ)

Накладную удалил, надо бы потом
очистить корзину.

— не забыть посмотреть свойства фото
  у ржавого пикапа

[color=#808080]------------------------------------------------[/color]
[color=#808080]24.09 — день рождения Юджина[/color]

█
"""
	page.add_child(text)

# ---------------------------------------------------------------------------
# Корзина
# ---------------------------------------------------------------------------

func _build_recycle() -> void:
	_build_chrome(
		["Файл", "Правка", "Вид", "Справка"],
		[{"text": "Восстановить"}, {"text": "Очистить корзину"}],
		"3 объекта",
		"1,8 КБ",
		"Корзина"
	)

	var root := HBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(root)

	var sidebar := _make_sidebar(root, 156.0)
	_sidebar_header(sidebar, "Задачи корзины")
	_sidebar_item(sidebar, ICON_RECYCLE, "Очистить корзину")
	_sidebar_item(sidebar, ICON_FILE, "Восстановить все")
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sidebar.add_child(spacer)
	var hint := _make_label("Удалённые файлы\nхранятся 30 дней", 10, C_DARK_GRAY)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sidebar.add_child(hint)

	var list_panel := _make_white_panel(root)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 0)
	list_panel.add_child(list)

	var header := PanelContainer.new()
	header.add_theme_stylebox_override("panel", _row_style(Color(0.84, 0.84, 0.84)))
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 6)
	var header_name := _make_heading("Имя", 11, Color.BLACK)
	header_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(header_name)
	var header_date := _make_heading("Дата удаления", 11, Color.BLACK)
	header_date.custom_minimum_size = Vector2(96, 0)
	header_row.add_child(header_date)
	var header_size := _make_heading("Размер", 11, Color.BLACK)
	header_size.custom_minimum_size = Vector2(58, 0)
	header_size.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header_row.add_child(header_size)
	header.add_child(header_row)
	list.add_child(header)

	_add_file_row(list, ICON_FILE, "старый_чек_автосервис.txt", "12.09.2009", "612 Б", {"type_width": 96.0, "size_width": 58.0})
	_add_file_row(list, ICON_FILE, "черновик_письма.txt", "28.09.2009", "1,0 КБ", {"alt": true, "type_width": 96.0, "size_width": 58.0})
	_add_file_row(list, ICON_FILE, "накладная_доставка.txt", "01.10.2009", "1,2 КБ", {"selected": true, "type_width": 96.0, "size_width": 58.0})

	var selected_hint := _make_label("Ключевой документ: накладная на аренду фургона", 10, C_RED)
	selected_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	list.add_child(selected_hint)
