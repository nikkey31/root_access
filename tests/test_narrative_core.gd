extends Node

## Автотест нарративного ядра (Pair 3 — Никита):
## 1. Панель внутренних мыслей Ника (ThoughtBox): тайп-эффект, 2-кликовое управление, очередь, HARD-фильтр.
## 2. Всплывающие системные уведомления (ToastBanner) по уровням сложности.
## 3. Сигнал дешифровки location.enc -> перемотка часов 02:15 -> 03:40 + ЭЛТ-помеха.
## 4. Прослушивание record.wav -> запуск 60-сек таймера, показ FinalTimerBar, верхний компактный режим ThoughtBox.
## 5. Ловушки таймера (взятка на 30 сек, фишинг через 5 сек после отмены) и абсолютный приоритет 00:00.

var _errors: Array[String] = []

func _check(cond: bool, msg: String) -> void:
	if cond:
		print("[OK] " + msg)
	else:
		print("[FAIL] " + msg)
		_errors.append(msg)

func _ready() -> void:
	print("====================================================")
	print("ЗАПУСК ТЕСТИРОВАНИЯ НАРРАТИВНОГО ЯДРА (PAIR 3 - НИКИТА)")
	print("====================================================")
	GameState.reset_state()

	var desktop_scene: PackedScene = load("res://scenes/desktop/Desktop.tscn")
	var desktop: Desktop = desktop_scene.instantiate()
	add_child(desktop)
	await get_tree().process_frame

	_check(desktop.thought_box != null, "ThoughtBox встроен в Desktop.tscn")
	_check(desktop.final_timer_bar != null, "FinalTimerBar встроен в Desktop.tscn")
	_check(desktop.toast_banner != null, "ToastBanner встроен в Desktop.tscn")
	_check(not desktop.thought_box.visible, "ThoughtBox скрыт по умолчанию")
	_check(not desktop.final_timer_bar.visible, "FinalTimerBar скрыт до Акта 3")
	_check(desktop.get_story_time_string() == "02:15", "Стартовое время на часах 02:15")

	# 1. Тест мыслей Ника: очередь и 2-кликовое управление
	GameState.trigger_thought("Первая мысль Ника.", false)
	GameState.trigger_thought("Вторая мысль в очереди.", false)
	_check(desktop.thought_box.visible and desktop.thought_box.is_active(), "Мысль открыла ThoughtBox")
	_check(desktop.thought_box.is_typing(), "Включён посимвольный тайп-эффект")

	# 1-й клик -> мгновенно допечатывает текст
	desktop.thought_box.advance_interaction()
	_check(not desktop.thought_box.is_typing(), "1-й клик мгновенно допечатал текст")
	_check(desktop.thought_box.visible, "После 1-го клика окно ещё открыто")

	# 2-й клик -> переходит к следующей мысли из очереди
	desktop.thought_box.advance_interaction()
	_check(desktop.thought_box.get_current_text() == "Вторая мысль в очереди.", "2-й клик переключил на следующую мысль в очереди")
	desktop.thought_box.advance_interaction()
	desktop.thought_box.advance_interaction()
	_check(not desktop.thought_box.visible, "После закрытия очереди ThoughtBox скрывается")

	# 2. Тест сложности HARD (подсказки отключаются, сюжетные мысли остаются)
	GameState.current_difficulty = GameState.Difficulty.HARD
	GameState.trigger_thought("Подсказка про фургон 6752", true)
	_check(not desktop.thought_box.visible, "На HARD наводящая мысль об улике отключена")
	GameState.trigger_notification("Новая задача: выяснить ДР Юджина", GameState.Difficulty.EASY)
	_check(not desktop.toast_banner.visible, "На HARD системная подсказка ToastBanner отключена")
	GameState.current_difficulty = GameState.Difficulty.EASY
	GameState.trigger_notification("Новая задача: выяснить ДР Юджина", GameState.Difficulty.EASY)
	_check(desktop.toast_banner.visible, "На EASY системная подсказка ToastBanner показывается")
	desktop.toast_banner.hide_banner()

	# 3. Тест дешифровки -> перемотка часов 02:15 -> 03:40
	var decrypted := GameState.verify_decryption("location.enc", "lenina 54")
	_check(decrypted, "GameState.verify_decryption принимает 'lenina 54'")
	_check(desktop.thought_box.visible, "После дешифровки выведена мысль Ника")
	desktop.thought_box.clear_thoughts()
	await get_tree().create_timer(1.25).timeout
	_check(desktop.get_story_time_string() == "03:40", "Часы перемотались с 02:15 до 03:40 после дешифровки")

	# 4. Тест прослушивания record.wav -> старт 60-сек таймера и верхний компактный режим мыслей
	GameState.mark_audio_listened()
	_check(GameState.is_timer_active, "После record.wav запустился финальный 60-сек таймер")
	_check(desktop.final_timer_bar.visible, "Появилась верхняя красная плашка FinalTimerBar")
	_check(desktop.thought_box.is_compact_top_mode(), "ThoughtBox перешёл в компактный верхний режим (не перекрывает Карту)")
	desktop.thought_box.clear_thoughts()

	# 5. Тест 30-й секунды (взятка), отмены взятки (+5 сек фишинг) и абсолютного приоритета 00:00
	var bribe_caught := [false]
	var phishing_caught := [false]
	var ended_id := [0]
	GameState.bribe_triggered.connect(func() -> void: bribe_caught[0] = true)
	GameState.phishing_triggered.connect(func() -> void: phishing_caught[0] = true)
	GameState.game_ended.connect(func(eid: int, _d: Dictionary) -> void: ended_id[0] = eid)

	GameState.time_remaining = 30.1
	GameState._process(0.2)
	_check(bribe_caught[0] and GameState.bribe_shown, "На 30-й секунде сработал сигнал взятки bribe_triggered")

	GameState.cancel_bribe()
	GameState._process(5.1)
	_check(phishing_caught[0] and GameState.phishing_shown, "Через 5 секунд после отмены взятки сработал phishing_triggered")

	# Проверка абсолютного приоритета 00:00
	GameState.time_remaining = 0.05
	GameState._process(0.1)
	_check(ended_id[0] == int(GameState.Ending.TIMEOUT), "При 00:00 активирована концовка TIMEOUT")
	GameState.trigger_ending(GameState.Ending.SALVATION, {})
	_check(GameState.final_ending == GameState.Ending.TIMEOUT, "Защита от гонки состояний: концовка после 00:00 не перезаписывается")

	GameState.reset_state()
	desktop.queue_free()

	print("====================================================")
	if _errors.is_empty():
		print("ВСЕ ПРОВЕРКИ НАРРАТИВНОГО ЯДРА ПРОЙДЕНЫ! (0 ошибок)")
		get_tree().quit(0)
	else:
		print("НАЙДЕНЫ ОШИБКИ: ", _errors.size())
		get_tree().quit(1)
