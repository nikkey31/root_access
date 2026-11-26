extends Node

## Автотест Задачи 4-й пары (Женя / Vo1dReign):
##   1. Ретро-иконки игр и спрайты фигур/рыб/бойца (64x64 Win98/XP PNG)
##   2. Глобальный звуковой синглтон AudioManager и реальные .wav/.ogg сэмплы
##   3. Команды терминала: netstat, chkdsk и поддержка составных ключей в decrypt
##
## Запуск:
##   godot --headless --path . --scene res://tests/test_icons_audio_and_cli.tscn

var _failures: Array[String] = []

func _ready() -> void:
	get_tree().root.set_meta("is_test", true)
	print("==================================================================")
	print("ТЕСТИРОВАНИЕ: ИКОНКИ ИГР, AUDIOMANAGER И НОВЫЕ КОМАНДЫ CLI")
	print("==================================================================")
	await get_tree().process_frame

	if GameState:
		GameState.reset_state()
	if VFS:
		VFS.reset_vfs()

	await _test_game_icons_and_sprites()
	await _test_audio_manager()
	await _test_terminal_netstat_chkdsk_and_composite_decrypt()
	await _test_explorer_game_folder_icons()

	if GameState:
		GameState.reset_state()
	if VFS:
		VFS.reset_vfs()

	print("==================================================================")
	if _failures.is_empty():
		print("ВСЕ ПРОВЕРКИ ИКОНОК, AUDIOMANAGER И CLI ПРОЙДЕНЫ УСПЕШНО! (0 ошибок)")
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

func _test_game_icons_and_sprites() -> void:
	print("\n--- ЭТАП 1: Ретро-иконки игр (64x64) и спрайты ---")
	var main_icons := [
		"res://assets/icons/games_folder.png",
		"res://assets/icons/fishing.png",
		"res://assets/icons/chess.png",
		"res://assets/icons/shadow_fight_1.png",
	]
	for path in main_icons:
		var tex := load(path) as Texture2D
		_check(tex != null, "Загружена иконка: %s" % path)
		if tex:
			_check(tex.get_size() == Vector2(64, 64), "Иконка %s имеет размер 64x64" % path.get_file())

	var chess_pieces := ["king", "queen", "rook", "bishop", "knight", "pawn"]
	for color_name in ["white", "black"]:
		for piece in chess_pieces:
			var p := "res://assets/icons/games/chess/%s_%s.png" % [color_name, piece]
			var tex := load(p) as Texture2D
			_check(tex != null and tex.get_size() == Vector2(64, 64), "Спрайт шахмат 64x64: %s" % p.get_file())

	var fishing_sprites := ["fish_crucian", "fish_perch", "fish_pike", "fish_rare", "boot", "bobber", "hook"]
	for fs in fishing_sprites:
		var p := "res://assets/icons/games/fishing/%s.png" % fs
		var tex := load(p) as Texture2D
		_check(tex != null and tex.get_size() == Vector2(64, 64), "Спрайт рыбалки 64x64: %s" % p.get_file())

	var sf_sprites := ["fighter_idle", "fighter_punch", "fighter_kick", "fighter_block"]
	for sf in sf_sprites:
		var p := "res://assets/icons/games/shadow_fight/%s.png" % sf
		var tex := load(p) as Texture2D
		_check(tex != null and tex.get_size() == Vector2(64, 64), "Спрайт бойца 64x64: %s" % p.get_file())

