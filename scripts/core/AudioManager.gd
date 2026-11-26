extends Node

## Глобальный звуковой движок (AutoLoad: AudioManager).
## Управляет пулом SFX (клики клавиатуры, звуки окон/ошибок Win98, пульс таймера,
## стук в дверь и выстрел) и фоновыми зацикленными треками (дождь за окном, гул ЭЛТ).

signal volume_changed(new_volume: float, is_muted: bool)
signal sfx_played(sfx_name: String)

const SFX_PATHS: Dictionary = {
	"key_click": "res://assets/audio/key_click.wav",
	"mouse_click": "res://assets/audio/mouse_click.wav",
	"win_open": "res://assets/audio/win_open.wav",
	"win_close": "res://assets/audio/win_close.wav",
	"win_error": "res://assets/audio/win_error.wav",
	"win_notify": "res://assets/audio/win_notify.wav",
	"win_success": "res://assets/audio/win_success.wav",
	"crt_poweroff": "res://assets/audio/crt_poweroff.wav",
	"timer_pulse": "res://assets/audio/timer_pulse.wav",
	"door_knock": "res://assets/audio/door_knock.wav",
	"gunshot": "res://assets/audio/gunshot.wav",
	"record_static": "res://assets/audio/record_static.wav",
}

const AMBIENT_PATHS: Dictionary = {
	"rain": "res://assets/audio/ambient_rain.ogg",
	"crt_hum": "res://assets/audio/ambient_crt_hum.ogg",
}

const SFX_POOL_SIZE: int = 10

var master_volume: float = 0.68
var is_muted: bool = false

## Наблюдаемое состояние (удобно для автотестов и отладки).
var last_sfx: String = ""
var sfx_history: Array[String] = []
var is_ambient_active: bool = false

var _streams: Dictionary = {}
var _sfx_pool: Array[AudioStreamPlayer] = []
var _pool_cursor: int = 0
var _loop_players: Dictionary = {}
var _ambient_players: Dictionary = {}

var _last_timer_second: int = -1
var _horror_sequence_id: int = 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_preload_streams()
	_build_players()
	_apply_master_bus()
	_connect_game_state()


func _preload_streams() -> void:
	for sfx_name in SFX_PATHS.keys():
		var path: String = SFX_PATHS[sfx_name]
		if ResourceLoader.exists(path):
			_streams[sfx_name] = load(path)
	for amb_name in AMBIENT_PATHS.keys():
		var path: String = AMBIENT_PATHS[amb_name]
		if ResourceLoader.exists(path):
			var stream = load(path)
			_enable_loop(stream)
			_streams[amb_name] = stream


func _enable_loop(stream: Variant) -> void:
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD


func _build_players() -> void:
	for i in range(SFX_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.name = "SfxPlayer_%d" % i
		add_child(player)
		_sfx_pool.append(player)

	for amb_name in AMBIENT_PATHS.keys():
		var player := AudioStreamPlayer.new()
		player.name = "Ambient_%s" % amb_name
		if _streams.has(amb_name):
			player.stream = _streams[amb_name]
		player.volume_db = -14.0 if amb_name == "rain" else -18.0
		add_child(player)
		_ambient_players[amb_name] = player


func _connect_game_state() -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs == null:
		return
	gs.folder_unlocked.connect(func(_folder: String): play_success())
	gs.location_decrypted.connect(_on_location_decrypted)
	gs.audio_record_completed.connect(_on_audio_record_completed)
	gs.bribe_triggered.connect(func(): play_notify())
	gs.phishing_triggered.connect(func(): play_error())
	gs.timer_started.connect(_on_timer_started)
	gs.timer_updated.connect(_on_timer_updated)
	gs.timer_expired.connect(func(): play_crt_poweroff())
	gs.game_ended.connect(_on_game_ended)
	if gs.has_signal("state_reset"):
		gs.state_reset.connect(stop_story_audio)


# ---------------------------------------------------------------------------
# Громкость и шина Master
# ---------------------------------------------------------------------------

## Установить общую громкость в диапазоне [0.0, 1.0].
func set_master_volume(volume: float) -> void:
	master_volume = clampf(volume, 0.0, 1.0)
	_apply_master_bus()
	volume_changed.emit(master_volume, is_muted)


## Включить или выключить звук глобально.
func set_muted(muted: bool) -> void:
	is_muted = muted
	_apply_master_bus()
	volume_changed.emit(master_volume, is_muted)


func toggle_mute() -> bool:
	set_muted(not is_muted)
	return is_muted


func get_volume_percent() -> int:
	return int(round(master_volume * 100.0))


func _apply_master_bus() -> void:
	var bus_idx := AudioServer.get_bus_index("Master")
	if bus_idx == -1:
		return
	var silent := is_muted or master_volume <= 0.001
	AudioServer.set_bus_mute(bus_idx, silent)
	if not silent:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(master_volume))


# ---------------------------------------------------------------------------
# Проверка наличия сэмплов и проигрывание SFX
# ---------------------------------------------------------------------------

func is_stream_loaded(sound_name: String) -> bool:
	return _streams.has(sound_name) and _streams[sound_name] != null


