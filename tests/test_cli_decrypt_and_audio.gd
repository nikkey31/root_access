extends Node

## Сквозной интеграционный автотест цепочки:
## cd -> pwd -> decrypt location.enc -k LENINA 54 -> появление и воспроизведение record.wav
## Задача Жени (Feature/cli-decrypt-and-audio)
##
## Запуск:
##   godot --headless --path . --scene res://tests/test_cli_decrypt_and_audio.tscn

var _failures: Array[String] = []

func _ready() -> void:
	get_tree().root.set_meta("is_test", true)
	print("==================================================================")
	print("ЗАПУСК СКВОЗНОГО АВТОТЕСТА ДЕШИФРОВКИ И АУДИОПЛЕЕРА (ЖЕНЯ)")
	print("==================================================================")
	await get_tree().process_frame
	
	if GameState:
		GameState.reset_state()
	
	await _test_terminal_navigation_and_pwd()
	await _test_password_forgiveness()
	await _test_explorer_encrypted_file_hint()
	await _test_terminal_decrypt_with_progress_bar()
	await _test_explorer_record_wav_and_act3()
	
	print("==================================================================")
	if _failures.is_empty():
		print("ВСЕ ПРОВЕРКИ СКВОЗНОЙ ЦЕПОЧКИ ПРОЙДЕНЫ УСПЕШНО! (0 ошибок)")
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

func _test_terminal_navigation_and_pwd() -> void:
	print("\n--- ЭТАП 1: Терминал — навигация cd и pwd по VFS ---")
	var terminal_scene = load("res://scenes/apps/Terminal.tscn")
	_check(terminal_scene != null, "Сцена scenes/apps/Terminal.tscn загружена")
	
	var terminal: TerminalApp = terminal_scene.instantiate()
	add_child(terminal)
	await get_tree().process_frame
	
	# Проверка pwd в корневом каталоге
	terminal._process_command("pwd")
	var text_pwd = terminal.output_label.get_parsed_text()
	_check(text_pwd.contains("C:\\ROOT_ACCESS"), "Команда pwd возвращает C:\\ROOT_ACCESS")
	
	# Попытка перехода в защищённую папку Работа до ввода пароля
	_check(GameState.is_work_folder_unlocked == false, "Папка «Работа» изначально заблокирована")
	terminal._process_command("cd Работа")
	var text_blocked = terminal.output_label.get_parsed_text()
	_check(text_blocked.contains("Доступ запрещён") or text_blocked.contains("защищён"), "Команда cd Работа отклоняет доступ до авторизации паролем")
	_check(terminal.vfs.get_current_directory() == "C:\\ROOT_ACCESS", "Текущий каталог остался C:\\ROOT_ACCESS")
	
	# Переход в незащищенную папку Документы
	terminal._process_command("cd Документы")
	_check(terminal.vfs.get_current_directory() == "C:\\ROOT_ACCESS\\Документы", "Команда cd Документы успешно переходит в подпапку")
	_check(terminal.prompt_label.text.contains("Документы>"), "Строка prompt обновилась на Документы> ")
	
	# Возврат наверх по cd ..
	terminal._process_command("cd ..")
	_check(terminal.vfs.get_current_directory() == "C:\\ROOT_ACCESS", "Команда cd .. возвращает в родительский каталог C:\\ROOT_ACCESS")
	
	terminal.queue_free()
	await get_tree().process_frame

func _test_password_forgiveness() -> void:
	print("\n--- ЭТАП 2: Валидация пароля папки «Работа» (прощающие форматы) ---")
	GameState.is_work_folder_unlocked = false
	
	# Проверяем форматы
	_check(GameState.verify_work_password("wrong_pass") == false, "Неверный пароль отклоняется")
	_check(GameState.is_work_folder_unlocked == false, "Флаг разблокировки остаётся false")
	
	_check(GameState.verify_work_password("24.09") == true, "Формат 24.09 успешно принимается")
	GameState.is_work_folder_unlocked = false
	
	_check(GameState.verify_work_password("24/09") == true, "Формат 24/09 успешно принимается")
	GameState.is_work_folder_unlocked = false
	
	_check(GameState.verify_work_password("24092009") == true, "Формат 24092009 успешно принимается")
	GameState.is_work_folder_unlocked = false
	
	_check(GameState.verify_work_password("2409") == true, "Каноничный пароль 2409 успешно принимается")
	_check(GameState.is_work_folder_unlocked == true, "Папка «Работа» теперь разблокирована")

