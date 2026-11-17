class_name MapPreview
extends Control

## Интерактивная карта города приложения «Карты».
## Отображает растровую ретро-карту (assets/maps/city_map.jpg) и семь
## кликабельных точек интереса поверх неё.

signal marker_clicked(marker: Dictionary)

const CITY_MAP_PATH := "res://assets/maps/city_map.jpg"

const MARKERS := [
	{
		"name": "Дом Саймона",
		"address": "ул. Береговая, 14",
		"card_address": "Адрес: ул. Береговая, 14  [BEREGOVAYA 14]",
		"note": "Частный одноэтажный дом. Указан как адрес проживания С. Раклина.",
		"action": "[ Отправить группу захвата ]",
		"action_result": "Группа захвата направлена по адресу: ул. Береговая, 14.\nОжидайте доклад с места.",
		"pos": Vector2(0.71, 0.22),
		"color": Color(0.16, 0.32, 0.56),
		"key": false,
	},
	{
		"name": "Дом брата",
		"address": "ул. Мира, 8",
		"card_address": "Адрес: ул. Мира, 8  [MIRA 8]",
		"note": "Жилой дом. Зарегистрирован на Е. Рейвенса.",
		"action": "[ Отправить группу захвата ]",
		"action_result": "Группа захвата направлена по адресу: ул. Мира, 8.\nОжидайте доклад с места.",
		"pos": Vector2(0.42, 0.24),
		"color": Color(0.16, 0.32, 0.56),
		"key": false,
	},
	{
		"name": "Гаражи",
		"address": "ГК «Восток», сектор Д",
		"card_address": "Адрес: ГК «Восток», сектор Д  [VOSTOK D]",
		"note": "Ряд металлических гаражных боксов на восточной окраине.",
		"action": "[ Отправить группу захвата ]",
		"action_result": "Группа захвата направлена в ГК «Восток».\nОжидайте доклад с места.",
		"pos": Vector2(0.64, 0.44),
		"color": Color(0.32, 0.32, 0.32),
		"key": false,
	},
	{
		"name": "Адрес Мишель",
		"address": "ул. Ленина, 54",
		"card_address": "Адрес: ул. Ленина, 54  [LENINA 54]",
		"note": "Многоквартирный жилой дом. Место проживания М. Юхновой.",
		"action": "[ Отправить группу захвата ]",
		"action_result": "Группа захвата направлена по адресу: ул. Ленина, 54.\nОжидайте доклад с места.",
		"pos": Vector2(0.28, 0.46),
		"color": Color(0.16, 0.32, 0.56),
		"key": false,
	},
	{
		"name": "Бокс № 6752",
		"address": "Северная промзона, бокс 6752",
		"card_address": "Адрес: Северная промзона, бокс 6752  [BOX 6752]",
		"note": "Одиночный металлический бокс в промышленном секторе.",
		"action": "[ Отправить группу захвата ]",
		"action_result": "Группа захвата направлена в Бокс № 6752.\nОжидайте доклад с места.",
		"pos": Vector2(0.64, 0.72),
		"color": Color(0.32, 0.32, 0.32),
		"key": false,
	},
	{
		"name": "Склад № 3",
		"address": "Северная промзона, пр. Заводской, 12",
		"card_address": "Адрес: Северная промзона, пр. Заводской, 12  [ZAVODSKOY 12]",
		"note": "Заброшенный складской комплекс за бетонным забором.",
		"action": "[ Отправить группу захвата ]",
		"action_result": "Группа захвата направлена на Склад № 3.\nОжидайте доклад с места.",
		"pos": Vector2(0.83, 0.67),
		"color": Color(0.32, 0.32, 0.32),
		"key": false,
	},
	{
		"name": "Свалка",
		"address": "Окружное шоссе, 9-й км",
		"card_address": "Адрес: Окружное шоссе, 9-й км  [OKRUZHNOE 9]",
		"note": "Заброшенный пункт приёма металлолома за городом.",
		"action": "[ Отправить группу захвата ]",
		"action_result": "Группа захвата направлена на Свалку (9-й км).\nОжидайте доклад с места.",
		"pos": Vector2(0.16, 0.80),
		"color": Color(0.32, 0.32, 0.32),
		"key": false,
	},
]

var _font: Font
var _map_texture: Texture2D = null
var _marker_buttons: Array[Button] = []
var _hovered_marker: int = -1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	clip_contents = true
	_font = get_theme_font("font", "Label")
	if _font == null:
		_font = ThemeDB.fallback_font
	_load_map_texture()
	_build_marker_buttons()
	resized.connect(_layout_marker_buttons)
	resized.connect(queue_redraw)

