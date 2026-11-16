class_name DesktopIcon
extends Control

## Иконка на рабочем столе: 48×48 пиктограмма, подпись до двух строк,
## выделение и активация. По умолчанию открывает приложение одиночным
## кликом (требование Issue #10); двойной клик также поддерживается.

signal pressed(icon: DesktopIcon)
signal activated(app_id: String)

@export var app_id: String = ""
@export var icon_title: String = "Приложение":
	set(value):
		icon_title = value
		if is_node_ready():
			label.text = value
			tooltip_text = value

@export var icon_texture: Texture2D:
	set(value):
		icon_texture = value
		if is_node_ready():
			icon_rect.texture = value

@export var single_click_opens: bool = true

@onready var icon_rect: TextureRect = $VBox/Icon
@onready var label: Label = $VBox/Label

var selected: bool = false:
	set(value):
		selected = value
		_update_visuals()

var _hovered: bool = false
var _box_selected: StyleBoxFlat
var _box_hover: StyleBoxFlat
var _box_empty: StyleBoxEmpty

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tooltip_text = icon_title
	label.text = icon_title
	if icon_texture:
		icon_rect.texture = icon_texture

	_box_selected = StyleBoxFlat.new()
	_box_selected.bg_color = Color(0, 0, 0.502, 0.9)
	_box_selected.content_margin_left = 2.0
	_box_selected.content_margin_right = 2.0
	_box_selected.content_margin_top = 1.0
	_box_selected.content_margin_bottom = 1.0

	_box_hover = StyleBoxFlat.new()
	_box_hover.bg_color = Color(0, 0, 0.35, 0.35)
	_box_hover.content_margin_left = 2.0
	_box_hover.content_margin_right = 2.0
	_box_hover.content_margin_top = 1.0
	_box_hover.content_margin_bottom = 1.0

	_box_empty = StyleBoxEmpty.new()

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	_update_visuals()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
			return
		grab_focus()
		pressed.emit(self)
		if single_click_opens or event.double_click:
			activated.emit(app_id)
		accept_event()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE:
			activated.emit(app_id)
			accept_event()

func _on_mouse_entered() -> void:
	_hovered = true
	_update_visuals()

func _on_mouse_exited() -> void:
	_hovered = false
	_update_visuals()

func _update_visuals() -> void:
	if not is_node_ready():
		return
	if selected:
		label.add_theme_stylebox_override("normal", _box_selected)
		label.add_theme_color_override("font_color", Color.WHITE)
		icon_rect.modulate = Color(0.62, 0.76, 1.0)
	elif _hovered:
		label.add_theme_stylebox_override("normal", _box_hover)
		label.add_theme_color_override("font_color", Color.WHITE)
		icon_rect.modulate = Color(1.0, 1.0, 1.0)
	else:
		label.add_theme_stylebox_override("normal", _box_empty)
		label.add_theme_color_override("font_color", Color.WHITE)
		icon_rect.modulate = Color(1.0, 1.0, 1.0)
	queue_redraw()

func _draw() -> void:
	# Классическая пунктирная рамка фокуса вокруг ячейки.
	if not (selected or has_focus()):
		return
	var rect := Rect2(2.0, 1.0, size.x - 4.0, size.y - 2.0)
	var color := Color(1, 1, 1, 0.85) if has_focus() else Color(0, 0, 0, 0.35)
	var step := 4.0
	var dash := 2.0
	var x := rect.position.x
	while x < rect.end.x:
		draw_rect(Rect2(x, rect.position.y, dash, 1.0), color)
		draw_rect(Rect2(x, rect.end.y - 1.0, dash, 1.0), color)
		x += step
	var y := rect.position.y
	while y < rect.end.y:
		draw_rect(Rect2(rect.position.x, y, 1.0, dash), color)
		draw_rect(Rect2(rect.end.x - 1.0, y, 1.0, dash), color)
		y += step
