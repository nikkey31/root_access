class_name InfoCard
extends Control

## Модальная ретро-карточка для приложений: свойства фото, карточка места,
## подтверждение действия. Затемняет приложение и блокирует клики под собой.

signal closed
signal action_pressed

@onready var title_label: Label = $Center/Dialog/VBox/Header/HBox/TitleLabel
@onready var body_label: RichTextLabel = $Center/Dialog/VBox/BodyMargin/BodyLabel
@onready var action_button: Button = $Center/Dialog/VBox/Footer/FooterRow/ActionButton
@onready var close_button: Button = $Center/Dialog/VBox/Footer/FooterRow/CloseButton
@onready var close_x: Button = $Center/Dialog/VBox/Header/HBox/CloseX
@onready var dim: ColorRect = $Dim

var _action_result: String = ""

func _ready() -> void:
	visible = false
	close_x.pressed.connect(close)
	close_button.pressed.connect(close)
	action_button.pressed.connect(_on_action_pressed)
	dim.gui_input.connect(_on_dim_gui_input)

func open(title: String, body: String, action_text: String = "", action_result: String = "") -> void:
	title_label.text = title
	body_label.text = body
	_action_result = action_result
	action_button.visible = action_text != ""
	action_button.disabled = false
	action_button.text = action_text
	visible = true
	body_label.scroll_to_line(0)

func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()

func _on_action_pressed() -> void:
	action_pressed.emit()
	if _action_result.is_empty():
		close()
		return
	body_label.text = _action_result
	action_button.visible = false

func _on_dim_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close()

func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey):
		return
	var key := event as InputEventKey
	if key.pressed and not key.echo and key.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()
