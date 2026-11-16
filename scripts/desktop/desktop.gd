class_name Desktop
extends Control

## Рабочий стол FARA OS: слой иконок, оконный менеджер, панель задач,
## меню «Пуск», трей и сюжетные часы (02:15 / 02.10.2009).
##
## Часы не читают системное время: по сценарию игра начинается в 02:15
## ночи, а время двигается только сюжетными событиями через
## set_story_time() / advance_story_time().

signal story_time_changed(hour: int, minute: int)

const WINDOW_FRAME := preload("res://scenes/ui/WindowFrame.tscn")
const APP_PREVIEW := preload("res://scenes/apps/previews/AppPreview.tscn")
const START_ITEM := preload("res://scenes/ui/StartMenuItem.tscn")

const APPS := [
	{
		"id": "computer",
		"title": "Мой компьютер",
		"icon": preload("res://assets/icons/computer.svg"),
		"kind": "computer",
		"size": Vector2(780, 520),
		"min_size": Vector2(560, 360),
	},
	{
		"id": "terminal",
		"title": "Терминал",
		"icon": preload("res://assets/icons/terminal.svg"),
		"kind": "terminal",
		"size": Vector2(720, 470),
		"min_size": Vector2(480, 300),
	},
	{
		"id": "maps",
		"title": "Карты",
		"icon": preload("res://assets/icons/maps.svg"),
		"kind": "maps",
		"size": Vector2(840, 560),
		"min_size": Vector2(560, 360),
	},
	{
		"id": "gallery",
		"title": "Галерея",
		"icon": preload("res://assets/icons/gallery.svg"),
		"kind": "gallery",
		"size": Vector2(860, 580),
		"min_size": Vector2(600, 380),
	},
	{
		"id": "notes",
		"title": "Заметки",
		"icon": preload("res://assets/icons/notes.svg"),
		"kind": "notes",
		"size": Vector2(660, 500),
		"min_size": Vector2(420, 300),
	},
	{
		"id": "recycle",
		"title": "Корзина",
		"icon": preload("res://assets/icons/recycle_bin.svg"),
		"kind": "recycle",
		"size": Vector2(760, 480),
		"min_size": Vector2(520, 320),
	},
]

@export var single_click_to_open: bool = true
@export var story_hour: int = 2
@export var story_minute: int = 15
@export var story_date: String = "02.10.2009"

@onready var icons_root: GridContainer = $DesktopSurface/Icons
@onready var window_layer: Control = $DesktopSurface/WindowLayer
@onready var taskbar: PanelContainer = $Taskbar
@onready var start_button: Button = $Taskbar/MainMargin/MainRow/StartButton
@onready var task_buttons: HBoxContainer = $Taskbar/MainMargin/MainRow/TaskButtons
@onready var time_label: Label = $Taskbar/MainMargin/MainRow/Tray/TrayMargin/TrayRow/Clock/TimeLabel
@onready var date_label: Label = $Taskbar/MainMargin/MainRow/Tray/TrayMargin/TrayRow/Clock/DateLabel
@onready var clock_box: VBoxContainer = $Taskbar/MainMargin/MainRow/Tray/TrayMargin/TrayRow/Clock
@onready var start_menu: PanelContainer = $StartMenu
@onready var start_search: LineEdit = $StartMenu/StartVBox/SearchMargin/Search
@onready var start_items: VBoxContainer = $StartMenu/StartVBox/Scroll/Items
@onready var tray_popup: PanelContainer = $TrayPopup
@onready var tray_popup_label: Label = $TrayPopup/PopupMargin/PopupLabel
@onready var shutdown_dialog: AcceptDialog = $ShutdownDialog

var _windows: Array[WindowFrame] = []
var _task_buttons: Dictionary = {}
var _active_window: WindowFrame = null
var _selected_icon: DesktopIcon = null
var _cascade_index: int = 0
var _tray_kind: String = ""

func _ready() -> void:
	_build_desktop_icons()
	_build_start_menu()
	_connect_tray()
	_update_clock()
	start_menu.visible = false
	tray_popup.visible = false
	start_button.pressed.connect(_on_start_button_pressed)
	get_viewport().size_changed.connect(_on_viewport_resized)

