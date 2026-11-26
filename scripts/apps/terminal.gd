class_name TerminalApp
extends Control

## Встроенный терминал виртуальной операционной системы (Issue #11).
## Разработчик: Женя (Jeka2287).
## Реализует консоль с зеленым ретро-текстом на черном фоне, историю команд
## и командный процессор с интеграцией в VFS.gd.

signal command_executed(command_name: String, args: Array)

@onready var output_label: RichTextLabel = $MarginContainer/VBoxContainer/OutputScroll/OutputLabel
@onready var output_scroll: ScrollContainer = $MarginContainer/VBoxContainer/OutputScroll
@onready var prompt_label: Label = $MarginContainer/VBoxContainer/InputBar/PromptLabel
@onready var command_input: LineEdit = $MarginContainer/VBoxContainer/InputBar/CommandInput

var vfs: Node
var history: Array[String] = []
var history_index: int = -1

const COLOR_GREEN = "#33FF33"
const COLOR_YELLOW = "#FFFF33"
const COLOR_RED = "#FF3333"
const COLOR_CYAN = "#33FFFF"

func _ready() -> void:
	# Инициализация VFS (берем синглтон или создаем локальный узел при автономном запуске)
	if VFS.get_vfs() != null:
		vfs = VFS.get_vfs()
	else:
		vfs = VFS.new()
		add_child(vfs)
	
	# Подключение сигналов ввода
	command_input.text_submitted.connect(_on_command_submitted)
	command_input.text_changed.connect(_on_command_text_changed)
	command_input.gui_input.connect(_on_input_gui_input)
	gui_input.connect(_on_terminal_clicked)
	
	_print_welcome_banner()
	_update_prompt()
	command_input.grab_focus()

func _print_welcome_banner() -> void:
	output_label.clear()
	var banner = "[color=%s]" % COLOR_GREEN
	banner += "=========================================================\n"
	banner += " RootAccess Virtual Terminal v2.4 [Panasonic Toughbook OS]\n"
	banner += " (C) 1998-2009 Cyber Crime Forensic Unit. All rights reserved.\n"
	banner += " Введите '[b]help[/b]' для вывода списка доступных утилит.\n"
	banner += "=========================================================\n[/color]"
	output_label.append_text(banner)

func _update_prompt() -> void:
	var path = vfs.get_current_directory() if vfs else "C:\\ROOT_ACCESS"
	prompt_label.text = path + "> "

func _on_command_text_changed(_new_text: String) -> void:
	_play_audio("play_key_click")

func _on_command_submitted(raw_text: String) -> void:
	_play_audio("play_key_click")
	var trimmed = raw_text.strip_edges()
	command_input.text = ""
	history_index = -1
	
	# Выводим строку с prompt в историю экрана
	var prompt_str = prompt_label.text
	output_label.append_text("\n[color=%s]%s%s[/color]\n" % [COLOR_GREEN, prompt_str, trimmed])
	
	if trimmed != "":
		history.append(trimmed)
		if history.size() > 50:
			history.pop_front()
		_process_command(trimmed)
	
	_scroll_to_bottom()
	command_input.grab_focus()

func _process_command(command_line: String) -> void:
	var tokens = _tokenize(command_line)
	if tokens.is_empty():
		return
	
	var cmd = tokens[0].to_lower()
	var args = tokens.slice(1)
	
	command_executed.emit(cmd, args)
	
	match cmd:
		"help":
			_cmd_help(args)
		"clear", "cls":
			_cmd_clear()
		"pwd":
			_cmd_pwd(args)
		"cd", "chdir":
			_cmd_cd(args)
		"ls", "dir":
			_cmd_ls(args)
		"cat", "type":
			_cmd_cat(args)
		"decrypt":
			_cmd_decrypt(args)
		"netstat":
			_cmd_netstat(args)
		"chkdsk":
			_cmd_chkdsk(args)
		"wipe":
			_cmd_wipe(args)
		_:
			_print_error("Неизвестная команда: '%s'. Введите 'help' для просмотра списка доступных команд." % cmd)

