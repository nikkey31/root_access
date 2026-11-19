extends Node

## Тестовый набор для Issue #16: Экраны концовок, кризисный финал и динамическая VFS.

var _failures: Array[String] = []

func _ready() -> void:
	await get_tree().process_frame
	print("[TEST #16] Старт тестирования кризисного финала и концовок...")
	
	var desktop: Desktop = load("res://scenes/desktop/Desktop.tscn").instantiate()
	get_tree().root.add_child(desktop)
	await get_tree().process_frame
	await get_tree().process_frame
	
	var ending_screen: Control = desktop.ending_screen
	_check(ending_screen != null, "Узел EndingScreen присутствует на рабочем столе")
	_check(not ending_screen.visible, "До финала экран концовок скрыт")
	
	# 1. Проверка Концовки 1 (Спасение)
	GameState.trigger_ending(GameState.Ending.SALVATION, {"point": "Склад № 3"})
	await get_tree().process_frame
	_check(ending_screen.visible, "Концовка 1 делает EndingScreen видимым")
	_check(ending_screen.title_label.text.contains("ГЕРОЙ НОЧИ"), "Заголовок концовки 1: ГЕРОЙ НОЧИ")
	_check(ending_screen.badge_label.text.contains("ЗАЛОЖНИЦА СПАСЕНА"), "Бейдж концовки 1: ЗАЛОЖНИЦА СПАСЕНА")
	
	# 2. Проверка сброса состояния
	GameState.reset_state()
	_check(GameState.final_ending == GameState.Ending.NONE, "reset_state сбрасывает final_ending")
	
	# 3. Проверка Концовки 2 (Ложный след)
	GameState.trigger_ending(GameState.Ending.FALSE_TRAIL, {"point": "Бокс № 6752"})
	await get_tree().process_frame
	_check(ending_screen.title_label.text.contains("РОКОВАЯ ОШИБКА"), "Заголовок концовки 2: РОКОВАЯ ОШИБКА")
	_check(ending_screen.badge_label.text.contains("ЛОЖНЫЙ СЛЕД"), "Бейдж концовки 2: ЛОЖНЫЙ СЛЕД")
	GameState.reset_state()
	
	# 4. Проверка Концовки 3 (Таймаут)
	GameState.trigger_ending(GameState.Ending.TIMEOUT, {"reason": "time_expired"})
	await get_tree().process_frame
	_check(ending_screen.title_label.text.contains("ОПОЗДАНИЕ"), "Заголовок концовки 3: ОПОЗДАНИЕ")
	GameState.reset_state()

	# 5. Проверка модального окна кризисных событий (CrisisDialog) и Концовки 4 (Юджин)
	var crisis: Control = desktop.crisis_dialog
	_check(crisis != null, "Узел CrisisDialog присутствует на рабочем столе")
	_check(not crisis.visible, "CrisisDialog скрыт до триггеров")

	# Триггер взятки ($100k)
	GameState.is_timer_active = true
	GameState.emit_signal("bribe_triggered")
	await get_tree().process_frame
	_check(crisis.visible, "Взятка открывает модальное окно CrisisDialog")
	_check(crisis.title_label.text.contains("Пейджер"), "Заголовок окна взятки: Пейджер")
	_check(crisis.btn_cancel.visible, "В окне взятки видна кнопка Отмена")

	# Нажатие Отмена в окне взятки
	crisis.btn_cancel.emit_signal("pressed")
	await get_tree().process_frame
	_check(not crisis.visible, "Нажатие Отмена закрывает окно взятки")
	_check(GameState.bribe_cancelled, "Отмена взятки устанавливает флаг GameState.bribe_cancelled")

	# Триггер фишинга с геометкой
	GameState.emit_signal("phishing_triggered")
	await get_tree().process_frame
	_check(crisis.visible, "Фишинг открывает модальное окно с запросом геометки")
	_check(crisis.title_label.text.contains("Служба безопасности"), "Заголовок окна фишинга: Служба безопасности")
	_check(crisis.btn_primary.visible, "В окне фишинга есть кнопка Продолжить")

	# Клик по Продолжить (тёмный UX-паттерн -> Концовка 4 с Юджином)
	crisis.btn_primary.emit_signal("pressed")
	await get_tree().process_frame
	_check(ending_screen.visible, "Клик по Продолжить активирует экран концовок")
	_check(ending_screen.title_label.text.contains("НЕЗВАНЫЙ ГОСТЬ"), "Заголовок концовки 4: НЕЗВАНЫЙ ГОСТЬ")
	_check(ending_screen._full_text.contains("Юджин Рейвенс"), "Текст концовки 4 содержит имя сообщника: Юджин Рейвенс")
	GameState.reset_state()
	
	# 5. Проверка динамической VFS и команды wipe_storage
	var vfs = get_node_or_null("/root/VFS")
	_check(vfs != null, "Синглтон VFS доступен")
	if vfs:
		_check(vfs.files_database.has("C:\\ROOT_ACCESS\\Работа"), "До очистки папка Работа существует")
		vfs.wipe_storage()
		_check(not vfs.files_database.has("C:\\ROOT_ACCESS\\Работа"), "После wipe_storage папка Работа удалена")
		_check(vfs.files_database.has("C:\\ROOT_ACCESS\\CORRUPTED_SECTOR_0.RAW"), "Создан поврежденный сектор CORRUPTED_SECTOR_0.RAW")
		
		# Проверка восстановления VFS
		vfs.reset_vfs()
		_check(vfs.files_database.has("C:\\ROOT_ACCESS\\Работа"), "reset_vfs восстановил оригинальную файловую систему")
	
	desktop.queue_free()
	
	if _failures.is_empty():
		print("ENDINGS & CRISIS (#16): PASS — все проверки концовок и динамической VFS пройдены.")
		get_tree().quit(0)
	else:
		print("ENDINGS & CRISIS (#16): FAIL:\n - " + "\n - ".join(_failures))
		get_tree().quit(1)

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
		print("  [FAIL] ", message)
	else:
		print("  [OK] ", message)
