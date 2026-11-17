class_name ToastBanner
extends PanelContainer

## Всплывающая ретро-подсказка в правом нижнем углу над треем.
## Используется для системных уведомлений и подсказок на Лёгкой/Средней сложности.

@onready var message_label: Label = $Margin/Row/MessageLabel
@onready var close_button: Button = $Margin/Row/CloseButton

var _hide_timer: float = 0.0

func _ready() -> void:
	visible = false
	close_button.pressed.connect(hide_banner)

func show_message(text: String, duration: float = 6.5) -> void:
	var cleaned := text.strip_edges()
	if cleaned.is_empty():
		return
	message_label.text = cleaned
	_hide_timer = duration
	visible = true

func hide_banner() -> void:
	visible = false
	_hide_timer = 0.0

func _process(delta: float) -> void:
	if not visible or _hide_timer <= 0.0:
		return
	_hide_timer -= delta
	if _hide_timer <= 0.0:
		hide_banner()