func _cmd_help(_args: Array) -> void:
	var text = "[color=%s][b]Список доступных системных утилит:[/b]\n" % COLOR_GREEN
	text += "  [b]help[/b]                      - вывод списка доступных утилит\n"
	text += "  [b]clear[/b] (алиас: cls)         - очистка экрана терминала\n"
	text += "  [b]pwd[/b]                       - вывод текущей рабочей директории\n"
	text += "  [b]cd <папка>[/b]                - переход в указанную директорию (cd .. - вверх)\n"
	text += "  [b]ls[/b]    (алиас: dir)         - вывод файлов текущей директории через VFS\n"
	text += "  [b]cat <file>[/b]                - просмотр содержимого текстового файла\n"
	text += "  [b]decrypt <file> -k <keys>[/b]  - дешифрование (.enc), поддержка составных ключей\n"
	text += "  [b]netstat [-an][/b]             - мониторинг активных сетевых подключений\n"
	text += "  [b]chkdsk [том][/b]              - проверка целостности секторов и кэша тома\n"
	text += "  [b]wipe [--force][/b]            - аварийная очистка секторов диска\n[/color]"
	output_label.append_text(text)

func _cmd_clear() -> void:
	output_label.clear()

func _cmd_pwd(_args: Array = []) -> void:
	if not vfs:
		_print_error("Ошибка: подсистема VFS недоступна.")
		return
	output_label.append_text("[color=%s]%s[/color]\n" % [COLOR_GREEN, vfs.get_current_directory()])

func _cmd_cd(args: Array) -> void:
	if not vfs:
		_print_error("Ошибка: подсистема VFS недоступна.")
		return
	
	if args.is_empty():
		output_label.append_text("[color=%s]%s[/color]\n" % [COLOR_GREEN, vfs.get_current_directory()])
		return
	
	var target = " ".join(args)
	var res = vfs.change_directory(target)
	if not res.get("success", false):
		_print_error(res.get("error", "Каталог не найден."))
	else:
		_update_prompt()

func _cmd_ls(_args: Array) -> void:
	if not vfs:
		_print_error("Ошибка: подсистема VFS недоступна.")
		return
	
	var items = vfs.list_dir()
	if items.is_empty():
		output_label.append_text("[color=%s]Директория пуста.[/color]\n" % COLOR_GREEN)
		return
	
	var text = "[color=%s]Содержимое папки %s:\n" % [COLOR_GREEN, vfs.get_current_directory()]
	for item in items:
		var name_str = item.get("name", "")
		if item.get("is_dir", false):
			text += "  [DIR]  [color=%s]%s\\[/color]\n" % [COLOR_CYAN, name_str]
		elif item.get("is_encrypted", false):
			text += "  [ENC]  [color=%s]%s[/color]\n" % [COLOR_YELLOW, name_str]
		elif name_str.to_lower().ends_with(".exe"):
			text += "  [EXE]  [color=%s]%s[/color]\n" % [COLOR_CYAN, name_str]
		else:
			text += "  [TXT]  %s\n" % name_str
	text += "[/color]"
	output_label.append_text(text)

func _cmd_cat(args: Array) -> void:
	if args.is_empty():
		_print_error("Использование команды: cat <имя_файла>")
		return
	
	if not vfs:
		_print_error("Ошибка: подсистема VFS недоступна.")
		return
	
	var filename = args[0]
	var res = vfs.read_file(filename)
	if not res.get("success", false):
		if res.get("is_encrypted", false):
			_print_warning(res.get("error", "Файл зашифрован."))
		else:
			_print_error(res.get("error", "Ошибка чтения файла."))
		return
	
	var content = res.get("content", "")
	output_label.append_text("[color=%s]%s[/color]\n" % [COLOR_GREEN, content])

