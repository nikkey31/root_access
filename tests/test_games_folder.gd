extends Node

## Headless-тест папки «Игры» и трёх встроенных приложений (ПР № 4).
## Запуск:
##   godot --headless --path . --scene res://tests/test_games_folder.tscn

var _failures: Array[String] = []
var _last_notification: String = ""

func _ready() -> void:
	await get_tree().process_frame
	GameState.reset_state()
	if VFS:
		VFS.reset_vfs()
	if not GameState.notification_triggered.is_connected(_on_notification):
		GameState.notification_triggered.connect(_on_notification)

	var desktop: Desktop = load("res://scenes/desktop/Desktop.tscn").instantiate()
	get_tree().root.add_child(desktop)
	await get_tree().process_frame
	await get_tree().process_frame

	# --- Рабочий стол и VFS -------------------------------------------------
	var games_icon := desktop.get_node_or_null("DesktopSurface/Icons/GamesIcon")
	_check(games_icon != null, "На рабочем столе есть папка «Игры»")
	var start_has_games := false
	for item in desktop.start_items.get_children():
		if item is StartMenuItem and item.app_id == "games":
			start_has_games = true
	_check(start_has_games, "Приложение «Игры» есть в меню «Пуск»")

	var vfs = VFS.get_vfs()
	_check(vfs != null, "VFS доступна")
	var fishing_node: Dictionary = vfs.files_database.get("C:\\ROOT_ACCESS\\Игры\\fishing.exe", {})
	var chess_node: Dictionary = vfs.files_database.get("C:\\ROOT_ACCESS\\Игры\\chess.exe", {})
	var shadow_node: Dictionary = vfs.files_database.get("C:\\ROOT_ACCESS\\Игры\\shadow_fight_1.exe", {})
	_check(fishing_node.get("type", "") == "app_link", "fishing.exe — запускаемый ярлык")
	_check(chess_node.get("type", "") == "app_link", "chess.exe — запускаемый ярлык")
	_check(shadow_node.get("type", "") == "app_link", "shadow_fight_1.exe — запускаемый ярлык")

	# --- Папка «Игры» в Проводнике -----------------------------------------
	desktop.open_app("games")
	await get_tree().process_frame
	var games_window := desktop._find_window("games")
	_check(games_window != null, "Папка «Игры» открывается в окне WindowFrame")
	var games_explorer: ExplorerApp = games_window.content_container.get_child(0) as ExplorerApp
	_check(games_explorer != null, "Содержимое папки — ExplorerApp")
	if games_explorer:
		_check(games_explorer.current_path == "C:\\ROOT_ACCESS\\Игры", "Проводник открыт на C:\\ROOT_ACCESS\\Игры")
		_check(GameState.is_games_folder_inspected, "Флаг исследования папки «Игры» установлен")
		var items: Array = vfs.list_dir("C:\\ROOT_ACCESS\\Игры")
		_check(items.size() == 3, "В папке ровно три приложения")

	# --- Рыбалка ------------------------------------------------------------
	desktop.open_app("fishing")
	await get_tree().process_frame
	var fishing_window := desktop._find_window("fishing")
	_check(fishing_window != null, "fishing.exe открывается в WindowFrame")
	var fishing: FishingMinigame = fishing_window.content_container.get_child(0) as FishingMinigame
	_check(fishing != null, "Содержимое fishing.exe — FishingMinigame")
	if fishing:
		_check(fishing.get_state_name() == "IDLE", "Рыбалка стартует в спокойном состоянии")
		_check(fishing.get_bobber_texture() != null, "Спрайт поплавка загружен")
		fishing.call("_start_cast")
		_check(fishing.get_state_name() == "CASTING", "Заброс переводит игру в CASTING")
		fishing.call("_enter_bite")
		_check(fishing.get_state_name() == "BITE", "Поклёвка переводит игру в BITE")
		fishing.call("_hook_fish")
		_check(fishing.get_state_name() == "FIGHT", "Подсечка переводит игру в FIGHT")
		fishing.set("_tension", 50.0)
		fishing.set("_reeling", true)
		fishing.call("_update_fight", 0.2)
		_check(fishing.get_tension() > 50.0, "Удержание кнопки увеличивает натяжение")
		fishing.set("_reeling", false)
		fishing.call("_update_fight", 0.1)
		_check(fishing.get_tension() < 60.0, "Отпускание кнопки ослабляет леску")

		# Три рыбы, затем гарантированный кейс с фрагментом ключа.
		for i in range(3):
			fishing.call("_complete_catch")
			await get_tree().process_frame
		_check(GameState.fishing_catch_count == 3, "После трёх уловов счётчик рыб равен 3")
		_check(not GameState.has_game_key_fragment, "До четвёртого улова фрагмента ключа ещё нет")
		_check(fishing.get_catch_count() == 3, "Рыбалка помнит три пойманные рыбы")
		fishing.call("_complete_catch")
		await get_tree().process_frame
		_check(fishing.get_state_name() == "TREASURE", "Четвёртый улов — старый кейс")
		_check(GameState.has_game_key_fragment, "Флаг фрагмента ключа сохранён в GameState")
		_check(GameState.game_key_fragment == "LENINA", "Фрагмент ключа — LENINA")
		_check(_last_notification.contains("фрагмент ключа"), "Показ уведомления о фрагменте ключа")

	# --- Шахматы ------------------------------------------------------------
	desktop.open_app("chess")
	await get_tree().process_frame
	var chess_window := desktop._find_window("chess")
	_check(chess_window != null, "chess.exe открывается в WindowFrame")
	var chess: ChessMinigame = chess_window.content_container.get_child(0) as ChessMinigame
	_check(chess != null, "Содержимое chess.exe — ChessMinigame")
	if chess:
		_check(chess.get_stage() == 0, "Шахматная задача стартует с первого хода")
		var wrong := chess.try_move("d1", "e1")
		_check(not wrong, "Неверный ход не принимается")
		var first := chess.try_move("e7", "e8")
		_check(first, "Жертва ферзя Qe8+ принимается")
		_check(chess.get_stage() == 1, "После шаха бот отвечает, задача переходит на второй ход")
		_check(chess.get_board_piece("e8").get("color", "") == "b", "Чёрная ладья забирает ферзя на e8")
		var second := chess.try_move("e1", "e8")
		_check(second, "Мат Rxe8# принимается")
		_check(chess.is_puzzle_solved(), "Шахматная задача решена")
		_check(GameState.is_chess_puzzle_solved, "Флаг решения сохранён в GameState")
		_check(chess.get_history_text().contains("54"), "В истории ходов есть пасхалка «54»")
		_check(chess.get_history_text().contains("Rxe8#"), "Мат записан в историю ходов")

	# --- Битый Shadow Fight -------------------------------------------------
	desktop.open_app("shadow_fight_1")
	await get_tree().process_frame
	var shadow_window := desktop._find_window("shadow_fight_1")
	_check(shadow_window != null, "shadow_fight_1.exe открывает окно ошибки")
	var shadow: ShadowFightError = shadow_window.content_container.get_child(0) as ShadowFightError
	_check(shadow != null, "Содержимое — ShadowFightError")
	if shadow:
		_check(shadow.get_error_text().contains("критические файлы ресурсов повреждены"), "Текст ошибки про повреждённые ресурсы")
		_check(shadow.get_error_text().contains("0x8004F012"), "Код ошибки 0x8004F012")
		_check(GameState.is_shadow_fight_error_seen, "Флаг ошибки Shadow Fight сохранён")
		_check(not shadow.is_details_visible(), "Подробности сначала скрыты")
		shadow.call("_toggle_details")
		_check(shadow.is_details_visible(), "Кнопка «Подробнее» раскрывает детали")
		shadow.press_ok()
		await get_tree().process_frame
		_check(not is_instance_valid(shadow_window) or not shadow_window.visible, "Кнопка ОК закрывает окно ошибки")

	if _failures.is_empty():
		print("GAMES FOLDER: PASS — папка «Игры» и три приложения работают.")
	else:
		for failure in _failures:
			printerr("FAIL: " + failure)
		printerr("GAMES FOLDER: FAIL — %d проверок." % _failures.size())
	get_tree().quit(0 if _failures.is_empty() else 1)


func _on_notification(text: String) -> void:
	_last_notification = text


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
