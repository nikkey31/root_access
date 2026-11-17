class_name MapPreview
extends Control

## Декоративная карта города для макета приложения «Карты».
## Рисует кварталы, дороги, реку и семь сюжетных точек интереса.
## Поверх рисунка лежат настоящие кнопки-метки: клик открывает карточку места.

signal marker_clicked(marker: Dictionary)

const MARKERS := [
	{
		"name": "Дом Саймона",
		"address": "ул. Лесная, 12",
		"note": "Жилой дом. Здесь живёт Саймон Раклин.",
		"pos": Vector2(0.24, 0.30),
		"color": Color(0.15, 0.35, 0.75),
		"key": false,
	},
	{
		"name": "Дом брата",
		"address": "ул. Мира, 8",
		"note": "Квартира Юджина Рейвенса, брата Саймона.",
		"pos": Vector2(0.48, 0.20),
		"color": Color(0.15, 0.35, 0.75),
		"key": false,
	},
	{
		"name": "Гаражи",
		"address": "Гаражный кооператив «Мотор»",
		"note": "Здесь стоит ржавый пикап со снимка из Галереи.",
		"pos": Vector2(0.72, 0.30),
		"color": Color(0.45, 0.35, 0.15),
		"key": false,
	},
	{
		"name": "Адрес Мишель",
		"address": "ул. Ленина, 54",
		"card_address": "Address: LENINA 54",
		"note": "Домашний адрес Мишель Юхновой. Адрес записан латиницей — пригодится для дешифровки.",
		"pos": Vector2(0.34, 0.55),
		"color": Color(0.72, 0.20, 0.22),
		"key": false,
	},
	{
		"name": "Бокс № 6752",
		"address": "Северная промзона, бокс 6752",
		"note": "Арендованный бокс. Проверить, не ложный ли это след.",
		"pos": Vector2(0.62, 0.68),
		"color": Color(0.45, 0.35, 0.15),
		"key": false,
	},
	{
		"name": "Склад № 3",
		"address": "Северная промзона, ворота 3",
		"note": "По накладной сюда привезли оборудование на фургоне 6752. Здесь держат Мишель.",
		"action": "[ Отправить группу захвата ]",
		"action_result": "Группа захвата направлена на Склад № 3.\nОжидайте доклад с места.",
		"pos": Vector2(0.82, 0.58),
		"color": Color(0.78, 0.12, 0.12),
		"key": true,
	},
	{
		"name": "Свалка",
		"address": "За городом, 14-й км",
		"note": "Заброшенная свалка. Одна из ложных точек на карте.",
		"pos": Vector2(0.18, 0.80),
		"color": Color(0.35, 0.35, 0.35),
		"key": false,
	},
]

var _font: Font
var _marker_buttons: Array[Button] = []
var _hovered_marker: int = -1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	clip_contents = true
	_font = get_theme_font("font", "Label")
	if _font == null:
		_font = ThemeDB.fallback_font
	_build_marker_buttons()
	resized.connect(_layout_marker_buttons)
	resized.connect(queue_redraw)

func _build_marker_buttons() -> void:
	for index in range(MARKERS.size()):
		var marker: Dictionary = MARKERS[index]
		var button := Button.new()
		button.flat = true
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.tooltip_text = "%s — %s" % [marker["name"], marker["address"]]
		var empty := StyleBoxEmpty.new()
		for state in ["normal", "hover", "pressed", "focus", "disabled"]:
			button.add_theme_stylebox_override(state, empty)
		button.pressed.connect(_on_marker_pressed.bind(index))
		button.mouse_entered.connect(_on_marker_entered.bind(index))
		button.mouse_exited.connect(_on_marker_exited)
		add_child(button)
		_marker_buttons.append(button)
	_layout_marker_buttons()

func _layout_marker_buttons() -> void:
	if _marker_buttons.is_empty():
		return
	for index in range(_marker_buttons.size()):
		var marker: Dictionary = MARKERS[index]
		var point := Vector2(size.x * marker["pos"].x, size.y * marker["pos"].y)
		var width := 180.0
		var x := point.x - 4.0
		if x + width > size.x:
			x = maxf(0.0, size.x - width)
		var button := _marker_buttons[index]
		button.position = Vector2(x, point.y - 18.0)
		button.size = Vector2(width, 30.0)

func _on_marker_pressed(index: int) -> void:
	marker_clicked.emit(MARKERS[index])

func _on_marker_entered(index: int) -> void:
	_hovered_marker = index
	queue_redraw()