func _load_map_texture() -> void:
	if ResourceLoader.exists(CITY_MAP_PATH):
		_map_texture = load(CITY_MAP_PATH) as Texture2D
	if _map_texture == null:
		var abs_path := ProjectSettings.globalize_path(CITY_MAP_PATH)
		if FileAccess.file_exists(abs_path):
			var img := Image.load_from_file(abs_path)
			if img != null and not img.is_empty():
				_map_texture = ImageTexture.create_from_image(img)

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
		var point := Vector2(roundf(size.x * marker["pos"].x), roundf(size.y * marker["pos"].y))
		var label: String = marker["name"]
		var text_w := _font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x + 12.0
		var flip_left := point.x + 14.0 + text_w > size.x - 6.0
		var left_x := (point.x - text_w - 14.0) if flip_left else (point.x - 10.0)
		var total_w := text_w + 26.0
		left_x = clampf(left_x, 2.0, maxf(2.0, size.x - total_w - 2.0))
		var button := _marker_buttons[index]
		button.position = Vector2(left_x, point.y - 18.0)
		button.size = Vector2(total_w, 32.0)

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

	if _map_texture != null:
		draw_texture_rect(_map_texture, Rect2(Vector2.ZERO, size), false)
	else:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.91, 0.89, 0.79))

	# Лёгкая координатная сетка поверх карты (стиль ГИС 2000-х).
	for x in range(0, int(w), 48):
		draw_line(Vector2(x, 0), Vector2(x, h), Color(0, 0, 0, 0.06), 1.0)
	for y in range(0, int(h), 48):
		draw_line(Vector2(0, y), Vector2(w, y), Color(0, 0, 0, 0.06), 1.0)

	# Лаконичные географические подписи районов.
	_draw_caption_tag(Vector2(w * 0.56, h * 0.88), "СЕВЕРНАЯ ПРОМЗОНА")
	_draw_caption_tag(Vector2(w * 0.85, h * 0.36), "р. Тёмная")
	_draw_caption_tag(Vector2(w * 0.24, h * 0.34), "ул. Ленина")

	# Точки интереса.
	for index in range(MARKERS.size()):
		_draw_marker(MARKERS[index], index)

func _draw_marker(marker: Dictionary, index: int) -> void:
	var pos: Vector2 = Vector2(roundf(size.x * marker["pos"].x), roundf(size.y * marker["pos"].y))
	var color: Color = marker["color"]
	var hovered := index == _hovered_marker
	if hovered:
		draw_rect(Rect2(pos - Vector2(9, 9), Vector2(18, 18)), Color(1.0, 0.95, 0.55, 0.65))
		draw_rect(Rect2(pos - Vector2(9, 9), Vector2(18, 18)), Color(0.0, 0.0, 0.5, 1.0), false, 1.0)
	# Строгая квадратная ретро-метка с чёрной рамкой (стиль карт 90-х).
	draw_line(pos + Vector2(0, 6), pos + Vector2(0, 14), Color(0, 0, 0, 1), 2.0)
	draw_rect(Rect2(pos - Vector2(6, 6), Vector2(12, 12)), color)
	draw_rect(Rect2(pos - Vector2(6, 6), Vector2(12, 12)), Color(0, 0, 0, 1), false, 1.0)
	draw_rect(Rect2(pos - Vector2(2, 2), Vector2(4, 4)), Color(1, 1, 1, 1))

	var label: String = marker["name"]
	var font_size := 10
	var text_size := _font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var flip_left := pos.x + 11.0 + text_size.x + 6.0 > size.x - 4.0
	var label_x := (pos.x - text_size.x - 14.0) if flip_left else (pos.x + 11.0)
	var label_pos := Vector2(roundf(label_x), roundf(pos.y - 6.0))
	var rect := Rect2(label_pos - Vector2(3, 12), Vector2(text_size.x + 6, 16))
	draw_rect(rect, Color(1, 1, 0.86, 1.0) if hovered else Color(0.96, 0.96, 0.92, 0.96))
	draw_rect(rect, Color(0.0, 0.0, 0.5, 1.0) if hovered else Color(0.15, 0.15, 0.15, 0.95), false, 1.0)
	draw_string(_font, label_pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.05, 0.05, 0.05, 1.0))

func _draw_caption_tag(pos: Vector2, text: String) -> void:
	var font_size := 9
	var ts := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var rect := Rect2(pos - Vector2(3, 10), Vector2(ts.x + 6, 13))
	draw_rect(rect, Color(0.95, 0.93, 0.86, 0.72))
	draw_string(_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.22, 0.20, 0.16, 0.95))
