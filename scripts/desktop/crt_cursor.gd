extends Control

## Программный курсор, который рисуется внутри искажаемого кадра.
## Благодаря этому он проходит через CRT-линзу и визуально остаётся
## ровно под реальной мышью (позиция задаётся уже с обратным искажением).

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 4096
	size = Vector2(24, 24)
	queue_redraw()

func _draw() -> void:
	var points := PackedVector2Array([
		Vector2(0, 0),
		Vector2(0, 18),
		Vector2(4, 14),
		Vector2(8, 22),
		Vector2(11, 20),
		Vector2(7, 12),
		Vector2(14, 12),
	])
	# Мягкая тень и классическая белая стрелка с чёрным контуром.
	var shadow := PackedVector2Array()
	for point in points:
		shadow.append(point + Vector2(1.5, 1.5))
	draw_colored_polygon(shadow, Color(0, 0, 0, 0.35))
	draw_colored_polygon(points, Color.WHITE)
	var outline := points.duplicate()
	outline.append(points[0])
	draw_polyline(outline, Color.BLACK, 1.0, true)
