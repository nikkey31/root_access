extends Node

## Ручная интеграционная проверка реальных кликов и перетаскивания.
## Требует графического окна (не --headless).
##   godot --path . --scene res://tools/test_interactions.tscn

var _failures: Array[String] = []

func _ready() -> void:
	await get_tree().process_frame
	var desktop: Desktop = load("res://scenes/desktop/Desktop.tscn").instantiate()
	get_tree().root.add_child(desktop)
	await get_tree().process_frame
	await get_tree().process_frame

	# 1. Одиночный клик по иконке открывает окно.
	var icon: DesktopIcon = desktop.get_node("DesktopSurface/Icons/ComputerIcon")
	var icon_point := icon.global_position + icon.size * 0.5
	await _click(icon_point)
	await get_tree().process_frame
	_check(desktop._windows.size() == 1, "Одиночный клик по иконке открывает окно")
	if desktop._windows.is_empty():
		_finish()
		return
	var window: WindowFrame = desktop._windows[0]
	var start_pos := window.global_position

	# 2. Перетаскивание за заголовок.
	var grab := window.global_position + Vector2(180, 13)
	await _press(grab)
	await get_tree().process_frame
	Input.warp_mouse(grab + Vector2(90, 55))
	await get_tree().process_frame
	var motion := InputEventMouseMotion.new()
	motion.position = grab + Vector2(90, 55)
	motion.global_position = grab + Vector2(90, 55)
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(motion)
	await get_tree().process_frame
	await _release(grab + Vector2(90, 55))
	await get_tree().process_frame
	var moved := window.global_position - start_pos
	_check(moved.x > 60.0 and moved.y > 30.0, "Окно перетаскивается за заголовок (сдвиг %s)" % moved)

	# 3. Сворачивание и восстановление с панели задач.
	var minimize_point := window.global_position + Vector2(window.size.x - 45, 13)
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
	var close_point := window.global_position + Vector2(window.size.x - 14, 13)
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

	_finish()

func _click(point: Vector2) -> void:
	await _press(point)
	await _release(point)

func _press(point: Vector2) -> void:
	Input.warp_mouse(point)
	await get_tree().process_frame
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = point
	event.global_position = point
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(event)
	await get_tree().process_frame

func _release(point: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = false
	event.position = point
	event.global_position = point
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
