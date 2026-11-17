extends Node

## Headless smoke-тест каркаса рабочего стола (Issue #10).
## Запуск:
##   godot --headless --path . --scene res://tests/test_desktop_shell.tscn

var _failures: Array[String] = []

func _ready() -> void:
	await get_tree().process_frame
	var desktop: Desktop = load("res://scenes/desktop/Desktop.tscn").instantiate()
	get_tree().root.add_child(desktop)
	await get_tree().process_frame
	await get_tree().process_frame

	_check(desktop.get_node("DesktopSurface/Icons").get_child_count() == 6, "На рабочем столе 6 иконок")
	_check(desktop.get_node("Taskbar/MainMargin/MainRow/StartButton").text == "Пуск", "Кнопка «Пуск» на месте")
	_check(desktop.time_label.text == "02:15", "Часы показывают сюжетные 02:15")
	_check(desktop.date_label.text == "02.10.2009", "Дата показывает 02.10.2009")

	for app_id in ["computer", "terminal", "maps", "gallery", "notes", "recycle"]:
		desktop.open_app(app_id)
		await get_tree().process_frame
		var window := desktop._find_window(app_id)
		_check(window != null, "Открывается окно: %s" % app_id)
		if window:
			_check(window.get_child_count() > 0, "У окна %s есть контент" % app_id)
			_check(desktop._task_buttons.has(window), "У окна %s есть кнопка на панели задач" % app_id)

	var windows := desktop.get_node("DesktopSurface/WindowLayer").get_child_count()
	_check(windows == 6, "Одновременно открыты 6 окон (сейчас %d)" % windows)
	_check(desktop.get_node("Taskbar/MainMargin/MainRow/TaskButtons").get_child_count() == 6, "На панели задач 6 кнопок окон")

	# CRT: преобразование мыши должно быть взаимно обратным.
	_check(desktop.crt_is_visible(Vector2(640, 360)), "Центр CRT-экрана видим")
	_check(not desktop.crt_is_visible(Vector2(1, 1)), "Угол CRT-экрана скрыт линзой")
	for point in [Vector2(320, 240), Vector2(640, 360), Vector2(960, 500)]:
		var screen_point := desktop.crt_ui_to_screen(point)
		var back := desktop.crt_screen_to_ui(screen_point)
		_check(back.distance_to(point) < 1.0, "CRT-преобразование мыши обратимо для %s" % point)

	# Карты: кликабельные метки и карточки.
	var maps_window := desktop._find_window("maps")
	var maps_preview := maps_window.content_container.get_child(0) as AppPreview
	var maps := maps_preview.find_children("*", "MapPreview", true, false)
	_check(not maps.is_empty(), "В «Картах» есть MapPreview")
	if not maps.is_empty():
		var map := maps[0] as MapPreview
		var map_card := maps_preview.get("_map_info_card") as InfoCard
		map.marker_clicked.emit(MapPreview.MARKERS[3])
		await get_tree().process_frame
		_check(map_card.visible, "Клик по метке открывает карточку")
		_check(map_card.body_label.text.contains("LENINA 54"), "Карточка Мишель содержит LENINA 54")
		map_card.close()
		map.marker_clicked.emit(MapPreview.MARKERS[5])
		await get_tree().process_frame
		_check(map_card.action_button.visible, "У карточки Склада № 3 есть кнопка штурма")
		map_card.action_button.emit_signal("pressed")
		await get_tree().process_frame
		_check(map_card.body_label.text.contains("Группа захвата направлена"), "Кнопка штурма подтверждает отправку группы")
		map_card.close()

	# Галерея: активная кнопка «Свойства / Подробнее».
	var gallery_window := desktop._find_window("gallery")
	var gallery_preview := gallery_window.content_container.get_child(0) as AppPreview
	var toolbar: Dictionary = gallery_preview.get("_toolbar_buttons")
	var properties_button := toolbar.get("Свойства / Подробнее") as Button
	_check(properties_button != null and not properties_button.disabled, "Кнопка «Свойства / Подробнее» активна")
	if properties_button:
		properties_button.emit_signal("pressed")
		await get_tree().process_frame
		var photo_card := gallery_preview.get("_photo_info_card") as InfoCard
		_check(photo_card.visible, "«Свойства / Подробнее» открывает карточку")
		_check(photo_card.body_label.text.contains("24.09.2009"), "В свойствах фото дата съёмки 24.09.2009")
		photo_card.close()

	var first: WindowFrame = desktop.get_node("DesktopSurface/WindowLayer").get_child(0)
	var old_position := first.position
	first.position = Vector2(-2000, -2000)
	first.call("_clamp_to_parent")
	_check(first.position.x > -1000, "Окно нельзя полностью утащить за экран")
	first.position = Vector2(first.position.x, 5000)
	first.call("_clamp_to_parent")
	_check(first.position.y + first.size.y <= desktop.window_layer.size.y + 0.5, "Окно не заходит на панель задач")
	first.position = old_position

	desktop.advance_story_time(85)
	_check(desktop.time_label.text == "03:40", "Сюжетное время перематывается на 03:40")

	var last: WindowFrame = desktop.get_node("DesktopSurface/WindowLayer").get_child(5)
	last.minimize()
	await get_tree().process_frame
	_check(not last.visible, "Окно сворачивается в панель задач")
	last.restore()
	desktop._bring_to_front(last)
	await get_tree().process_frame
	_check(last.is_active, "Свёрнутое окно восстанавливается и становится активным")

	last.close()
	await get_tree().process_frame
	_check(desktop.get_node("DesktopSurface/WindowLayer").get_child_count() == 5, "Окно закрывается крестиком")

	desktop.get_node("Taskbar/MainMargin/MainRow/StartButton").emit_signal("pressed")
	await get_tree().process_frame
	_check(desktop.start_menu.visible, "Меню «Пуск» открывается")
	desktop.start_search.text = "термин"
	desktop.start_search.text_changed.emit("термин")
	await get_tree().process_frame
	var visible_items := 0
	for item in desktop.start_items.get_children():
		if item.visible:
			visible_items += 1
	_check(visible_items == 1, "Поиск в «Пуске» фильтрует приложения")
	desktop._close_start_menu()

	desktop._on_tray_pressed("battery")
	await get_tree().process_frame
	_check(desktop.tray_popup.visible, "Трей показывает информационную панель")
	desktop._hide_tray_popup()

	if _failures.is_empty():
		print("DESKTOP SHELL: PASS — все проверки Issue #10 пройдены.")
	else:
		for failure in _failures:
			printerr("FAIL: " + failure)
		printerr("DESKTOP SHELL: FAIL — %d проверок." % _failures.size())
	get_tree().quit(0 if _failures.is_empty() else 1)

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