func _build_desktop_icons() -> void:
	for child in icons_root.get_children():
		var icon := child as DesktopIcon
		if icon == null:
			continue
		icon.single_click_opens = single_click_to_open
		icon.pressed.connect(_on_icon_pressed)
		icon.activated.connect(_on_icon_activated)
		icon.focus_entered.connect(_on_icon_focused.bind(icon))

func _build_start_menu() -> void:
	for app in APPS:
		var item: StartMenuItem = START_ITEM.instantiate()
		item.app_id = app["id"]
		item.item_title = app["title"]
		item.item_icon = app["icon"]
		item.activated.connect(_on_start_item_activated)
		start_items.add_child(item)
	start_search.text_changed.connect(_on_start_search_changed)
	start_search.text_submitted.connect(_on_start_search_submitted)

func _connect_tray() -> void:
	var tray_row := $Taskbar/MainMargin/MainRow/Tray/TrayMargin/TrayRow
	var volume: Button = tray_row.get_node("VolumeButton")
	var network: Button = tray_row.get_node("NetworkButton")
	var battery: Button = tray_row.get_node("BatteryButton")
	volume.pressed.connect(_on_tray_pressed.bind("volume"))
	network.pressed.connect(_on_tray_pressed.bind("network"))
	battery.pressed.connect(_on_tray_pressed.bind("battery"))

func _update_clock() -> void:
	time_label.text = "%02d:%02d" % [story_hour, story_minute]
	date_label.text = story_date
	clock_box.tooltip_text = "%02d:%02d · %s" % [story_hour, story_minute, story_date]

## Публичный API для сюжетных скриптов: точное время.
func set_story_time(hour: int, minute: int) -> void:
	story_hour = posmod(hour, 24)
	story_minute = posmod(minute, 60)
	_update_clock()
	story_time_changed.emit(story_hour, story_minute)

## Публичный API для сюжетных скриптов: сдвиг времени вперёд (например,
## после дешифровки location.enc с 02:15 до 03:40).
func advance_story_time(minutes: int) -> void:
	var total := story_hour * 60 + story_minute + minutes
	total = posmod(total, 24 * 60)
	story_hour = int(total / 60.0)
	story_minute = total % 60
	_update_clock()
	story_time_changed.emit(story_hour, story_minute)

func get_story_time_string() -> String:
	return "%02d:%02d" % [story_hour, story_minute]

# ---------------------------------------------------------------------------
# Иконки и выбор
# ---------------------------------------------------------------------------

func _on_icon_pressed(icon: DesktopIcon) -> void:
	_select_icon(icon)

func _on_icon_focused(icon: DesktopIcon) -> void:
	_select_icon(icon)

func _on_icon_activated(app_id: String) -> void:
	open_app(app_id)

func _select_icon(icon: DesktopIcon) -> void:
	if _selected_icon == icon:
		return
	if is_instance_valid(_selected_icon):
		_selected_icon.selected = false
	_selected_icon = icon
	if is_instance_valid(icon):
		icon.selected = true

func _clear_selection() -> void:
	for icon in icons_root.get_children():
		if icon is DesktopIcon:
			icon.selected = false
	_selected_icon = null

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	if start_menu.visible:
		return
	if _selected_icon == null or not _selected_icon.has_focus():
		return
	var delta := 0
	if key.keycode == KEY_UP or key.keycode == KEY_LEFT:
		delta = -1
	elif key.keycode == KEY_DOWN or key.keycode == KEY_RIGHT:
		delta = 1
	if delta == 0:
		return
	var index := _selected_icon.get_index()
	var next_index := clampi(index + delta, 0, icons_root.get_child_count() - 1)
	var next_icon := icons_root.get_child(next_index) as DesktopIcon
	if next_icon:
		next_icon.grab_focus()
		_select_icon(next_icon)
		get_viewport().set_input_as_handled()

# ---------------------------------------------------------------------------
# Оконный менеджер
# ---------------------------------------------------------------------------

