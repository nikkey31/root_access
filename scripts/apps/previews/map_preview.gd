class_name MapPreview
extends Control

## Интерактивная карта города приложения «Карты».
## Отображает растровую ретро-карту (assets/maps/city_map.jpg) и 18
## кликабельных точек интереса поверх неё, с поддержкой поиска и слоя транспорта.

signal marker_clicked(marker: Dictionary)

const CITY_MAP_PATH := "res://assets/maps/city_map.jpg"

const MARKERS := [
	{
		"id": "my_home",
		"name": "Мой дом",
		"address": "SADOVAYA 12",
		"card_address": "Address: SADOVAYA 12",
		"note": "Одноэтажный частный дом",
		"action": "[ Отправить группу захвата ]",
		"action_result": "Группа захвата направлена по адресу: SADOVAYA 12.\nОжидайте доклад с места.",
		"pos": Vector2(0.72, 0.20),
		"color": Color(0.16, 0.32, 0.56),
		"key": false,
	},
	{
		"id": "brother_house",
		"name": "Дом брата",
		"address": "ZAVODSKAYA 7, APT 31",
		"card_address": "Address: ZAVODSKAYA 7, APT 31",
		"note": "Женя. Запасной ключ у соседки",
		"action": "[ Отправить группу захвата ]",
		"action_result": "Группа захвата направлена по адресу: ZAVODSKAYA 7, APT 31.\nОжидайте доклад с места.",
		"pos": Vector2(0.42, 0.22),
		"color": Color(0.16, 0.32, 0.56),
		"key": false,
	},
	{
		"id": "garages",
		"name": "Гаражи",
		"address": "GARAGE COOP VOSKHOD, ROW 4",
		"card_address": "Address: GARAGE COOP VOSKHOD, ROW 4",
		"note": "Мастерская, верстак",
		"action": "[ Отправить группу захвата ]",
		"action_result": "Группа захвата направлена в ГК «Восход» (ряд 4).\nОжидайте доклад с места.",
		"pos": Vector2(0.64, 0.44),
		"color": Color(0.32, 0.32, 0.32),
		"key": false,
	},
	{
		"id": "michelle_address",
		"name": "Адрес Мишель",
		"address": "LENINA 54",
		"card_address": "Address: LENINA 54",
		"note": "М.",
		"action": "[ Отправить группу захвата ]",
		"action_result": "Группа захвата направлена по адресу: LENINA 54.\nОжидайте доклад с места.",
		"pos": Vector2(0.27, 0.48),
		"color": Color(0.16, 0.32, 0.56),
		"key": false,
	},
	{
		"id": "box_6752",
		"name": "Бокс № 6752",
		"address": "GARAGE COOP VOSKHOD, BOX 6752",
		"card_address": "Address: GARAGE COOP VOSKHOD, BOX 6752",
		"note": "Старый бокс, давно не открывал",
		"action": "[ Отправить группу захвата ]",
		"action_result": "Группа захвата направлена в Бокс № 6752.\nОжидайте доклад с места.",
		"pos": Vector2(0.62, 0.72),
		"color": Color(0.32, 0.32, 0.32),
		"key": false,
	},
	{
		"id": "warehouse_3",
		"name": "Склад № 3",
		"address": "SEVERNAYA PROMZONA, WAREHOUSE 3",
		"card_address": "Address: SEVERNAYA PROMZONA, WAREHOUSE 3",
		"note": "Хранение оборудования",
		"action": "[ Отправить группу захвата ]",
		"action_result": "Группа захвата направлена на Склад № 3.\nОжидайте доклад с места.",
		"pos": Vector2(0.84, 0.67),
		"color": Color(0.32, 0.32, 0.32),
		"key": false,
	},
	{
		"id": "junkyard",
		"name": "Свалка",
		"address": "ZAVODSKOE SHOSSE 9",
		"card_address": "Address: ZAVODSKOE SHOSSE 9",
		"note": "Металлолом",
		"action": "[ Отправить группу захвата ]",
		"action_result": "Группа захвата направлена на Свалку (ZAVODSKOE SHOSSE 9).\nОжидайте доклад с места.",
		"pos": Vector2(0.16, 0.84),
		"color": Color(0.32, 0.32, 0.32),
		"key": false,
	},
	{
		"id": "service_motor",
		"name": "Автосервис «Мотор»",
		"address": "MOTORNAYA 3",
		"card_address": "Address: MOTORNAYA 3",
		"note": "Педаль, пружина",
		"action": "[ Отправить группу захвата ]",
		"action_result": "Группа захвата направлена в Автосервис «Мотор».\nОжидайте доклад с места.",
		"pos": Vector2(0.49, 0.80),
		"color": Color(0.32, 0.32, 0.32),
		"key": false,
	},
	{
		"id": "gas_trassa",
		"name": "АЗС «Трасса»",
		"address": "TRASSA M7, KM 14",
		"card_address": "Address: TRASSA M7, KM 14",
		"note": "Заправка",
		"action": "[ Отправить группу захвата ]",
		"action_result": "Группа захвата направлена на АЗС «Трасса».\nОжидайте доклад с места.",
		"pos": Vector2(0.76, 0.41),
		"color": Color(0.32, 0.32, 0.32),
		"key": false,
	},
	{
		"id": "bus_stop_uni",
		"name": "Остановка «Университет»",
		"address": "UNIVERSITETSKAYA 1",
		"card_address": "Address: UNIVERSITETSKAYA 1",
		"note": "Маршрут 14",
		"action": "[ Отправить группу захвата ]",
		"action_result": "Группа захвата направлена к остановке «Университет».\nОжидайте доклад с места.",
		"pos": Vector2(0.21, 0.35),
		"color": Color(0.20, 0.42, 0.30),
		"key": false,
	},
	{
		"id": "library",
		"name": "Библиотека",
		"address": "BIBLIOTECHNAYA 6",
		"card_address": "Address: BIBLIOTECHNAYA 6",
		"note": "—",
		"action": "[ Отправить группу захвата ]",
		"action_result": "Группа захвата направлена к Библиотеке.\nОжидайте доклад с места.",
		"pos": Vector2(0.36, 0.36),
		"color": Color(0.28, 0.34, 0.44),
		"key": false,
	},
	{
		"id": "cafe_ugolok",
		"name": "Кафе «Уголок»",
		"address": "UNIVERSITETSKAYA 3",
		"card_address": "Address: UNIVERSITETSKAYA 3",
		"note": "Утром открыто",
		"action": "[ Отправить группу захвата ]",
		"action_result": "Группа захвата направлена в Кафе «Уголок».\nОжидайте доклад с места.",
		"pos": Vector2(0.14, 0.46),
		"color": Color(0.28, 0.34, 0.44),
		"key": false,
	},
	{
		"id": "shop_produkty",
		"name": "Магазин «Продукты»",
		"address": "SADOVAYA 20",
		"card_address": "Address: SADOVAYA 20",
		"note": "—",
		"action": "[ Отправить группу захвата ]",
		"action_result": "Группа захвата направлена к магазину «Продукты».\nОжидайте доклад с места.",
		"pos": Vector2(0.58, 0.13),
		"color": Color(0.28, 0.34, 0.44),
		"key": false,
	},
	{
		"id": "vet_aibolit",
		"name": "Ветклиника «Айболит»",
		"address": "KOMSOMOLSKAYA 15",
		"card_address": "Address: KOMSOMOLSKAYA 15",
		"note": "Кот, прививка",
		"action": "[ Отправить группу захвата ]",
		"action_result": "Группа захвата направлена в ветклинику «Айболит».\nОжидайте доклад с места.",
		"pos": Vector2(0.13, 0.21),
		"color": Color(0.20, 0.42, 0.30),
		"key": false,
	},
	{
		"id": "bank_severny",
		"name": "Банк «Северный»",
		"address": "SEVERNAYA 2",
		"card_address": "Address: SEVERNAYA 2",
		"note": "Отделение",
		"action": "[ Отправить группу захвата ]",
		"action_result": "Группа захвата направлена в Банк «Северный».\nОжидайте доклад с места.",
		"pos": Vector2(0.49, 0.42),
		"color": Color(0.28, 0.34, 0.44),
		"key": false,
	},
	{
		"id": "market",
		"name": "Рынок",
		"address": "RYNOCHNAYA 1",
		"card_address": "Address: RYNOCHNAYA 1",
		"note": "—",
		"action": "[ Отправить группу захвата ]",
		"action_result": "Группа захвата направлена на Рынок.\nОжидайте доклад с места.",
		"pos": Vector2(0.45, 0.57),
		"color": Color(0.28, 0.34, 0.44),
		"key": false,
	},
	{
		"id": "park_rechnoy",
		"name": "Парк «Речной»",
		"address": "RECHNAYA NAB. 5",
		"card_address": "Address: RECHNAYA NAB. 5",
		"note": "Прогулки",
		"action": "[ Отправить группу захвата ]",
		"action_result": "Группа захвата направлена в Парк «Речной».\nОжидайте доклад с места.",
		"pos": Vector2(0.86, 0.27),
		"color": Color(0.20, 0.42, 0.30),
		"key": false,
	},
	{
		"id": "dacha_old",
		"name": "Дача (старая)",
		"address": "DACHA KOOP RASSVET 14",
		"card_address": "Address: DACHA KOOP RASSVET 14",
		"note": "Не езжу",
		"action": "[ Отправить группу захвата ]",
		"action_result": "Группа захвата направлена на Дачу (RASSVET 14).\nОжидайте доклад с места.",
		"pos": Vector2(0.08, 0.66),
		"color": Color(0.32, 0.32, 0.32),
		"key": false,
	},
]

