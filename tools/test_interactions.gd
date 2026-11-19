extends Node

## Ручная интеграционная проверка реальных кликов и перетаскивания.
## Требует графического окна (не --headless).
##   godot --path . --scene res://tools/test_interactions.tscn

var _failures: Array[String] = []
var _desktop: Desktop

func _ready() -> void:
	await get_tree().process_frame
	var desktop: Desktop = load("res://scenes/desktop/Desktop.tscn").instantiate()
	get_tree().root.add_child(desktop)
	_desktop = desktop
	await get_tree().process_frame
	await get_tree().process_frame
	if desktop.thought_box:
		desktop.thought_box.clear_thoughts()
		desktop.thought_box.visible = false

	# 0. Курсор рисуется внутри линзы и совпадает с точкой интерфейса.
	var icon: DesktopIcon = desktop.get_node("DesktopSurface/Icons/ComputerIcon")
	var icon_point := icon.global_position + icon.size * 0.5
	var icon_screen := _desktop.crt_ui_to_screen(icon_point)
	Input.warp_mouse(icon_screen)
	var hover := InputEventMouseMotion.new()
	hover.position = icon_screen
	hover.global_position = icon_screen
	Input.parse_input_event(hover)
	await get_tree().process_frame
	_check(desktop.crt_cursor.visible, "CRT-курсор видим внутри линзы")
	_check(desktop.crt_cursor.position.distance_to(icon_point) < 2.0, "CRT-курсор совпадает с точкой интерфейса")
	_check(_desktop.crt_ui_to_screen(desktop.crt_cursor.position).distance_to(icon_screen) < 2.0, "CRT-курсор визуально совпадает с реальной мышью")

	# 1. Одиночный клик по иконке открывает окно.
	await _click(icon_point)
	await get_tree().process_frame
	_check(desktop._windows.size() == 1, "Одиночный клик по иконке открывает окно")
	if desktop._windows.is_empty():
		_finish()
		return
	var window: WindowFrame = desktop._windows[0]
	if desktop.thought_box:
		desktop.thought_box.clear_thoughts()
		desktop.thought_box.visible = false
	var start_pos := window.global_position

	# 2. Перетаскивание за заголовок.
	var grab := window.global_position + Vector2(180, 13)
	await _press(grab)
	await get_tree().process_frame
	var drag_target := grab + Vector2(90, 55)
	var drag_screen := _screen(drag_target)
	Input.warp_mouse(drag_screen)
	await get_tree().process_frame
	var motion := InputEventMouseMotion.new()
	motion.position = drag_screen
	motion.global_position = drag_screen
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(motion)
	await get_tree().process_frame
	await _release(drag_target)
	await get_tree().process_frame
	var moved := window.global_position - start_pos
	_check(moved.x > 60.0 and moved.y > 30.0, "Окно перетаскивается за заголовок (сдвиг %s)" % moved)

	# 3. Сворачивание и восстановление с панели задач.
	var minimize_point := window.btn_minimize.global_position + window.btn_minimize.size * 0.5
	await _click(minimize_point)
	await get_tree().process_frame
	_check(not window.visible, "Кнопка «Свернуть» скрывает окно")
	var task_button: Button = desktop._task_buttons.get(window)
	_check(task_button != null, "У свёрнутого окна остаётся кнопка на панели задач")
	if task_button:
		await _click(task_button.global_position + task_button.size * 0.5)
		await get_tree().process_frame
		_check(window.visible and window.is_active, "Клик по панели задач восстанавливает окно")

	# 4. Закрытие крестиком.
	var close_point := window.btn_close.global_position + window.btn_close.size * 0.5
	await _click(close_point)
	await get_tree().process_frame
	_check(desktop._windows.is_empty(), "Крестик закрывает окно")

	# 5. Кнопка «Пуск» и Escape.
	var start_button: Button = desktop.get_node("Taskbar/MainMargin/MainRow/StartButton")
	await _click(start_button.global_position + start_button.size * 0.5)
	await get_tree().process_frame
	_check(desktop.start_menu.visible and start_button.button_pressed, "Кнопка «Пуск» открывает меню")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	Input.parse_input_event(escape)
	await get_tree().process_frame
	_check(not desktop.start_menu.visible, "Escape закрывает меню «Пуск»")

	# 6. Кликабельная метка на карте под CRT-линзой.
	desktop.open_app("maps")
	await get_tree().process_frame
	var maps_window := desktop._find_window("maps")
	var maps_preview := maps_window.content_container.get_child(0) as AppPreview
	var maps := maps_preview.find_children("*", "MapPreview", true, false)
	var map := maps[0] as MapPreview
	var marker_button := map.get_child(3) as Button
	await _click(marker_button.global_position + marker_button.size * 0.5)
	await get_tree().process_frame
	var map_card := maps_preview.get("_map_info_card") as InfoCard
	_check(map_card.visible, "Клик по метке карты открывает карточку")
	_check(map_card.body_label.text.contains("LENINA 54"), "Карточка Мишель содержит LENINA 54")
	map_card.close()
	maps_window.close()
	await get_tree().process_frame

	# 7. Кнопка «Свойства / Подробнее» в Галерее.
	desktop.open_app("gallery")
	await get_tree().process_frame
	var gallery_window := desktop._find_window("gallery")
	var gallery_preview := gallery_window.content_container.get_child(0) as AppPreview
	gallery_preview.select_photo_by_filename("IMG_0488.JPG")
	await get_tree().process_frame
	var toolbar: Dictionary = gallery_preview.get("_toolbar_buttons")
	var properties_button := toolbar.get("Свойства / Подробнее") as Button
	await _click(properties_button.global_position + properties_button.size * 0.5)
	await get_tree().process_frame
	var photo_card := gallery_preview.get("_photo_info_card") as InfoCard
	_check(photo_card.visible, "Кнопка «Свойства / Подробнее» открывает карточку")
	_check(photo_card.body_label.text.contains("24.09.2009"), "Свойства фото показывают дату 24.09.2009")
	photo_card.close()

	# 8. Реальный зум колесом и перетаскивание фото под CRT.
	gallery_preview._open_photo_viewer()
	await get_tree().process_frame
	var viewer := gallery_preview.get("_photo_viewer_viewport") as Control
	var viewer_center := viewer.global_position + viewer.size * 0.5
	await _wheel(viewer_center, MOUSE_BUTTON_WHEEL_UP)
	await get_tree().process_frame
	_check(gallery_preview.get("_photo_zoom") > 1.0, "Колесо мыши увеличивает фото в просмотрщике")
	var pan_before: Vector2 = gallery_preview.get("_photo_pan")
	await _press(viewer_center)
	await _move(viewer_center, viewer_center + Vector2(42, 24))
	await _release(viewer_center + Vector2(42, 24))
	await get_tree().process_frame
	_check(gallery_preview.get("_photo_pan") != pan_before, "Увеличенное фото перетаскивается мышью")
	gallery_preview._close_photo_viewer()
	gallery_window.close()
	await get_tree().process_frame

	# 9. Браузер: реальный клик по «История» и по строке мессенджера.
	desktop.open_app("browser")
	await get_tree().process_frame
	var browser_window := desktop._find_window("browser")
	var browser = browser_window.content_container.get_child(0)
	await _click(browser.history_button.global_position + browser.history_button.size * 0.5)
	await get_tree().process_frame
	var messenger_row: Button = null
	for child in browser.history_rows.get_children():
		if child is Button and (child.text.to_lower().contains("рейвенс") or child.text.to_lower().contains("eugene") or child.text.to_lower().contains("мессенджер")):
			messenger_row = child
			break
	_check(messenger_row != null, "Строка мессенджера найдена в истории")
	if messenger_row:
		await _click(messenger_row.global_position + messenger_row.size * 0.5)
		await get_tree().process_frame
		_check(browser.current_view == "messenger", "Клик по истории мессенджера открывает чат с Юджином")
		_check(browser.messenger_banner != null and browser.messenger_banner.text.contains("30 дней"), "В чате видна плашка об удалённых сообщениях")
	browser_window.close()

	_finish()