func open_app(app_id: String) -> void:
	_close_start_menu()
	_hide_tray_popup()

	var existing := _find_window(app_id)
	if existing:
		if not existing.visible:
			existing.restore()
		_bring_to_front(existing)
		return

	var app := _find_app(app_id)
	if app.is_empty():
		push_warning("Неизвестное приложение: %s" % app_id)
		return

	var app_content: Control
	if app_id == "terminal":
		var term_scene: PackedScene = load("res://scenes/apps/Terminal.tscn")
		app_content = term_scene.instantiate()
	else:
		var preview: AppPreview = APP_PREVIEW.instantiate()
		preview.kind = app["kind"]
		app_content = preview

	var frame: WindowFrame = WINDOW_FRAME.instantiate()
	frame.window_title = app["title"]
	frame.window_icon = app["icon"]
	frame.min_window_size = app["min_size"]
	frame.set_meta("app_id", app_id)
	window_layer.add_child(frame)
	frame.embed_app(app_content)
	frame.close_requested.connect(_on_window_close.bind(frame))
	frame.minimize_requested.connect(_on_window_minimize.bind(frame))
	frame.focus_requested.connect(_on_window_focus.bind(frame))

	_place_window(frame, app["size"])
	_windows.append(frame)
	_cascade_index += 1
	_add_task_button(frame)
	_bring_to_front(frame)

func _find_app(app_id: String) -> Dictionary:
	for app in APPS:
		if app["id"] == app_id:
			return app
	return {}

func _find_window(app_id: String) -> WindowFrame:
	for window in _windows:
		if is_instance_valid(window) and window.get_meta("app_id", "") == app_id:
			return window
	return null

func _place_window(frame: WindowFrame, requested_size: Vector2) -> void:
	var area := window_layer.size
	var target := Vector2(
		minf(requested_size.x, area.x - 24.0),
		minf(requested_size.y, area.y - 24.0)
	)
	frame.size = target
	var base := (area - target) * 0.5
	var step := float(_cascade_index % 5) * 22.0
	var position := base + Vector2(step - 44.0, step - 36.0)
	position.x = clampf(position.x, 8.0, maxf(8.0, area.x - target.x - 8.0))
	position.y = clampf(position.y, 8.0, maxf(8.0, area.y - target.y - 8.0))
	frame.position = position

func _add_task_button(frame: WindowFrame) -> void:
	var button := Button.new()
	button.text = frame.window_title
	button.icon = frame.window_icon
	button.toggle_mode = true
	button.focus_mode = Control.FOCUS_NONE
	button.clip_text = true
	button.custom_minimum_size = Vector2(140, 36)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", 11)
	button.add_theme_constant_override("icon_max_width", 16)
	button.tooltip_text = frame.window_title
	button.pressed.connect(_on_task_button_pressed.bind(frame))
	task_buttons.add_child(button)
	_task_buttons[frame] = button

func _on_task_button_pressed(frame: WindowFrame) -> void:
	if not is_instance_valid(frame):
		return
	if not frame.visible:
		frame.restore()
		_bring_to_front(frame)
	elif frame == _active_window:
		frame.minimize()
	else:
		_bring_to_front(frame)

func _bring_to_front(window: WindowFrame) -> void:
	if not is_instance_valid(window) or not window.visible:
		return
	window_layer.move_child(window, window_layer.get_child_count() - 1)
	for candidate in _windows:
		if is_instance_valid(candidate):
			candidate.set_active(candidate == window)
	_active_window = window
	_update_task_buttons()

func _on_window_focus(window: WindowFrame) -> void:
	_bring_to_front(window)

func _on_window_minimize(window: WindowFrame) -> void:
	_update_task_buttons()
	if window == _active_window:
		_active_window = null
		_activate_topmost_visible()

func _on_window_close(window: WindowFrame) -> void:
	_windows.erase(window)
	if _task_buttons.has(window):
		var button: Button = _task_buttons[window]
		_task_buttons.erase(window)
		button.queue_free()
	if is_instance_valid(window):
		window.visible = false
	if window == _active_window:
		_active_window = null
		_activate_topmost_visible()
	else:
		_update_task_buttons()

func _activate_topmost_visible() -> void:
	for i in range(window_layer.get_child_count() - 1, -1, -1):
		var frame := window_layer.get_child(i) as WindowFrame
		if frame and frame.visible:
			_bring_to_front(frame)
			return
	for candidate in _windows:
		if is_instance_valid(candidate):
			candidate.set_active(false)
	_active_window = null
	_update_task_buttons()