func _cmd_decrypt(args: Array) -> void:
	var parsed := _parse_decrypt_args(args)
	if not parsed.get("valid", false):
		_print_error(parsed.get("error", "Использование команды: decrypt <файл.enc> -k <ключ_1> [ключ_2 ...]"))
		return

	var filename: String = parsed["filename"]
	var key: String = parsed["key"]
	var key_parts: Array = parsed["parts"]

	output_label.append_text("[color=%s]Запуск дешифрования криптоконтейнера: %s...[/color]\n" % [COLOR_CYAN, filename])
	if key_parts.size() > 1:
		output_label.append_text("[color=%s]Собран составной ключ (%d комп.): %s[/color]\n" % [COLOR_CYAN, key_parts.size(), " + ".join(key_parts)])

	var progress_steps = [
		"[░░░░░░░░░░░░░░░░]   0%",
		"[████░░░░░░░░░░░░]  25%",
		"[████████░░░░░░░░]  50%",
		"[████████████░░░░]  75%",
		"[████████████████] 100% COMPLETE"
	]

	for step in progress_steps:
		output_label.append_text("[color=%s]%s[/color]\n" % [COLOR_GREEN, step])
		_scroll_to_bottom()
		if get_tree() and not get_tree().root.get_meta("is_test", false):
			await get_tree().create_timer(0.04).timeout

	var res = vfs.decrypt_file(filename, key, key_parts)
	if not res.get("success", false):
		_print_error(res.get("error", "Ошибка дешифрования."))
		return

	var unlocked_file = res.get("unlocked_file", "record.wav")
	var success_text = "[color=%s][SUCCESS] Ключ подтвержден: контрольная сумма совпадает!\n" % COLOR_GREEN
	if unlocked_file == "record.wav":
		success_text += "Разблокирован скрытый аудиофайл: %s\n" % unlocked_file
		success_text += "Файл сохранён в папку: \\Работа\\%s\n" % unlocked_file
		success_text += "Сюжетное время на часах перемотано на 03:40.\n"
		success_text += "Аудиозапись доступна для прослушивания в Проводнике.[/color]\n"
	else:
		success_text += "Разблокирован файл: %s\n" % unlocked_file
		success_text += "Файл доступен для чтения через Проводник и команду cat.[/color]\n"
	output_label.append_text(success_text)


## Разбор аргументов decrypt с поддержкой составного ключа (-k part1 part2, -k part1+part2, нескольких -k).
func _parse_decrypt_args(args: Array) -> Dictionary:
	if args.size() < 2:
		return {
			"valid": false,
			"error": "Использование команды: decrypt <файл.enc> -k <ключ_1> [ключ_2 ...]"
		}

	var raw_tokens: Array[String] = []
	for t in args:
		raw_tokens.append(str(t))

	var filename := ""
	var key_raw: Array[String] = []

	# Сначала пробуем выделить имя файла (.enc или первый позиционный аргумент до флага -k)
	var first_flag_idx := -1
	for i in range(raw_tokens.size()):
		if raw_tokens[i] == "-k" or raw_tokens[i] == "--key":
			first_flag_idx = i
			break

	if first_flag_idx != 0:
		filename = raw_tokens[0]
		for i in range(1, raw_tokens.size()):
			if raw_tokens[i] == "-k" or raw_tokens[i] == "--key":
				continue
			key_raw.append(raw_tokens[i])
	else:
		# Например: decrypt -k PART1 PART2 secret.enc
		for token in raw_tokens:
			if token == "-k" or token == "--key":
				continue
			if filename == "" and token.to_lower().ends_with(".enc"):
				filename = token
			else:
				key_raw.append(token)
		if filename == "" and not key_raw.is_empty():
			filename = key_raw.pop_back()

	if filename == "" or key_raw.is_empty():
		return {
			"valid": false,
			"error": "Флаг -k требует указания ключа (или фрагментов составного ключа)."
		}

	var parts := _split_composite_parts(key_raw)
	if parts.is_empty():
		return {
			"valid": false,
			"error": "Укажите непустой ключ дешифрования: decrypt %s -k <ключ>" % filename
		}

	return {
		"valid": true,
		"filename": filename,
		"key": " ".join(parts),
		"parts": parts
	}