var _font: Font
var _map_texture: Texture2D = null
var _marker_buttons: Array[Button] = []
var _hovered_marker: int = -1
var _search_query: String = ""
var _show_transport_layer: bool = false

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

func set_search_filter(query: String) -> void:
	_search_query = query.strip_edges().to_lower()
	queue_redraw()

func set_transport_layer(enabled: bool) -> void:
	_show_transport_layer = enabled
	queue_redraw()

func is_transport_layer() -> bool:
	return _show_transport_layer

func _matches_search(marker: Dictionary) -> bool:
	if _search_query.is_empty():
		return true
	return str(marker["name"]).to_lower().contains(_search_query) or str(marker["address"]).to_lower().contains(_search_query)

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
		var button := _marker_buttons[index]
		button.position = point - Vector2(12, 12)
		button.size = Vector2(24, 24)

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

	# Лёгкая координатная сетка (стиль ГИС 2000-х).
	for x in range(0, int(w), 48):
		draw_line(Vector2(x, 0), Vector2(x, h), Color(0, 0, 0, 0.055), 1.0)
	for y in range(0, int(h), 48):
		draw_line(Vector2(0, y), Vector2(w, y), Color(0, 0, 0, 0.055), 1.0)

	# Слой «Транспорт»: маршрут автобуса № 14.
	if _show_transport_layer:
		var route := PackedVector2Array([
			Vector2(w * 0.14, h * 0.46),
			Vector2(w * 0.21, h * 0.35),
			Vector2(w * 0.27, h * 0.48),
			Vector2(w * 0.45, h * 0.57),
			Vector2(w * 0.49, h * 0.42),
			Vector2(w * 0.72, h * 0.20),
		])
		draw_polyline(route, Color(0.05, 0.25, 0.72, 0.85), 3.0)
		_draw_caption_tag(Vector2(w * 0.29, h * 0.53), "АВТ. № 14")

	# Подписи районов.
	_draw_caption_tag(Vector2(w * 0.58, h * 0.90), "СЕВЕРНАЯ ПРОМЗОНА")
	_draw_caption_tag(Vector2(w * 0.86, h * 0.42), "р. Тёмная")

	# Сначала рисуем все обычные точки.
	for index in range(MARKERS.size()):
		if index != _hovered_marker:
			_draw_marker(MARKERS[index], index, false)
	# Наведённую точку и её бирку рисуем поверх всех.
	if _hovered_marker >= 0 and _hovered_marker < MARKERS.size():
		_draw_marker(MARKERS[_hovered_marker], _hovered_marker, true)

