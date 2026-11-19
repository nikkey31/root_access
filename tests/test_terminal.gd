extends Node

func _ready() -> void:
	print("====================================================")
	print("ЗАПУСК ТЕСТИРОВАНИЯ ТЕРМИНАЛА (ISSUE #11 - ЖЕНЯ)")
	print("====================================================")
	
	# 1. Загрузка сцены Terminal.tscn
	var terminal_scene = load("res://scenes/apps/Terminal.tscn")
	assert(terminal_scene != null, "Сцена scenes/apps/Terminal.tscn должна успешно загружаться")
	
	var terminal = terminal_scene.instantiate()
	add_child(terminal)
	
	# Проверка DoD 1: Зеленый ретро-стиль текста на черном фоне
	var bg = terminal.get_node("Background") as ColorRect
	assert(bg != null, "Узел Background должен существовать")
	assert(bg.color == Color(0, 0, 0, 1), "Фон должен быть черным")
	
	var output = terminal.output_label
	assert(output != null, "OutputLabel должен существовать")
	assert(output.get_theme_color("default_color") == Color(0.2, 1, 0.2, 1), "Цвет текста должен быть зеленым")
	print("[DoD 1 ПРОЙДЕН] Черный фон и зеленый ретро-текст подтверждены.")
	
	# Проверка DoD 2: Команды help и clear работают корректно
	# Тест help
	terminal._on_command_submitted("help")
	var help_text = output.get_parsed_text()
	assert(help_text.contains("help") and help_text.contains("ls") and help_text.contains("cat"), "Команда help должна выводить список утилит")
	print("[DoD 2.1 ПРОЙДЕН] Команда help успешно вывела список доступных утилит.")
	
	# Тест clear
	terminal._on_command_submitted("clear")
	assert(output.get_parsed_text() == "", "Команда clear должна полностью очищать экран")
	print("[DoD 2.2 ПРОЙДЕН] Команда clear успешно очистила экран.")
	
	# Проверка DoD 3: При вводе неизвестной команды выводится понятное сообщение об ошибке
	terminal._on_command_submitted("foobar123")
	var err_text = output.get_parsed_text()
	assert(err_text.contains("Неизвестная команда") and err_text.contains("foobar123"), "Должно выводиться понятное сообщение об ошибке")
	print("[DoD 3 ПРОЙДЕН] Неизвестная команда выводит понятную ошибку.")
	
	# Проверка ls и cat через VFS
	terminal._on_command_submitted("clear")
	terminal._on_command_submitted("ls")
	var ls_text = output.get_parsed_text()
	assert(ls_text.contains("Работа") or ls_text.contains("график_работ.txt"), "ls должен отображать элементы из VFS.gd")
	print("[ls / VFS ПРОЙДЕН] Команда ls успешно запросила файлы из VFS.gd.")
	
	terminal._on_command_submitted("cat пароли.txt")
	var cat_text = output.get_parsed_text()
	assert(cat_text.contains("Папка Работа: др Юджина"), "cat должен выводить содержимое текстового файла")
	print("[cat / VFS ПРОЙДЕН] Команда cat успешно вывела содержимое текстового файла.")
	
	# Проверка DoD 4: Терминал корректно встраивается внутрь WindowFrame.tscn
	var frame_scene = load("res://scenes/ui/WindowFrame.tscn")
	assert(frame_scene != null, "Сцена WindowFrame.tscn должна существовать")
	var frame = frame_scene.instantiate() as WindowFrame
	add_child(frame)
	
	var embedded_terminal = terminal_scene.instantiate()
	frame.embed_app(embedded_terminal)
	
	assert(frame.content_container.get_child_count() == 1, "Terminal должен успешно встроиться в content_container WindowFrame")
	assert(frame.content_container.get_child(0) == embedded_terminal, "Первым дочерним элементом должен быть Terminal")
	print("[DoD 4 ПРОЙДЕН] Терминал корректно встраивается внутрь WindowFrame.tscn.")
	
	print("====================================================")
	print("ВСЕ ПРОВЕРКИ ИЗ ЧЕКЛИСТА DEFINITION OF DONE ПРОЙДЕНЫ!")
	print("====================================================")
	
	get_tree().quit(0)