func _update_task_buttons() -> void:
	for frame in _task_buttons.keys():
		if not is_instance_valid(frame):
			continue
		var button: Button = _task_buttons[frame]
		button.button_pressed = (frame == _active_window and frame.visible)

func _window_at(global_point: Vector2) -> WindowFrame:
	for i in range(window_layer.get_child_count() - 1, -1, -1):
		var frame := window_layer.get_child(i) as WindowFrame
		if frame and frame.visible and frame.get_global_rect().has_point(global_point):
			return frame
	return null

# ---------------------------------------------------------------------------
# Меню «Пуск», трей и системные клики
# ---------------------------------------------------------------------------

func _on_start_button_pressed() -> void:
	if start_menu.visible:
		_close_start_menu()
	else:
		_open_start_menu()

func _open_start_menu() -> void:
	start_menu.visible = true
	start_button.set_pressed_no_signal(true)
	start_search.text = ""
	_on_start_search_changed("")
	_hide_tray_popup()
	start_search.grab_focus()

func _close_start_menu() -> void:
	if not start_menu.visible:
		return
	start_menu.visible = false
	start_button.set_pressed_no_signal(false)
	start_search.release_focus()

func _on_start_item_activated(app_id: String) -> void:
	open_app(app_id)
	_close_start_menu()

func _on_start_search_changed(query: String) -> void:
	var needle := query.strip_edges().to_lower()
	for item in start_items.get_children():
		if item is StartMenuItem:
			item.visible = needle.is_empty() or item.item_title.to_lower().contains(needle)

func _on_start_search_submitted(_query: String) -> void:
	for item in start_items.get_children():
		if item is StartMenuItem and item.visible:
			_on_start_item_activated(item.app_id)
			return

func _on_tray_pressed(kind: String) -> void:
	if tray_popup.visible and _tray_kind == kind:
		_hide_tray_popup()
		return
	_tray_kind = kind
	match kind:
		"volume":
			tray_popup_label.text = "Громкость: 68%\nЗвук ноутбука включён."
		"network":
			tray_popup_label.text = "Сеть: нет подключения\nЛокальный сеанс, без внешней сети."
		"battery":
			tray_popup_label.text = "Батарея: 84%\nПитание от сети."
		_:
			tray_popup_label.text = ""
	tray_popup.visible = true
	call_deferred("_position_tray_popup")

func _position_tray_popup() -> void:
	if not tray_popup.visible:
		return
	var popup_size := tray_popup.get_combined_minimum_size()
	tray_popup.size = popup_size
	tray_popup.position = Vector2(
		taskbar.position.x + taskbar.size.x - popup_size.x - 8.0,
		taskbar.position.y - popup_size.y - 6.0
	)

func _hide_tray_popup() -> void:
	tray_popup.visible = false
	_tray_kind = ""

func _on_viewport_resized() -> void:
	if tray_popup.visible:
		_position_tray_popup()
	for window in _windows:
		if is_instance_valid(window):
			window.call("_clamp_to_parent")

func _on_shutdown_pressed() -> void:
	shutdown_dialog.popup_centered(Vector2i(440, 170))

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and not key.echo and key.keycode == KEY_ESCAPE:
			if start_menu.visible:
				_close_start_menu()
				get_viewport().set_input_as_handled()
			elif tray_popup.visible:
				_hide_tray_popup()
				get_viewport().set_input_as_handled()
		return

	if not (event is InputEventMouseButton):
		return
	var mouse := event as InputEventMouseButton
	if not mouse.pressed or mouse.button_index != MOUSE_BUTTON_LEFT:
		return
	var point := mouse.position

	# Клики внутри плавающих панелей не должны их закрывать.
	if start_menu.visible and start_menu.get_global_rect().has_point(point):
		return
	if tray_popup.visible and tray_popup.get_global_rect().has_point(point):
		return

	if start_menu.visible and not start_button.get_global_rect().has_point(point):
		_close_start_menu()
	if tray_popup.visible:
		_hide_tray_popup()

	if point.y >= taskbar.position.y:
		return

	var clicked := _window_at(point)
	if clicked:
		_bring_to_front(clicked)

func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse := event as InputEventMouseButton
	if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
		_clear_selection()
