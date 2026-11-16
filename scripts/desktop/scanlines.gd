extends Control

## Тонкий оверлей ЭЛТ-монитора: горизонтальные линии развёртки и лёгкое
## мерцание. Полностью прозрачен для мыши и не влияет на работу UI.

@export var line_spacing: int = 3
@export var line_color: Color = Color(0, 0, 0, 0.055)
@export var bright_color: Color = Color(1, 1, 1, 0.018)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var height := int(size.y)
	if height <= 0:
		return
	var y := 0
	var index := 0
	while y < height:
		draw_line(Vector2(0, y), Vector2(size.x, y), line_color, 1.0)
		if index % 9 == 0:
			draw_line(Vector2(0, y + 1), Vector2(size.x, y + 1), bright_color, 1.0)
		y += maxi(1, line_spacing)
		index += 1
