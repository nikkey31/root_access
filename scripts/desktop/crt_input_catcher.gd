extends Control

## Ловит сырые события мыши поверх CRT-линзы и передаёт их в Desktop
## для обратного преобразования координат. Без этого маленькие кнопки
## (например, «Свернуть») могли промахиваться из-за искажения.

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 3000
	focus_mode = Control.FOCUS_NONE

func _gui_input(event: InputEvent) -> void:
	var desktop := get_parent()
	if desktop and desktop.has_method("handle_crt_gui_input"):
		desktop.handle_crt_gui_input(event)
		accept_event()