func _screen(point: Vector2) -> Vector2:
	return _desktop.crt_ui_to_screen(point)

func _click(point: Vector2) -> void:
	await _press(point)
	await _release(point)

func _press(point: Vector2) -> void:
	var screen_point := _screen(point)
	Input.warp_mouse(screen_point)
	await get_tree().process_frame
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = screen_point
	event.global_position = screen_point
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(event)
	await get_tree().process_frame

func _move(from_point: Vector2, to_point: Vector2) -> void:
	var from_screen := _screen(from_point)
	var screen_point := _screen(to_point)
	Input.warp_mouse(screen_point)
	await get_tree().process_frame
	var event := InputEventMouseMotion.new()
	event.position = screen_point
	event.global_position = screen_point
	event.relative = screen_point - from_screen
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(event)
	await get_tree().process_frame

func _wheel(point: Vector2, button: int) -> void:
	var screen_point := _screen(point)
	Input.warp_mouse(screen_point)
	await get_tree().process_frame
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = true
	event.position = screen_point
	event.global_position = screen_point
	Input.parse_input_event(event)
	await get_tree().process_frame

func _release(point: Vector2) -> void:
	var screen_point := _screen(point)
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = false
	event.position = screen_point
	event.global_position = screen_point
	Input.parse_input_event(event)
	await get_tree().process_frame

func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		_failures.append(message)
		printerr("FAIL: ", message)

func _finish() -> void:
	if _failures.is_empty():
		print("INTERACTIONS: PASS")
	else:
		printerr("INTERACTIONS: FAIL — %d" % _failures.size())
	get_tree().quit(0 if _failures.is_empty() else 1)
