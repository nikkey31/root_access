extends Node

# Глобальный менеджер состояния расследования (AutoLoad: GameState)
# Отвечает за сюжетный прогресс, проверку паролей, таймер и концовки

signal thought_triggered(text: String)
signal notification_triggered(text: String)
signal story_time_jump_requested(target_hour: int, target_minute: int, animate: bool)
signal folder_unlocked(folder_name: String)
signal location_decrypted()
signal audio_record_completed()
signal timer_started(duration: float)
signal timer_updated(time_left: float)
signal timer_expired()
signal bribe_triggered()
signal phishing_triggered()
signal game_ended(ending_id: int, details: Dictionary)
signal state_reset()

enum Difficulty {
	EASY,
	MEDIUM,
	HARD
}

enum Ending {
	NONE = 0,
	SALVATION = 1,       # Склад № 3 (Идеальное спасение)
	FALSE_TRAIL = 2,     # Ложная точка на карте
	TIMEOUT = 3,         # 60 секунд истекли
	HORROR = 4,          # Утечка геолокации (Незваный гость)
	CORRUPTION = 5       # Взятка $100k и wipe --force
}

# Текущая сложность игры
var current_difficulty: Difficulty = Difficulty.EASY

# Сюжетные флаги
var is_notes_opened: bool = false
var is_messenger_read: bool = false
var is_truck_photo_viewed: bool = false
var is_exif_viewed: bool = false
var is_work_folder_unlocked: bool = false
var is_location_decrypted: bool = false
var is_trash_inspected: bool = false
var is_audio_listened: bool = false

# Финальный таймер и ловушки
var is_timer_active: bool = false
var time_remaining: float = 60.0
var bribe_shown: bool = false
var bribe_cancelled: bool = false
var phishing_delay_remaining: float = -1.0
var phishing_shown: bool = false
var final_ending: Ending = Ending.NONE
var selected_map_point: String = ""

# Допустимые варианты пароля от папки «Работа»
const VALID_WORK_PASSWORDS: Array[String] = [
	"2409",
	"24.09",
	"24092009",
	"24/09",
	"24.09.2009"
]

const DECRYPT_KEY: String = "LENINA54"

func _ready() -> void:
	print("[GameState] Инициализирован менеджер расследования. Время: 02:15.")

func reset_state() -> void:
	current_difficulty = Difficulty.EASY
	is_notes_opened = false
	is_messenger_read = false
	is_truck_photo_viewed = false
	is_exif_viewed = false
	is_work_folder_unlocked = false
	is_location_decrypted = false
	is_trash_inspected = false
	is_audio_listened = false
	is_timer_active = false
	time_remaining = 60.0
	bribe_shown = false
	bribe_cancelled = false
	phishing_delay_remaining = -1.0
	phishing_shown = false
	final_ending = Ending.NONE
	selected_map_point = ""
	emit_signal("state_reset")

func _process(delta: float) -> void:
	if not is_timer_active or final_ending != Ending.NONE:
		return

	time_remaining -= delta
	if time_remaining <= 0.0:
		# Абсолютный приоритет таймера при 00:00 (защита от гонки состояний)
		time_remaining = 0.0
		is_timer_active = false
		phishing_delay_remaining = -1.0
		emit_signal("timer_updated", 0.0)
		emit_signal("timer_expired")
		trigger_ending(Ending.TIMEOUT, {"reason": "time_expired"})
		return

	emit_signal("timer_updated", time_remaining)
	_check_timer_events(delta)

func start_final_timer(duration: float = 60.0) -> void:
	if final_ending != Ending.NONE:
		return
	time_remaining = duration
	is_timer_active = true
	bribe_shown = false
	bribe_cancelled = false
	phishing_delay_remaining = -1.0
	phishing_shown = false
	emit_signal("timer_started", duration)
	print("[GameState] Запущен финальный 60-секундный таймер!")

func stop_timer() -> void:
	is_timer_active = false
	phishing_delay_remaining = -1.0

func cancel_bribe() -> void:
	if not is_timer_active or final_ending != Ending.NONE:
		return
	if bribe_cancelled or phishing_shown:
		return
	bribe_cancelled = true
	phishing_delay_remaining = 5.0

func _check_timer_events(delta: float) -> void:
	# На 30-й секунде (когда осталось <= 30.0) вылетает взятка от Саймона
	if time_remaining <= 30.0 and not bribe_shown:
		bribe_shown = true
		emit_signal("bribe_triggered")
		emit_signal("thought_triggered", "Сто тысяч… Нет. Нет!")

	# Через 5 секунд после отмены взятки вылетает фишинг-ловушка с геолокацией
	if bribe_cancelled and not phishing_shown and phishing_delay_remaining >= 0.0:
		phishing_delay_remaining -= delta
		if phishing_delay_remaining <= 0.0:
			phishing_delay_remaining = -1.0
			phishing_shown = true
			emit_signal("phishing_triggered")

func verify_work_password(input_password: String) -> bool:
	var cleaned = input_password.strip_edges().to_lower().replace(" ", "")
	for valid in VALID_WORK_PASSWORDS:
		if cleaned == valid.to_lower():
			is_work_folder_unlocked = true
			emit_signal("folder_unlocked", "Работа")
			print("[GameState] Папка «Работа» успешно разблокирована!")
			return true
	return false

func verify_decryption(file_name: String, key: String) -> bool:
	var normalized_file = file_name.strip_edges().to_lower()
	var normalized_key = _normalize_key(key)
	
	if normalized_file == "location.enc" and normalized_key == DECRYPT_KEY:
		is_location_decrypted = true
		emit_signal("location_decrypted")
		emit_signal("story_time_jump_requested", 3, 40, true)
		trigger_thought("Аудиофайл. Девять секунд. Надо послушать.", false)
		print("[GameState] location.enc успешно дешифрован!")
		return true
	return false


func _normalize_key(raw: String) -> String:
	var normalized := raw.strip_edges().to_upper()
	for sep in [" ", "\t", "+", "-", "_", ",", ";", ":", "/"]:
		normalized = normalized.replace(sep, "")
	return normalized

func mark_audio_listened() -> void:
	if is_audio_listened:
		return
	is_audio_listened = true
	emit_signal("audio_record_completed")
	trigger_thought("Звонок из дежурной части: Саймон вышел на связь! У меня ровно 60 секунд, чтобы назвать точку на карте!", false)
	start_final_timer(60.0)

func trigger_thought(text: String, is_clue_hint: bool = false) -> void:
	# На сложной сложности (и средней для части подсказок) отключаются наводящие мысли об уликах
	if is_clue_hint and current_difficulty != Difficulty.EASY:
		return
	emit_signal("thought_triggered", text)

func trigger_notification(text: String, max_difficulty: Difficulty = Difficulty.EASY) -> void:
	if int(current_difficulty) > int(max_difficulty):
		return
	emit_signal("notification_triggered", text)

func trigger_ending(ending: Ending, details: Dictionary = {}) -> void:
	if final_ending != Ending.NONE:
		return
	final_ending = ending
	is_timer_active = false
	phishing_delay_remaining = -1.0
	emit_signal("game_ended", int(ending), details)
	print("[GameState] Игра завершена! Концовка: ", ending, " Детали: ", details)