func _test_explorer_encrypted_file_hint() -> void:
	print("\n--- ЭТАП 3: Проводник — открытие location.enc с подсказкой о Терминале ---")
	var explorer_scene = load("res://scenes/apps/Explorer.tscn")
	_check(explorer_scene != null, "Сцена scenes/apps/Explorer.tscn загружена")
	
	var explorer: ExplorerApp = explorer_scene.instantiate()
	add_child(explorer)
	await get_tree().process_frame
	
	explorer.navigate_to("C:\\ROOT_ACCESS\\Работа")
	_check(explorer.current_path == "C:\\ROOT_ACCESS\\Работа", "Проводник открыл папку Работа")
	
	# Поиск location.enc
	var enc_item: Dictionary = {}
	for child in explorer.file_list_container.get_children():
		var data = child.get_meta("item_data", {})
		if data.get("name") == "location.enc":
			enc_item = data
			break
	
	_check(not enc_item.is_empty(), "В папке Работа найден файл location.enc")
	_check(enc_item.get("is_encrypted", false) == true, "Файл location.enc помечен как зашифрованный")
	
	# Клик по location.enc
	explorer._activate_item(enc_item)
	_check(explorer.preview_overlay.visible == true, "Открылось модальное окно ошибки чтения файла")
	
	var preview_content = explorer.preview_text.text
	_check(preview_content.contains("НЕВОЗМОЖНО ОТКРЫТЬ ФАЙЛ") or preview_content.contains("0x7F454C46"), "Текст ошибки указывает на невозможность текстового чтения")
	_check(preview_content.contains("decrypt location.enc -k") and preview_content.contains("инструкция_шифрование.txt"), "Текст содержит подсказку к дешифровке через Терминал и отсылку к инструкции")
	
	explorer.preview_overlay.visible = false
	explorer.queue_free()
	await get_tree().process_frame

func _test_terminal_decrypt_with_progress_bar() -> void:
	print("\n--- ЭТАП 4: Терминал — дешифровка с анимацией прогресс-бара и перемоткой часов ---")
	var terminal_scene = load("res://scenes/apps/Terminal.tscn")
	var terminal: TerminalApp = terminal_scene.instantiate()
	add_child(terminal)
	await get_tree().process_frame
	
	# Переход в папку Работа
	terminal._process_command("cd Работа")
	_check(terminal.vfs.get_current_directory() == "C:\\ROOT_ACCESS\\Работа", "Успешный вход в папку Работа через Терминал")
	
	_check(GameState.is_location_decrypted == false, "Флаг is_location_decrypted изначально false")
	
	var jump_data = {"received": false, "hour": 0, "minute": 0}
	var on_time_jump = func(h: int, m: int, _anim: bool):
		jump_data["received"] = true
		jump_data["hour"] = h
		jump_data["minute"] = m
	GameState.story_time_jump_requested.connect(on_time_jump)
	
	# Тестируем ввод команды с ключом с пробелом и разным регистром: 'LENINA 54'
	await terminal._cmd_decrypt(["location.enc", "-k", "LENINA", "54"])
	
	GameState.story_time_jump_requested.disconnect(on_time_jump)
	
	var out = terminal.output_label.get_parsed_text()
	_check(out.contains("[████████████████] 100% COMPLETE"), "Отображен прогресс-бар дешифрования [████████████████] 100% COMPLETE")
	_check(out.contains("record.wav"), "В выводе терминала указано имя разблокированного файла record.wav")
	_check(GameState.is_location_decrypted == true, "Флаг GameState.is_location_decrypted установлен в true")
	_check(jump_data["received"] and jump_data["hour"] == 3 and jump_data["minute"] == 40, "Сигнал сюжетного времени отправлен на часах с перемоткой на 03:40")
	
	# Проверка VFS: record.wav появился в файловой системе
	var vfs_items = terminal.vfs.list_dir("C:\\ROOT_ACCESS\\Работа")
	var has_record_wav = false
	for it in vfs_items:
		if it["name"] == "record.wav":
			has_record_wav = true
			break
	_check(has_record_wav, "Файл record.wav появился в VFS в папке Работа")
	
	terminal.queue_free()
	await get_tree().process_frame

func _test_explorer_record_wav_and_act3() -> void:
	print("\n--- ЭТАП 5: Проводник — появление record.wav, плеер и старт Акта 3 ---")
	var explorer_scene = load("res://scenes/apps/Explorer.tscn")
	var explorer: ExplorerApp = explorer_scene.instantiate()
	add_child(explorer)
	await get_tree().process_frame
	
	explorer.navigate_to("C:\\ROOT_ACCESS\\Работа")
	
	# Проверяем наличие record.wav в списке отображения Проводника
	var record_item: Dictionary = {}
	for child in explorer.file_list_container.get_children():
		var data = child.get_meta("item_data", {})
		if data.get("name") == "record.wav":
			record_item = data
			break
	
	_check(not record_item.is_empty(), "Файл record.wav отображается в списке файлов Проводника в папке Работа")
	
	# Запуск воспроизведения record.wav
	_check(GameState.is_audio_listened == false, "Флаг is_audio_listened изначально false")
	_check(GameState.is_timer_active == false, "Финальный таймер изначально не запущен")
	
	explorer._activate_item(record_item)
	_check(explorer.audio_overlay.visible == true, "Модальное окно аудиоплеера открылось")
	_check(explorer._is_audio_playing == true, "Воспроизведение аудио запущено")
	
	var subs = explorer.audio_subtitles.text
	_check(subs.contains("Саймон") and subs.contains("6-7-5-2"), "Субтитры содержат реплику Саймона про грузовик 6-7-5-2")
	
	# Симулируем окончание аудиозаписи
	explorer.simulate_audio_finish()
	_check(GameState.is_audio_listened == true, "Флаг GameState.is_audio_listened установлен в true")
	_check(GameState.is_timer_active == true, "Запущен финальный таймер (Акт 3 начался)")
	_check(is_equal_approx(GameState.time_remaining, 60.0), "Таймер установлен на ровно 60 секунд")
	
	explorer.queue_free()
	await get_tree().process_frame