func _split_composite_parts(tokens: Array[String]) -> Array[String]:
	var parts: Array[String] = []
	for token in tokens:
		var cleaned := token.strip_edges()
		for sep in ["+", ",", ";", "_", "-", "/"]:
			cleaned = cleaned.replace(sep, " ")
		for piece in cleaned.split(" ", false):
			var trimmed := piece.strip_edges()
			if trimmed != "":
				parts.append(trimmed)
	return parts


## Мониторинг активных сетевых соединений (выявление бэкдора злоумышленников).
func _cmd_netstat(_args: Array = []) -> void:
	var table = "[color=%s][b]Активные сетевые подключения (TCP/UDP):[/b]\n\n" % COLOR_GREEN
	table += "  Протокол  Локальный адрес        Внешний адрес          Состояние       Процесс / PID\n"
	table += "  TCP       127.0.0.1:1042         0.0.0.0:0              LISTENING       [system.exe / 4]\n"
	table += "  TCP       192.168.1.44:139       192.168.1.1:445        TIME_WAIT       [netbios.sys / 312]\n"
	table += "[color=%s]  TCP       192.168.1.44:4481      185.174.98.21:9082     ESTABLISHED     [Host-982 / eugene_relay.dll (982)][/color]\n" % COLOR_RED
	table += "[color=%s]  UDP       192.168.1.44:6752      185.174.98.21:9083     ACTIVE_BEACON   [geo_telemetry.svc (1408)][/color]\n\n" % COLOR_YELLOW
	table += "[color=%s][ТРЕВОГА] Обнаружен скрытый исходящий канал злоумышленников: удалённый узел [Host-982] (eugene_relay.dll)![/color]\n" % COLOR_RED
	table += "[color=%s]Соединение активно в фоновом режиме вопреки статусу «Нет сети».[/color]\n[/color]" % COLOR_YELLOW
	output_label.append_text(table)
	_play_audio("play_notify")


## Проверка файловой системы и кластеров диска (обнаруживает битые сектора в играх).
func _cmd_chkdsk(args: Array = []) -> void:
	var target_vol := "C:\\"
	for arg in args:
		var a := str(arg).strip_edges()
		if a != "" and not a.begins_with("/"):
			target_vol = a
			break

	output_label.append_text("[color=%s]Тип файловой системы: FAT32 (Том: ROOT_ACCESS, S/N: 2409-6752)\n" % COLOR_GREEN)
	output_label.append_text("Запуск проверки целостности тома %s...\n[/color]" % target_vol)

	var scan_steps = [
		"  Этап 1: проверка базовой структуры каталогов и таблиц FAT... 100%",
		"  Этап 2: проверка связей индекса \\Игры\\... 100%",
		"  Этап 3: сканирование секторов данных..."
	]
	for step in scan_steps:
		output_label.append_text("[color=%s]%s[/color]\n" % [COLOR_GREEN, step])
		_scroll_to_bottom()
		if get_tree() and not get_tree().root.get_meta("is_test", false):
			await get_tree().create_timer(0.05).timeout

	var report := "\n[color=%s][ОШИБКА СКАНИРОВАНИЯ] Обнаружены битые сектора (BAD SECTORS) в модуле:\n" % COLOR_RED
	report += "  -> C:\\ROOT_ACCESS\\Игры\\shadow_fight_1.exe\n"
	report += "     Повреждённые кластеры: #4012, #4019, #4088 (CRC32 MISMATCH, 12 КБ потеряно).\n"
	report += "     Целостность бинарного файла нарушена — восстановление невозможно.[/color]\n\n"
	report += "[color=%s][ПОТЕНЦИАЛЬНЫЕ ДАННЫЕ] Найдены несвязанные цепочки кластеров в локальном кэше:\n" % COLOR_YELLOW
	report += "  -> C:\\ROOT_ACCESS\\Игры\\fishing.exe (кэш сессии: temp_catch.cache)\n"
	report += "     Подсказка: в кэше fishing.exe сохранились фрагменты пользовательских логов и ключей.[/color]\n\n"
	report += "[color=%s]Итого: 20 971 520 КБ на диске. 12 КБ в повреждённых секторах.\n[/color]" % COLOR_GREEN
	output_label.append_text(report)
	_play_audio("play_error")


