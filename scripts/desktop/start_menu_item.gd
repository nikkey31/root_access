class_name StartMenuItem
extends Button

## Пункт меню «Пуск»: плоская строка, подсвечивающаяся синим,
## с иконкой приложения и идентификатором для оконного менеджера.

signal activated(app_id: String)

@export var app_id: String = ""
@export var item_title: String = "Приложение":
	set(value):
		item_title = value
		if is_node_ready():
			text = value

@export var item_icon: Texture2D:
	set(value):
		item_icon = value
		if is_node_ready():
			icon = value

func _ready() -> void:
	text = item_title
	if item_icon:
		icon = item_icon
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	tooltip_text = item_title
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	activated.emit(app_id)
