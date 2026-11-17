extends Control

## Программный пиксельный курсор, который рисуется внутри искажаемого кадра.
## Благодаря этому он проходит через CRT-линзу и визуально остаётся
## ровно под реальной мышью (остриё текстуры строго в точке (0, 0)).

const CURSOR_TEXTURE := preload("res://assets/ui/cursor.png")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = 4096
	size = Vector2(24, 24)
	queue_redraw()

func _draw() -> void:
	if CURSOR_TEXTURE != null:
		draw_texture_rect(CURSOR_TEXTURE, Rect2(Vector2.ZERO, Vector2(24, 24)), false)
