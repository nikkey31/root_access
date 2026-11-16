extends Node

## Комплексный тест логики Заметок, Проводника и Корзины (Задача Жени)
## Запуск:
##   godot --headless --path . --scene res://tests/test_notes_and_explorer.tscn

var _failures: Array[String] = []

func _ready() -> void:
	print("====================================================")
	print("ЗАПУСК ТЕСТИРОВАНИЯ ЗАМЕТОК, ПРОВОДНИКА И КОРЗИНЫ")
	print("====================================================")
	await get_tree().process_frame
	
	await _test_notes_app()
	await _test_explorer_app()
	await _test_recycle_bin()
	await _test_desktop_integration()
	
	print("====================================================")
	if _failures.is_empty():
		print("ВСЕ ПРОВЕРКИ ПРОЙДЕНЫ УСПЕШНО! (0 ошибок)")
		get_tree().quit(0)
	else:
		for f in _failures:
			printerr("ОШИБКА: " + f)
		printerr("ТЕСТИРОВАНИЕ ЗАВЕРШЕНО С ОШИБКАМИ: %d" % _failures.size())
		get_tree().quit(1)

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
		printerr("[FAIL] " + message)
	else:
		print("[OK] " + message)

func _test_notes_app() -> void:
	print("\n--- ТЕСТ 1: Приложение «Заметки» (NotesApp) ---")
	var notes_scene = load("res://scenes/apps/Notes.tscn")
	_check(notes_scene != null, "Сцена scenes/apps/Notes.tscn загружается")
	
	var notes: NotesApp = notes_scene.instantiate()
	add_child(notes)
	await get_tree().process_frame
	
	_check(GameState.is_notes_opened == true, "Флаг GameState.is_notes_opened установлен в true")
	_check(notes.notes_list != null, "Список заметок (ItemList) присутствует")
	_check(notes.notes_list.item_count == 4, "В списке ровно 4 заметки")
	
	var required_notes = [
		"пароли.txt",
		"мишель_слежка.txt",
		"инструкция_шифрование.txt",
		"чек_заправка.txt"
	]
	for req in required_notes:
		var found = false
		for i in range(notes.notes_list.item_count):
			if notes.notes_list.get_item_text(i) == req:
				found = true
				break
		_check(found, "В списке присутствует файл: %s" % req)
	
	# Проверка чтения пароли.txt
	notes.open_note("пароли.txt")
	var text_passwords = notes.text_display.get_parsed_text()
	_check(text_passwords.contains("др Юджина") and text_passwords.contains("ДДММ"), "Содержимое пароли.txt прочитано из VFS")
	
	# Проверка чтения мишель_слежка.txt
	notes.open_note("мишель_слежка.txt")
	var text_michelle = notes.text_display.get_parsed_text()
	_check(text_michelle.contains("LENINA 54") and text_michelle.contains("Мишель Юхнова"), "Содержимое мишель_слежка.txt прочитано из VFS")
	
	# Проверка чтения инструкция_шифрование.txt
	notes.open_note("инструкция_шифрование.txt")
	var text_encrypt = notes.text_display.get_parsed_text()
	_check(text_encrypt.contains("decrypt") and text_encrypt.contains("Ключ шифра"), "Содержимое инструкция_шифрование.txt прочитано из VFS")
	
	# Проверка чтения чек_заправка.txt
	notes.open_note("чек_заправка.txt")
	var text_gas = notes.text_display.get_parsed_text()
	_check(text_gas.contains("АЗС «Северная»") and text_gas.contains("Склад № 3"), "Содержимое чек_заправка.txt прочитано из VFS (упоминает Склад № 3)")
	
	notes.queue_free()
	await get_tree().process_frame