func _test_audio_manager() -> void:
	print("\n--- ЭТАП 2: Глобальный синглтон AudioManager и сэмплы ---")
	var am := get_node_or_null("/root/AudioManager")
	_check(am != null, "Синглтон AudioManager подключён в /root/AudioManager")
	if am == null:
		return

	var required_sounds := [
		"key_click", "mouse_click", "win_open", "win_close", "win_error",
		"win_notify", "win_success", "crt_poweroff", "timer_pulse",
		"door_knock", "gunshot", "record_static", "rain", "crt_hum"
	]
	for snd in required_sounds:
		_check(am.is_stream_loaded(snd), "Аудиосэмпл загружен: %s" % snd)

	# Проверка громкости и mute
	am.set_master_volume(0.5)
	_check(am.get_volume_percent() == 50, "Громкость обновляется корректно (50%)")
	am.set_muted(true)
	_check(am.is_muted == true, "Режим Mute активируется")
	am.set_muted(false)
	am.set_master_volume(0.68)
	_check(am.get_volume_percent() == 68 and not am.is_muted, "Громкость возвращена к 68%")

	# Проверка фонового амбиента (дождь + гул ЭЛТ)
	am.start_ambient()
	_check(am.is_ambient_active, "Фоновый амбиент дождя и ЭЛТ активирован")
	am.stop_ambient()
	_check(not am.is_ambient_active, "Фоновый амбиент остановлен")

	# Проверка проигрывания ключевых событий
	am.play_key_click()
	_check(am.last_sfx == "key_click", "play_key_click регистрирует key_click")
	am.play_window_open()
	_check(am.last_sfx == "win_open", "play_window_open регистрирует win_open")
	am.play_error()
	_check(am.last_sfx == "win_error", "play_error регистрирует win_error")
	am.play_door_knock()
	_check(am.last_sfx == "door_knock", "play_door_knock регистрирует door_knock")
	am.play_gunshot()
	_check(am.last_sfx == "gunshot", "play_gunshot регистрирует gunshot")

	# Проверка реакции AudioManager на таймер и концовку 4
	am.sfx_history.clear()
	GameState.emit_signal("timer_started", 60.0)
	_check(am.sfx_history.has("timer_pulse"), "Старт таймера запускает timer_pulse")
	GameState.emit_signal("timer_updated", 14.4)
	_check(am.last_sfx == "timer_pulse", "Смена секунды таймера запускает пульс timer_pulse")
	GameState.trigger_ending(GameState.Ending.HORROR, {"reason": "test"})
	_check(am.sfx_history.has("crt_poweroff"), "Хоррор-концовка запускает звук отключения ЭЛТ")
	GameState.reset_state()

