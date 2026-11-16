class_name WindowFrame
extends PanelContainer

## Каркас ретро-окна Windows 98 / 2000 (WindowFrame.tscn).
## Предоставляет заголовок с кнопками управления и контейнер для встроенных приложений.

signal close_requested
signal minimize_requested

@export var window_title: String = "Командная строка"
@export var app_scene: PackedScene

@onready var title_label: Label = $VBoxContainer/TitleBar/HBoxContainer/TitleLabel
@onready var btn_close: Button = $VBoxContainer/TitleBar/HBoxContainer/BtnClose
@onready var btn_minimize: Button = $VBoxContainer/TitleBar/HBoxContainer/BtnMinimize
@onready var content_container: MarginContainer = $VBoxContainer/ContentContainer

var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	title_label.text = window_title
	btn_close.pressed.connect(func(): close_requested.emit(); queue_free())
	btn_minimize.pressed.connect(func(): minimize_requested.emit())
	
	$VBoxContainer/TitleBar.gui_input.connect(_on_titlebar_gui_input)
	
	# Если назначена сцена приложения, встраиваем её в ContentContainer
	if app_scene:
		embed_app(app_scene.instantiate())

func embed_app(app_node: Control) -> void:
	for child in content_container.get_children():
		child.queue_free()
	content_container.add_child(app_node)

func _on_titlebar_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				is_dragging = true
				drag_offset = get_global_mouse_position() - global_position
			else:
				is_dragging = false
	elif event is InputEventMouseMotion and is_dragging:
		global_position = get_global_mouse_position() - drag_offset