func _test_explorer_app() -> void:
	print("\n--- ТЕСТ 2: Интерактивный Проводник («Мой компьютер») и пароль папки «Работа» ---")
	var explorer_scene = load("res://scenes/apps/Explorer.tscn")
	_check(explorer_scene != null, "Сцена scenes/apps/Explorer.tscn загружается")
	
	var explorer: ExplorerApp = explorer_scene.instantiate()
	explorer.mode = "computer"
	add_child(explorer)
	await get_tree().process_frame
	
	_check(explorer.current_path == "C:\\ROOT_ACCESS", "Начальный каталог: C:\\ROOT_ACCESS")
	
	# Проверка перехода в Документы
	explorer.navigate_to("C:\\ROOT_ACCESS\\Документы")
	await get_tree().process_frame
	_check(explorer.current_path == "C:\\ROOT_ACCESS\\Документы", "Успешный переход в папку Документы")
	_check(explorer.file_list_container.get_child_count() > 0, "Папка Документы содержит файлы")
	
	# Проверка попытки входа в защищённую папку Работа с неверным паролем
	GameState.is_work_folder_unlocked = false
	explorer.navigate_to("C:\\ROOT_ACCESS\\Работа")
	await get_tree().process_frame
	_check(explorer.password_overlay.visible == true, "Клик по папке Работа вызывает модальное окно пароля")
	_check(explorer.current_path != "C:\\ROOT_ACCESS\\Работа", "Вход в папку Работа не произошёл до ввода пароля")
	
	# Неверный пароль
	explorer.password_input.text = "0000"
	explorer._on_password_ok_pressed()
	await get_tree().process_frame
	_check(explorer.password_overlay.visible == true, "Окно пароля остаётся при неверном пароле")
	_check(GameState.is_work_folder_unlocked == false, "Флаг GameState.is_work_folder_unlocked остаётся false")
	
	# Правильный пароль: 2409
	explorer.password_input.text = "2409"
	explorer._on_password_ok_pressed()
	await get_tree().process_frame
	_check(explorer.password_overlay.visible == false, "Окно пароля закрывается после верного пароля 2409")
	_check(GameState.is_work_folder_unlocked == true, "Флаг GameState.is_work_folder_unlocked установлен в true")
	_check(explorer.current_path == "C:\\ROOT_ACCESS\\Работа", "Проводник открыл папку Работа")
	
	# Проверка содержимого папки Работа
	var found_location_enc = false
	for child in explorer.file_list_container.get_children():
		var data = child.get_meta("item_data", {})
		if data.get("name", "") == "location.enc":
			found_location_enc = true
			break
	_check(found_location_enc, "В папке Работа находится зашифрованный файл location.enc")
	
	explorer.queue_free()
	await get_tree().process_frame

func _test_recycle_bin() -> void:
	print("\n--- ТЕСТ 3: Корзина и удалённая накладная с фурой 6752 ---")
	var explorer_scene = load("res://scenes/apps/Explorer.tscn")
	var recycle_app: ExplorerApp = explorer_scene.instantiate()
	recycle_app.mode = "recycle"
	add_child(recycle_app)
	await get_tree().process_frame
	
	_check(recycle_app.current_path == "C:\\ROOT_ACCESS\\Корзина", "Корзина открывает C:\\ROOT_ACCESS\\Корзина")
	_check(GameState.is_trash_inspected == true, "Флаг GameState.is_trash_inspected установлен в true")
	
	# Ищем накладная_доставка.txt
	var invoice_row: Control = null
	for child in recycle_app.file_list_container.get_children():
		var data = child.get_meta("item_data", {})
		if data.get("name", "") == "накладная_доставка.txt":
			invoice_row = child
			break
	_check(invoice_row != null, "В Корзине найден файл накладная_доставка.txt")
	
	# Открываем накладную
	var data = invoice_row.get_meta("item_data")
	recycle_app._activate_item(data)
	await get_tree().process_frame
	
	_check(recycle_app.preview_overlay.visible == true, "Открылось модальное окно просмотра накладной")
	var preview_content = recycle_app.preview_text.get_parsed_text()
	_check(preview_content.contains("6752"), "Накладная содержит бортовой номер фуры 6752")
	_check(preview_content.contains("Склад № 3"), "Накладная указывает пункт назначения: Склад № 3")
	_check(preview_content.contains("Рейвенс"), "Накладная указывает арендатора: Рейвенс")
	
	recycle_app.queue_free()
	await get_tree().process_frame

func _test_desktop_integration() -> void:
	print("\n--- ТЕСТ 4: Интеграция с рабочим столом (Desktop.tscn) ---")
	var desktop_scene = load("res://scenes/desktop/Desktop.tscn")
	var desktop: Desktop = desktop_scene.instantiate()
	add_child(desktop)
	await get_tree().process_frame
	await get_tree().process_frame
	
	# 1. Открываем Заметки
	desktop.open_app("notes")
	await get_tree().process_frame
	var notes_win = desktop._find_window("notes")
	_check(notes_win != null, "Окно Заметок открыто на рабочем столе")
	_check(notes_win.content_container.get_child(0) is NotesApp, "В окно Заметок встроен настоящий NotesApp")
	
	# 2. Открываем Мой компьютер
	desktop.open_app("computer")
	await get_tree().process_frame
	var comp_win = desktop._find_window("computer")
	_check(comp_win != null, "Окно «Мой компьютер» открыто на рабочем столе")
	_check(comp_win.content_container.get_child(0) is ExplorerApp, "В окно «Мой компьютер» встроен настоящий ExplorerApp")
	
	# 3. Открываем Корзину
	desktop.open_app("recycle")
	await get_tree().process_frame
	var rec_win = desktop._find_window("recycle")
	_check(rec_win != null, "Окно Корзины открыто на рабочем столе")
	_check(rec_win.content_container.get_child(0) is ExplorerApp, "В окно Корзины встроен настоящий ExplorerApp")
	var rec_app = rec_win.content_container.get_child(0) as ExplorerApp
	_check(rec_app.current_path.ends_with("Корзина"), "Корзина открылась в каталоге Корзины")
	
	desktop.queue_free()
	await get_tree().process_frame