## Проиграть произвольный сэмпл из SFX_PATHS по имени.
func play_sfx(sfx_name: String, volume_db: float = 0.0, pitch_jitter: float = 0.0, base_pitch: float = 1.0) -> bool:
	if not _streams.has(sfx_name):
		push_warning("[AudioManager] Неизвестный сэмпл: %s" % sfx_name)
		return false

	last_sfx = sfx_name
	sfx_history.append(sfx_name)
	if sfx_history.size() > 64:
		sfx_history.pop_front()
	sfx_played.emit(sfx_name)

	if _is_headless() or is_muted:
		return true

	var player := _sfx_pool[_pool_cursor]
	_pool_cursor = (_pool_cursor + 1) % SFX_POOL_SIZE
	player.stream = _streams[sfx_name]
	player.volume_db = volume_db
	player.pitch_scale = maxf(0.25, base_pitch + (_rng.randf_range(-pitch_jitter, pitch_jitter) if pitch_jitter > 0.0 else 0.0))
	player.play()
	return true


func play_key_click() -> void:
	play_sfx("key_click", -5.0, 0.08, 1.0)


func play_mouse_click() -> void:
	play_sfx("mouse_click", -4.0, 0.03, 1.0)


func play_window_open() -> void:
	play_sfx("win_open", -4.0)


func play_window_close() -> void:
	play_sfx("win_close", -4.0)


func play_error() -> void:
	play_sfx("win_error", -2.0)


func play_notify() -> void:
	play_sfx("win_notify", -3.0)


func play_success() -> void:
	play_sfx("win_success", -2.0)


func play_crt_poweroff() -> void:
	play_sfx("crt_poweroff", -2.0)


func play_timer_pulse(urgent: bool = false) -> void:
	var vol := -1.0 if urgent else -4.0
	var pitch := 1.14 if urgent else 1.0
	play_sfx("timer_pulse", vol, 0.0, pitch)


func play_door_knock() -> void:
	play_sfx("door_knock", 0.0)


func play_gunshot() -> void:
	play_sfx("gunshot", 1.0)


# ---------------------------------------------------------------------------
# Зацикленные звуки и фоновая атмосфера (дождь + гул ЭЛТ)
# ---------------------------------------------------------------------------

## Запустить фоновые звуки ночного дождя и гула ЭЛТ-монитора.
func start_ambient() -> void:
	is_ambient_active = true
	if _is_headless():
		return
	for amb_name in _ambient_players.keys():
		var player: AudioStreamPlayer = _ambient_players[amb_name]
		if player.stream and not player.playing:
			player.play()


func stop_ambient() -> void:
	is_ambient_active = false
	for amb_name in _ambient_players.keys():
		var player: AudioStreamPlayer = _ambient_players[amb_name]
		if player.playing:
			player.stop()


## Запустить или остановить зацикленный SFX (например, шипение record.wav).
func play_loop_sfx(sfx_name: String, volume_db: float = -8.0) -> void:
	if not _streams.has(sfx_name):
		return
	var stream = _streams[sfx_name]
	_enable_loop(stream)
	if not _loop_players.has(sfx_name):
		var player := AudioStreamPlayer.new()
		player.name = "Loop_%s" % sfx_name
		add_child(player)
		_loop_players[sfx_name] = player
	var lp: AudioStreamPlayer = _loop_players[sfx_name]
	lp.stream = stream
	lp.volume_db = volume_db
	last_sfx = sfx_name
	sfx_played.emit(sfx_name)
	if not _is_headless() and not is_muted and not lp.playing:
		lp.play()


func stop_loop_sfx(sfx_name: String) -> void:
	if _loop_players.has(sfx_name):
		var lp: AudioStreamPlayer = _loop_players[sfx_name]
		if lp.playing:
			lp.stop()


## Последовательность концовки 4 («Незваный гость»): отключение ЭЛТ -> стук -> выстрел.
func play_horror_sequence() -> void:
	_horror_sequence_id += 1
	var seq_id := _horror_sequence_id
	play_crt_poweroff()
	if _is_headless() or not get_tree():
		return
	await get_tree().create_timer(0.9).timeout
	if seq_id != _horror_sequence_id:
		return
	play_door_knock()
	await get_tree().create_timer(5.3).timeout
	if seq_id != _horror_sequence_id:
		return
	play_gunshot()


## Остановить сюжетные разовые/зацикленные эффекты (при перезапуске сцены).
func stop_story_audio() -> void:
	_horror_sequence_id += 1
	_last_timer_second = -1
	for player in _sfx_pool:
		if player.playing:
			player.stop()
	for sfx_name in _loop_players.keys():
		stop_loop_sfx(sfx_name)


# ---------------------------------------------------------------------------
# Реакция на события GameState
# ---------------------------------------------------------------------------

func _on_location_decrypted() -> void:
	play_success()
	play_crt_poweroff()


func _on_audio_record_completed() -> void:
	stop_loop_sfx("record_static")
	play_notify()


func _on_timer_started(duration: float) -> void:
	_last_timer_second = int(ceil(duration))
	play_timer_pulse(false)


func _on_timer_updated(time_left: float) -> void:
	var sec := int(ceil(time_left))
	if sec > 0 and sec < _last_timer_second:
		_last_timer_second = sec
		play_timer_pulse(time_left <= 15.0)


func _on_game_ended(ending_id: int, _details: Dictionary) -> void:
	stop_loop_sfx("record_static")
	match ending_id:
		1:
			play_success()
		2, 3:
			play_error()
		4:
			play_horror_sequence()
		5:
			play_crt_poweroff()


func _is_headless() -> bool:
	return DisplayServer.get_name() == "headless"