func _cmd_wipe(args: Array) -> void:
	if args.has("--force"):
		output_label.append_text("[color=%s][КРИТИЧЕСКИЙ РЕЖИМ] Инициализация команды wipe --force...\n" % COLOR_RED)
		output_label.append_text("Стирание секторов виртуального хранилища... 100%\nДанные безвозвратно уничтожены.[/color]\n")
		if vfs and vfs.has_method("wipe_storage"):
			vfs.wipe_storage()
		if GameState:
			GameState.trigger_ending(GameState.Ending.CORRUPTION, {"reason": "wipe_force"})
	else:
		_print_warning("[ПРЕДУПРЕЖДЕНИЕ] Команда уничтожения данных требует подтверждения: wipe --force")

func _print_error(msg: String) -> void:
	output_label.append_text("[color=%s][ОШИБКА] %s[/color]\n" % [COLOR_RED, msg])
	_play_audio("play_error")

func _print_warning(msg: String) -> void:
	output_label.append_text("[color=%s][ВНИМАНИЕ] %s[/color]\n" % [COLOR_YELLOW, msg])
	_play_audio("play_notify")

func _play_audio(method_name: String) -> void:
	var am := get_node_or_null("/root/AudioManager")
	if am and am.has_method(method_name):
		am.call(method_name)

func _on_input_gui_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.is_pressed():
		return
	
	var key_event = event as InputEventKey
	
	# Навигация по истории команд (стрелка вверх / вниз)
	if key_event.keycode == KEY_UP:
		_play_audio("play_key_click")
		if history.size() > 0:
			if history_index == -1:
				history_index = history.size() - 1
			elif history_index > 0:
				history_index -= 1
			command_input.text = history[history_index]
			command_input.caret_column = command_input.text.length()
			get_viewport().set_input_as_handled()
	elif key_event.keycode == KEY_DOWN:
		_play_audio("play_key_click")
		if history_index != -1:
			if history_index < history.size() - 1:
				history_index += 1
				command_input.text = history[history_index]
			else:
				history_index = -1
				command_input.text = ""
			command_input.caret_column = command_input.text.length()
			get_viewport().set_input_as_handled()
	
	# Горячая клавиша Ctrl + L (очистка экрана)
	elif key_event.keycode == KEY_L and key_event.ctrl_pressed:
		_cmd_clear()
		get_viewport().set_input_as_handled()
	
	# Горячая клавиша Ctrl + C (сброс ввода)
	elif key_event.keycode == KEY_C and key_event.ctrl_pressed:
		output_label.append_text("\n[color=%s]%s%s^C[/color]\n" % [COLOR_GREEN, prompt_label.text, command_input.text])
		command_input.text = ""
		_scroll_to_bottom()
		get_viewport().set_input_as_handled()

func _tokenize(input_str: String) -> Array[String]:
	var tokens: Array[String] = []
	var current = ""
	var in_quotes = false
	var quote_char = ""
	
	for i in range(input_str.length()):
		var c = input_str[i]
		if in_quotes:
			if c == quote_char:
				in_quotes = false
			else:
				current += c
		else:
			if c == "\"" or c == "'":
				in_quotes = true
				quote_char = c
			elif c == " " or c == "\t":
				if current != "":
					tokens.append(current)
					current = ""
			else:
				current += c
	
	if current != "":
		tokens.append(current)
	
	return tokens

func _scroll_to_bottom() -> void:
	await get_tree().process_frame
	if output_scroll:
		output_scroll.scroll_vertical = int(output_scroll.get_v_scroll_bar().max_value)

func _on_terminal_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		command_input.grab_focus()

## Публичный метод для вставки команды из других приложений (например, из Заметок)
func paste_command(command_text: String) -> void:
	command_input.text = command_text
	command_input.caret_column = command_text.length()
	command_input.grab_focus()
