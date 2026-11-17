class_name WindowFrame
extends PanelContainer

## Универсальное перетаскиваемое окно в стиле Windows 98 / 2000.
##
## Каркас отвечает только за «хром» окна: заголовок, кнопки управления,
## перетаскивание и слой контента. Само приложение встраивается в
## ContentContainer через embed_app() или свойство app_scene.
##
## Сигналы прокидываются в оконный менеджер рабочего стола, чтобы он мог
## обновить панель задач и z-порядок. Кнопки при этом работают и автономно.

signal close_requested
signal minimize_requested
signal focus_requested

@export var window_title: String = "Окно":
	set(value):
		window_title = value
		if is_node_ready() and title_label:
			title_label.text = value

@export var window_icon: Texture2D:
	set(value):
		window_icon = value
		if is_node_ready() and title_icon:
			title_icon.texture = value
			title_icon.visible = value != null

## Необязательная сцена приложения. Если задана, она автоматически
## встраивается при добавлении окна в дерево.
@export var app_scene: PackedScene

@export var title_active_style: StyleBox
@export var title_inactive_style: StyleBox
@export var min_window_size: Vector2 = Vector2(360, 220)

## Сколько пикселей заголовка обязано оставаться на экране при перетаскивании.
@export var keep_visible_margin: float = 84.0

@onready var title_bar: PanelContainer = $VBoxContainer/TitleBar
@onready var title_label: Label = $VBoxContainer/TitleBar/HBoxContainer/TitleLabel
@onready var title_icon: TextureRect = $VBoxContainer/TitleBar/HBoxContainer/TitleIcon
@onready var content_container: MarginContainer = $VBoxContainer/ContentContainer
@onready var btn_minimize: Button = $VBoxContainer/TitleBar/HBoxContainer/BtnMinimize
@onready var btn_close: Button = $VBoxContainer/TitleBar/HBoxContainer/BtnClose

var is_active: bool = false

var _is_dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _closed: bool = false

func _ready() -> void:
	custom_minimum_size = min_window_size
	title_label.text = window_title
	if window_icon:
		title_icon.texture = window_icon
		title_icon.visible = true
	else:
		title_icon.visible = false

	btn_minimize.pressed.connect(_on_minimize_pressed)
	btn_close.pressed.connect(_on_close_pressed)
	title_bar.gui_input.connect(_on_title_bar_gui_input)
	title_bar.mouse_default_cursor_shape = Control.CURSOR_DRAG

	if app_scene:
		var instance := app_scene.instantiate()
		if instance is Control:
			embed_app(instance)
		else:
			push_warning("WindowFrame.app_scene должна быть Control-сценой.")

	set_active(is_active)

## Встроить приложение в контентную область. Старый контент удаляется.
func embed_app(app_node: Control) -> void:
	if not is_instance_valid(app_node):
		return
	for child in content_container.get_children():
		content_container.remove_child(child)
		child.queue_free()
	app_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	app_node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_container.add_child(app_node)

## Совместимый алиас для сцен, которым удобнее называть метод set_content().
func set_content(app_node: Control) -> void:
	embed_app(app_node)

func set_active(value: bool) -> void:
	is_active = value
	if not is_node_ready():
		return
	if value:
		if title_active_style:
			title_bar.add_theme_stylebox_override("panel", title_active_style)
		title_label.add_theme_color_override("font_color", Color.WHITE)
		title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
		title_icon.modulate = Color.WHITE
	else:
		if title_inactive_style:
			title_bar.add_theme_stylebox_override("panel", title_inactive_style)
		title_label.add_theme_color_override("font_color", Color(0.86, 0.86, 0.86))
		title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.35))
		title_icon.modulate = Color(0.78, 0.78, 0.78)

func minimize() -> void:
	if not visible:
		return
	visible = false
	minimize_requested.emit()

func restore() -> void:
	visible = true

func close() -> void:
	if _closed:
		return
	_closed = true
	close_requested.emit()
	queue_free()

func _on_minimize_pressed() -> void:
	minimize()

func _on_close_pressed() -> void:
	close()

func _on_title_bar_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT:
			return
		if event.pressed:
			focus_requested.emit()
			_is_dragging = true
			_drag_offset = event.global_position - global_position
			accept_event()
		elif _is_dragging:
			_is_dragging = false
			accept_event()
	elif event is InputEventMouseMotion and _is_dragging:
		var motion := event as InputEventMouseMotion
		global_position = motion.global_position - _drag_offset
		_clamp_to_parent()
		accept_event()

## Страховка на случай, если курсор вышел за пределы заголовка во время
## быстрого перетаскивания: продолжаем вести окно до отпускания кнопки.
func _input(event: InputEvent) -> void:
	if not _is_dragging:
		return
	if event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		global_position = motion.global_position - _drag_offset
		_clamp_to_parent()
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT and not mouse.pressed:
			_is_dragging = false

## Не даём утащить окно за пределы рабочей области (над панелью задач)
## и оставляем минимум keep_visible_margin пикселей заголовка на экране.
func _clamp_to_parent() -> void:
	var parent_control := get_parent_control()
	if parent_control == null:
		return
	var bounds := parent_control.get_global_rect()
	var visible_x := minf(keep_visible_margin, size.x)
	var min_x := bounds.position.x - size.x + visible_x
	var max_x := bounds.end.x - visible_x
	var min_y := bounds.position.y
	# Нижняя кромка окна не должна заходить на панель задач.
	var max_y := maxf(min_y, bounds.end.y - size.y)
	global_position.x = clampf(global_position.x, min_x, maxf(min_x, max_x))
	global_position.y = clampf(global_position.y, min_y, max_y)
