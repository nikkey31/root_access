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
