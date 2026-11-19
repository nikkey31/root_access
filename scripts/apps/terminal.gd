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

func _on_command_submitted(raw_text: String) -> void:
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
		"wipe":
			_cmd_wipe(args)
		_:
			_print_error("Неизвестная команда: '%s'. Введите 'help' для просмотра списка доступных команд." % cmd)

func _cmd_help(_args: Array) -> void:
	var text = "[color=%s][b]Список доступных системных утилит:[/b]\n" % COLOR_GREEN
	text += "  [b]help[/b]                 - вывод списка доступных утилит\n"
	text += "  [b]clear[/b] (алиас: cls)    - очистка экрана терминала\n"
	text += "  [b]pwd[/b]                  - вывод текущей рабочей директории\n"
	text += "  [b]cd <папка>[/b]          - переход в указанную директорию (cd .. - вверх)\n"
	text += "  [b]ls[/b]    (алиас: dir)    - вывод файлов текущей директории через VFS\n"
	text += "  [b]cat <file>[/b]           - просмотр содержимого текстового файла\n"
	text += "  [b]decrypt <file> -k <key>[/b] - дешифрование зашифрованного файла (.enc)\n"
	text += "  [b]wipe [--force][/b]       - аварийная очистка секторов диска\n[/color]"
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
	if args.size() < 2:
		_print_error("Использование команды: decrypt <файл.enc> -k <ключ>")
		return
	
	var filename = args[0]
	var key = ""
	
	var k_idx = -1
	for i in range(args.size()):
		if args[i] == "-k" or args[i] == "--key":
			k_idx = i
			break
	
	if k_idx != -1:
		if k_idx + 1 < args.size():
			var key_tokens = args.slice(k_idx + 1)
			key = " ".join(key_tokens)
		else:
			_print_error("Флаг -k требует указания ключа дешифрования.")
			return
	elif args.size() >= 2:
		var key_tokens = args.slice(1)
		key = " ".join(key_tokens)
	else:
		_print_error("Укажите ключ дешифрования: decrypt " + filename + " -k <ключ>")
		return
	
	output_label.append_text("[color=%s]Запуск дешифрования криптоконтейнера: %s...[/color]\n" % [COLOR_CYAN, filename])
	
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
	
	var res = vfs.decrypt_file(filename, key)
	if not res.get("success", false):
		_print_error(res.get("error", "Ошибка дешифрования."))
		return
	
	var unlocked_file = res.get("unlocked_file", "record.wav")
	var success_text = "[color=%s][SUCCESS] Ключ подтвержден: контрольная сумма совпадает!\n" % COLOR_GREEN
	success_text += "Разблокирован скрытый аудиофайл: %s\n" % unlocked_file
	success_text += "Файл сохранён в папку: \\Работа\\%s\n" % unlocked_file
	success_text += "Сюжетное время на часах перемотано на 03:40.\n"
	success_text += "Аудиозапись доступна для прослушивания в Проводнике.[/color]\n"
	output_label.append_text(success_text)

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

func _print_warning(msg: String) -> void:
	output_label.append_text("[color=%s][ВНИМАНИЕ] %s[/color]\n" % [COLOR_YELLOW, msg])

func _on_input_gui_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.is_pressed():
		return
	
	var key_event = event as InputEventKey
	
	# Навигация по истории команд (стрелка вверх / вниз)
	if key_event.keycode == KEY_UP:
		if history.size() > 0:
			if history_index == -1:
				history_index = history.size() - 1
			elif history_index > 0:
				history_index -= 1
			command_input.text = history[history_index]
			command_input.caret_column = command_input.text.length()
			get_viewport().set_input_as_handled()
	elif key_event.keycode == KEY_DOWN:
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