func _test_terminal_netstat_chkdsk_and_composite_decrypt() -> void:
	print("\n--- ЭТАП 3: Терминал — netstat, chkdsk и составной ключ decrypt ---")
	var terminal: TerminalApp = load("res://scenes/apps/Terminal.tscn").instantiate()
	add_child(terminal)
	await get_tree().process_frame

	var am := get_node_or_null("/root/AudioManager")

	# 1. netstat
	terminal._cmd_clear()
	terminal._process_command("netstat -an")
	var net_out := terminal.output_label.get_parsed_text()
	_check(net_out.contains("Host-982") and net_out.contains("ESTABLISHED"), "netstat показывает активное скрытое соединение злоумышленников (Host-982 / ESTABLISHED)")
	_check(net_out.contains("eugene_relay.dll") or net_out.contains("geo_telemetry"), "netstat отображает процессы злоумышленников")
	if am:
		_check(am.last_sfx == "win_notify", "netstat вызывает звуковое оповещение win_notify")

	# 2. chkdsk
	terminal._cmd_clear()
	await terminal._cmd_chkdsk(["C:"])
	var chk_out := terminal.output_label.get_parsed_text()
	_check(chk_out.contains("shadow_fight_1.exe") and chk_out.contains("BAD SECTORS"), "chkdsk обнаруживает битые сектора в shadow_fight_1.exe")
	_check(chk_out.contains("fishing.exe") and chk_out.contains("кэш"), "chkdsk даёт намёк на локальный кэш fishing.exe")
	if am:
		_check(am.last_sfx == "win_error", "chkdsk при обнаружении ошибок издаёт звук win_error")

	# 3. Каталог Игры в VFS
	terminal._process_command("cd Игры")
	_check(terminal.vfs.get_current_directory() == "C:\\ROOT_ACCESS\\Игры", "cd Игры переводит в папку игр")
	terminal._cmd_clear()
	terminal._process_command("ls")
	var games_ls := terminal.output_label.get_parsed_text()
	_check(games_ls.contains("fishing.exe") and games_ls.contains("chess.exe") and games_ls.contains("shadow_fight_1.exe"), "ls в Игры отображает все 3 ярлыка игр")
	terminal._process_command("cd ..")

	# 4. Поддержка составных ключей в decrypt
	VFS.files_database["C:\\ROOT_ACCESS\\vault_test.enc"] = {
		"type": "file",
		"is_encrypted": true,
		"key": "CARPKNIGHT99",
		"key_parts": ["CARP", "KNIGHT", "99"],
		"unlocked_file": "vault_cache.txt",
		"unlocked_content": "СЕКРЕТНЫЙ_КЛЮЧ_РАСКРЫТ"
	}
	VFS.files_database["C:\\ROOT_ACCESS"]["items"].append("vault_test.enc")

	# Неполный ключ -> отказ
	terminal._cmd_clear()
	await terminal._cmd_decrypt(["vault_test.enc", "-k", "CARP"])
	var partial_out := terminal.output_label.get_parsed_text()
	_check(partial_out.contains("часть составного ключа"), "Часть составного ключа корректно отклоняется с диагностикой")

	# Составной ключ через плюс: -k carp+knight-99
	terminal._cmd_clear()
	await terminal._cmd_decrypt(["vault_test.enc", "-k", "carp+knight-99"])
	var plus_out := terminal.output_label.get_parsed_text()
	_check(plus_out.contains("Собран составной ключ (3 комп.)") and plus_out.contains("[SUCCESS]"), "Составной ключ с разделителями (+, -) собирается и расшифровывает файл")

	# Составной ключ через несколько флагов -k и пробелы (обратный порядок файла)
	await terminal._cmd_decrypt(["-k", "CARP", "-k", "KNIGHT", "-k", "99", "vault_test.enc"])
	var read_unlocked := VFS.read_file("vault_cache.txt")
	_check(read_unlocked.get("success", false) and read_unlocked.get("content", "") == "СЕКРЕТНЫЙ_КЛЮЧ_РАСКРЫТ", "Разблокированный составным ключом файл читается через VFS")

	# Проверяем составной ключ на location.enc: decrypt -k LENINA -k 54 location.enc
	terminal._cmd_clear()
	await terminal._cmd_decrypt(["-k", "LENINA", "-k", "54", "location.enc"])
	_check(GameState.is_location_decrypted, "location.enc успешно дешифруется составной записью -k LENINA -k 54")

	# Клики клавиатуры в Терминале
	if am:
		am.sfx_history.clear()
		terminal._on_command_text_changed("netstat")
		_check(am.last_sfx == "key_click", "Ввод символов в Терминале воспроизводит звук клика клавиатуры")

	terminal.queue_free()
	await get_tree().process_frame

func _test_explorer_game_folder_icons() -> void:
	print("\n--- ЭТАП 4: Проводник — иконки папки «Игры» и ярлыков .exe ---")
	var explorer: ExplorerApp = load("res://scenes/apps/Explorer.tscn").instantiate()
	explorer.initial_path = "C:\\ROOT_ACCESS\\Игры"
	add_child(explorer)
	await get_tree().process_frame

	var expected_textures := {
		"fishing.exe": load("res://assets/icons/fishing.png"),
		"chess.exe": load("res://assets/icons/chess.png"),
		"shadow_fight_1.exe": load("res://assets/icons/shadow_fight_1.png"),
	}
	for fname in expected_textures.keys():
		var item_icon: Texture2D = explorer._get_icon_for_item({"name": fname, "is_dir": false})
		_check(item_icon == expected_textures[fname], "Проводник назначает правильную ретро-иконку для %s" % fname)

	var folder_icon: Texture2D = explorer._get_icon_for_item({"name": "Игры", "is_dir": true})
	_check(folder_icon == load("res://assets/icons/games_folder.png"), "Проводник назначает games_folder.png для папки Игры")

	explorer.queue_free()
	await get_tree().process_frame