func _on_marker_exited() -> void:
	_hovered_marker = -1
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 40.0 or h < 40.0:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.91, 0.89, 0.79))

	# Лёгкая миллиметровая сетка.
	for x in range(0, int(w), 36):
		draw_line(Vector2(x, 0), Vector2(x, h), Color(0, 0, 0, 0.045), 1.0)
	for y in range(0, int(h), 36):
		draw_line(Vector2(0, y), Vector2(w, y), Color(0, 0, 0, 0.045), 1.0)

	# Парк и река.
	draw_rect(Rect2(w * 0.05, h * 0.58, w * 0.22, h * 0.28), Color(0.68, 0.78, 0.56))
	draw_circle(Vector2(w * 0.10, h * 0.68), 9.0, Color(0.42, 0.58, 0.36))
	draw_circle(Vector2(w * 0.18, h * 0.78), 12.0, Color(0.42, 0.58, 0.36))
	var river := PackedVector2Array([
		Vector2(w * 0.90, 0), Vector2(w * 0.95, h * 0.22),
		Vector2(w * 0.88, h * 0.42), Vector2(w * 0.92, h * 0.62),
		Vector2(w * 0.86, h * 0.82), Vector2(w * 0.90, h),
		Vector2(w, h), Vector2(w, 0),
	])
	draw_colored_polygon(river, Color(0.55, 0.72, 0.80))

	# Кварталы.
	var blocks: Array[Rect2] = [
		Rect2(w * 0.06, h * 0.10, w * 0.12, h * 0.12),
		Rect2(w * 0.23, h * 0.08, w * 0.16, h * 0.14),
		Rect2(w * 0.54, h * 0.08, w * 0.16, h * 0.12),
		Rect2(w * 0.74, h * 0.12, w * 0.10, h * 0.10),
		Rect2(w * 0.08, h * 0.38, w * 0.14, h * 0.12),
		Rect2(w * 0.42, h * 0.38, w * 0.16, h * 0.12),
		Rect2(w * 0.68, h * 0.42, w * 0.12, h * 0.10),
		Rect2(w * 0.22, h * 0.68, w * 0.12, h * 0.10),
		Rect2(w * 0.44, h * 0.78, w * 0.18, h * 0.10),
	]
	for block in blocks:
		draw_rect(block, Color(0.80, 0.75, 0.63))
		draw_rect(block, Color(0.66, 0.60, 0.48), false, 1.0)
		var inner := block.grow(-4)
		if inner.size.x > 0 and inner.size.y > 0:
			draw_rect(inner, Color(0.86, 0.82, 0.71))

	# Дороги: тёмная кромка + светлое полотно.
	_draw_road(Vector2(0, h * 0.32), Vector2(w, h * 0.26), 16.0)
	_draw_road(Vector2(0, h * 0.72), Vector2(w, h * 0.64), 20.0)
	_draw_road(Vector2(w * 0.20, 0), Vector2(w * 0.28, h), 14.0)
	_draw_road(Vector2(w * 0.56, 0), Vector2(w * 0.50, h), 14.0)
	_draw_road(Vector2(w * 0.80, 0), Vector2(w * 0.74, h), 12.0)
	_draw_road(Vector2(w * 0.20, h * 0.32), Vector2(w * 0.56, h * 0.72), 10.0)

	# Промзона.
	draw_rect(Rect2(w * 0.52, h * 0.52, w * 0.32, h * 0.32), Color(0.73, 0.70, 0.62, 0.45))
	draw_rect(Rect2(w * 0.52, h * 0.52, w * 0.32, h * 0.32), Color(0.55, 0.50, 0.42, 0.7), false, 1.0)
	for x in range(int(w * 0.54), int(w * 0.82), 10):
		draw_line(Vector2(x, h * 0.54), Vector2(x, h * 0.82), Color(0.55, 0.50, 0.42, 0.18), 1.0)

	_draw_caption(Vector2(w * 0.54, h * 0.55), "СЕВЕРНАЯ ПРОМЗОНА", Color(0.40, 0.35, 0.28, 0.9), 9)
	_draw_caption(Vector2(w * 0.60, h * 0.86), "р. Тёмная", Color(0.30, 0.45, 0.55, 0.9), 9)
	_draw_caption(Vector2(w * 0.26, h * 0.34), "ул. Ленина", Color(0.35, 0.35, 0.35, 0.8), 9)

	# Точки интереса.
	for index in range(MARKERS.size()):
		_draw_marker(MARKERS[index], index)

func _draw_road(from: Vector2, to: Vector2, width: float) -> void:
	draw_line(from, to, Color(0.63, 0.58, 0.49), width + 3.0)
	draw_line(from, to, Color(0.97, 0.95, 0.88), width)
	draw_line(from, to, Color(1.0, 1.0, 1.0, 0.45), 1.0)

func _draw_marker(marker: Dictionary, index: int) -> void:
	var pos: Vector2 = Vector2(size.x * marker["pos"].x, size.y * marker["pos"].y)
	var color: Color = marker["color"]
	var key: bool = marker["key"]
	var hovered := index == _hovered_marker
	if key:
		draw_circle(pos, 16.0, Color(1, 1, 1, 0.75))
		draw_arc(pos, 16.0, 0, TAU, 32, color, 2.0)
	if hovered:
		draw_circle(pos, 15.0, Color(1.0, 0.95, 0.55, 0.35))
		draw_arc(pos, 15.0, 0, TAU, 32, Color(0.1, 0.25, 0.65, 1.0), 2.0)
	# Булавка: круг с ножкой.
	draw_circle(pos + Vector2(0, 3), 8.0, Color(0, 0, 0, 0.18))
	draw_circle(pos, 8.0, color)
	draw_circle(pos, 8.0, Color(0, 0, 0, 0.35), false, 1.0)
	draw_circle(pos, 3.0, Color(1, 1, 1, 0.9))
	draw_line(pos + Vector2(0, 7), pos + Vector2(0, 15), color, 2.0)

	var label: String = marker["name"]
	var font_size := 10 if not key else 11
	var text_size := _font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var label_pos := pos + Vector2(12, -8)
	var rect := Rect2(label_pos - Vector2(3, 12), Vector2(text_size.x + 6, 16))
	draw_rect(rect, Color(1, 1, 0.86, 0.98) if hovered else Color(1, 1, 1, 0.88))
	draw_rect(rect, Color(0.1, 0.25, 0.65, 1.0) if hovered else (color if key else Color(0.55, 0.55, 0.55, 0.6)), false, 1.0)
	draw_string(_font, label_pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color.darkened(0.35))

func _draw_caption(pos: Vector2, text: String, color: Color, font_size: int) -> void:
	draw_string(_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