func _draw_marker(marker: Dictionary, _index: int, hovered: bool) -> void:
	var pos: Vector2 = Vector2(roundf(size.x * marker["pos"].x), roundf(size.y * marker["pos"].y))
	var matched := _matches_search(marker)
	var alpha := 1.0 if matched else 0.28
	var color: Color = marker["color"]
	color.a = alpha

	if hovered or (not _search_query.is_empty() and matched):
		draw_rect(Rect2(pos - Vector2(8, 8), Vector2(16, 16)), Color(1.0, 0.95, 0.55, 0.72))
		draw_rect(Rect2(pos - Vector2(8, 8), Vector2(16, 16)), Color(0.0, 0.0, 0.5, 1.0), false, 1.0)

	# Строгая квадратная ретро-метка 90-х.
	draw_line(pos + Vector2(0, 5), pos + Vector2(0, 11), Color(0, 0, 0, alpha), 2.0)
	draw_rect(Rect2(pos - Vector2(5, 5), Vector2(10, 10)), color)
	draw_rect(Rect2(pos - Vector2(5, 5), Vector2(10, 10)), Color(0, 0, 0, alpha), false, 1.0)
	draw_rect(Rect2(pos - Vector2(2, 2), Vector2(4, 4)), Color(1, 1, 1, alpha))

	# Чтобы 18 подписей не слипались, всегда рисуем полные бирки при наведении/поиске,
	# а в обычном режиме — компактную бирку для всех видимых точек.
	if not matched:
		return
	var label: String = marker["name"]
	var font_size := 10 if hovered else 9
	var text_size := _font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var flip_left := pos.x + 9.0 + text_size.x + 6.0 > size.x - 4.0
	var label_x := (pos.x - text_size.x - 11.0) if flip_left else (pos.x + 9.0)
	var label_pos := Vector2(roundf(label_x), roundf(pos.y - 5.0))
	var rect := Rect2(label_pos - Vector2(2, 10), Vector2(text_size.x + 5, 13))
	draw_rect(rect, Color(1, 1, 0.86, 1.0) if hovered else Color(0.96, 0.96, 0.92, 0.86))
	draw_rect(rect, Color(0.0, 0.0, 0.5, 1.0) if hovered else Color(0.2, 0.2, 0.2, 0.7), false, 1.0)
	draw_string(_font, label_pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.05, 0.05, 0.05, 1.0))

func _draw_caption_tag(pos: Vector2, text: String) -> void:
	var font_size := 9
	var ts := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var rect := Rect2(pos - Vector2(3, 10), Vector2(ts.x + 6, 13))
	draw_rect(rect, Color(0.95, 0.93, 0.86, 0.72))
	draw_string(_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.22, 0.20, 0.16, 0.95))
