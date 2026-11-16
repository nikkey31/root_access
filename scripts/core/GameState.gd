extends Node

# Глобальный менеджер состояния расследования (AutoLoad: GameState)
# Отвечает за сюжетный прогресс, проверку паролей, таймер и концовки

signal thought_triggered(text: String)
signal folder_unlocked(folder_name: String)
signal location_decrypted()
signal timer_started(duration: float)
signal timer_updated(time_left: float)
signal timer_expired()
signal game_ended(ending_id: int, details: Dictionary)

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

func _process(delta: float) -> void:
	if is_timer_active:
		time_remaining -= delta
		if time_remaining <= 0.0:
			time_remaining = 0.0
			is_timer_active = false
			emit_signal("timer_expired")
			trigger_ending(Ending.TIMEOUT, {"reason": "time_expired"})
		else:
			emit_signal("timer_updated", time_remaining)
			_check_timer_events()

func start_final_timer(duration: float = 60.0) -> void:
	time_remaining = duration
	is_timer_active = true
	emit_signal("timer_started", duration)
	print("[GameState] Запущен финальный 60-секундный таймер!")

func stop_timer() -> void:
	is_timer_active = false

func _check_timer_events() -> void:
	# На 30-й секунде (когда осталось <= 30.0) вылетает взятка от Саймона
	if time_remaining <= 30.0 and not bribe_shown:
		bribe_shown = true
		emit_signal("thought_triggered", "Входящее сообщение: взятка $100,000 от Саймона...")

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
	var normalized_key = key.strip_edges().to_upper().replace(" ", "")
	
	if normalized_file == "location.enc" and normalized_key == DECRYPT_KEY:
		is_location_decrypted = true
		emit_signal("location_decrypted")
		print("[GameState] location.enc успешно дешифрован!")
		return true
	return false

func trigger_thought(text: String, is_clue_hint: bool = false) -> void:
	# На сложной сложности отключаются подсказывающие мысли об уликах
	if current_difficulty == Difficulty.HARD and is_clue_hint:
		return
	emit_signal("thought_triggered", text)

func trigger_ending(ending: Ending, details: Dictionary = {}) -> void:
	final_ending = ending
	is_timer_active = false
	emit_signal("game_ended", int(ending), details)
	print("[GameState] Игра завершена! Концовка: ", ending, " Детали: ", details)
