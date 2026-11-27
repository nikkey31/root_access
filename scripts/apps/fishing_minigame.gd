class_name FishingMinigame
extends Control

## Ретро-рыбалка из папки «Игры».
##
## Цикл: заброс -> ожидание -> поклёвка (нужно вовремя подсечь) -> вываживание
## с балансом натяжения лески. После трёх рыб на крючок попадает старый кейс
## с запиской, содержащей фрагмент ключа дешифрования.

enum State { IDLE, CASTING, WAITING, BITE, FIGHT, CAUGHT, TREASURE, BROKEN }

const FISH_TO_CASE: int = 3
const SAFE_MIN: float = 28.0
const SAFE_MAX: float = 80.0
const BITE_WINDOW: float = 1.9
const CAST_DURATION: float = 0.55

const ICON_BOBBER := preload("res://assets/icons/games/fishing/bobber.png")
const ICON_HOOK := preload("res://assets/icons/games/fishing/hook.png")
const ICON_CASE := preload("res://assets/icons/lock.svg")

const FISH_DATA := [
	{
		"name": "Карась",
		"weight": 0.42,
		"texture": preload("res://assets/icons/games/fishing/fish_crucian.png"),
	},
	{
		"name": "Окунь",
		"weight": 0.87,
		"texture": preload("res://assets/icons/games/fishing/fish_perch.png"),
	},
	{
		"name": "Щука",
		"weight": 2.60,
		"texture": preload("res://assets/icons/games/fishing/fish_pike.png"),
	},
	{
		"name": "Редкий трофей",
		"weight": 4.10,
		"texture": preload("res://assets/icons/games/fishing/fish_rare.png"),
	},
]

var _state: int = State.IDLE
var _state_time: float = 0.0
var _wait_duration: float = 2.0
var _bite_timer: float = 0.0
var _cast_t: float = 0.0
var _bobber_uv: Vector2 = Vector2(0.62, 0.66)
var _tension: float = 40.0
var _reel_progress: float = 0.0
var _line_break_timer: float = 0.0
var _reeling: bool = false
var _catches: int = 0
var _key_found: bool = false
var _last_fish: Dictionary = {}
var _catch_log: Array[String] = []

var _lake_view: LakeView
var _tension_meter: TensionMeter
var _status_label: Label
var _hint_label: Label
var _count_label: Label
var _tension_value_label: Label
var _catch_label: Label
var _action_button: Button
var _reset_button: Button
var _reward_icon: TextureRect


func _ready() -> void:
	if GameState:
		_catches = GameState.fishing_catch_count
		_key_found = GameState.has_game_key_fragment
	_build_ui()
	_set_state(State.IDLE)
	_refresh_catch_label()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color(0.75, 0.75, 0.75, 1.0)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	add_child(margin)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 4)
	margin.add_child(outer)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	outer.add_child(header)

	var title := Label.new()
	title.text = "СИМУЛЯТОР СПОРТИВНОЙ РЫБАЛКИ  v1.4"
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", Color(0.08, 0.12, 0.08))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	_count_label = Label.new()
	_count_label.text = "Улов: 0"
	_count_label.add_theme_font_size_override("font_size", 11)
	_count_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))
	header.add_child(_count_label)

	_lake_view = LakeView.new()
	_lake_view.game = self
	_lake_view.custom_minimum_size = Vector2(0, 210)
	_lake_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lake_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lake_view.clip_contents = true
	outer.add_child(_lake_view)

	var status_panel := PanelContainer.new()
	status_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.93, 0.91, 0.82), Color(0.35, 0.35, 0.3)))
	outer.add_child(status_panel)
	var status_margin := MarginContainer.new()
	status_margin.add_theme_constant_override("margin_left", 6)
	status_margin.add_theme_constant_override("margin_top", 4)
	status_margin.add_theme_constant_override("margin_right", 6)
	status_margin.add_theme_constant_override("margin_bottom", 4)
	status_panel.add_child(status_margin)
	_status_label = Label.new()
	_status_label.text = "Забрось удочку и жди поклёвки."
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.custom_minimum_size = Vector2(0, 30)
	_status_label.add_theme_font_size_override("font_size", 11)
	_status_label.add_theme_color_override("font_color", Color(0.08, 0.08, 0.06))
	status_margin.add_child(_status_label)

	var tension_row := HBoxContainer.new()
	tension_row.add_theme_constant_override("separation", 6)
	outer.add_child(tension_row)
	var tension_caption := Label.new()
	tension_caption.text = "Натяжение лески:"
	tension_caption.add_theme_font_size_override("font_size", 10)
	tension_caption.add_theme_color_override("font_color", Color(0.18, 0.18, 0.18))
	tension_row.add_child(tension_caption)
	_tension_meter = TensionMeter.new()
	_tension_meter.custom_minimum_size = Vector2(0, 14)
	_tension_meter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tension_meter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_tension_meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tension_row.add_child(_tension_meter)
	_tension_value_label = Label.new()
	_tension_value_label.text = "40%"
	_tension_value_label.custom_minimum_size = Vector2(38, 0)
	_tension_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_tension_value_label.add_theme_font_size_override("font_size", 10)
	tension_row.add_child(_tension_value_label)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 6)
	outer.add_child(actions)
	_action_button = Button.new()
	_action_button.text = "Забросить удочку"
	_action_button.custom_minimum_size = Vector2(0, 30)
	_action_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_action_button.focus_mode = Control.FOCUS_NONE
	_action_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_action_button.pressed.connect(_on_action_pressed)
	_action_button.button_down.connect(_on_action_button_down)
	_action_button.button_up.connect(_on_action_button_up)
	actions.add_child(_action_button)

	_reset_button = Button.new()
	_reset_button.text = "Сброс"
	_reset_button.custom_minimum_size = Vector2(72, 30)
	_reset_button.focus_mode = Control.FOCUS_NONE
	_reset_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_reset_button.pressed.connect(reset_minigame)
	actions.add_child(_reset_button)

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 6)
	outer.add_child(bottom)

	_reward_icon = TextureRect.new()
	_reward_icon.texture = ICON_HOOK
	_reward_icon.custom_minimum_size = Vector2(20, 20)
	_reward_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_reward_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_reward_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.add_child(_reward_icon)

	var text_column := VBoxContainer.new()
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_column.add_theme_constant_override("separation", 0)
	bottom.add_child(text_column)

	_catch_label = Label.new()
	_catch_label.text = "В ведре пусто."
	_catch_label.add_theme_font_size_override("font_size", 10)
	_catch_label.add_theme_color_override("font_color", Color(0.15, 0.2, 0.15))
	_catch_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_column.add_child(_catch_label)

	_hint_label = Label.new()
	_hint_label.text = "Когда поплавок дёрнется — жми «Подсечь». Потом удерживай натяжение в зелёной зоне."
	_hint_label.add_theme_font_size_override("font_size", 9)
	_hint_label.add_theme_color_override("font_color", Color(0.28, 0.28, 0.28))
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_column.add_child(_hint_label)


func _process(delta: float) -> void:
	match _state:
		State.CASTING:
			_cast_t = minf(1.0, _cast_t + delta / CAST_DURATION)
			if _cast_t >= 1.0:
				_enter_waiting()
		State.WAITING:
			_state_time += delta
			if _state_time >= _wait_duration:
				_enter_bite()
		State.BITE:
			_bite_timer -= delta
			if _bite_timer <= 0.0:
				_miss_bite()
		State.FIGHT:
			_update_fight(delta)

	if _lake_view:
		_lake_view.queue_redraw()
	if _tension_meter:
		_tension_meter.value = _tension
		_tension_meter.active = (_state == State.FIGHT)
		_tension_meter.queue_redraw()
	if _tension_value_label:
		_tension_value_label.text = "%d%%" % int(round(_tension))
	if _status_label:
		if _state == State.BITE:
			var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 95.0)
			_status_label.modulate = Color(1.0, 0.75, 0.75).lerp(Color(1, 1, 1), pulse)
		elif _state == State.FIGHT:
			_status_label.modulate = Color(0.92, 1.0, 0.92)
		else:
			_status_label.modulate = Color.WHITE


func _set_state(new_state: int) -> void:
	_state = new_state
	_state_time = 0.0
	_refresh_controls()


func _refresh_controls() -> void:
	if _action_button == null:
		return
	_action_button.disabled = false
	match _state:
		State.IDLE:
			_action_button.text = "Забросить удочку"
			_status_label.text = "Берег тихий. Только дождь стучит по воде."
		State.CASTING:
			_action_button.text = "Заброс..."
			_action_button.disabled = true
			_status_label.text = "Леска уходит в темноту..."
		State.WAITING:
			_action_button.text = "Ждём поклёвки..."
			_action_button.disabled = true
			_status_label.text = "Поплавок покачивается на воде."
		State.BITE:
			_action_button.text = "ПОДСЕЧЬ!"
			_status_label.text = "ПОКЛЁВКА! Подсекай, пока не ушла!"
			_hint_label.text = "Успей нажать «Подсечь» в течение пары секунд."
		State.FIGHT:
			_action_button.text = "Тянуть (удерживать)"
			_status_label.text = "Есть! Держи натяжение в зелёной зоне."
			_hint_label.text = "Удерживай ЛКМ на кнопке или ПРОБЕЛ. Отпускай, когда леска перетянута."
		State.CAUGHT:
			_action_button.text = "Забросить снова"
		State.TREASURE:
			_action_button.text = "Забросить снова"
		State.BROKEN:
			_action_button.text = "Забросить снова"


func _on_action_pressed() -> void:
	match _state:
		State.IDLE, State.CAUGHT, State.TREASURE, State.BROKEN:
			_start_cast()
		State.BITE:
			_hook_fish()
		_:
			pass


func _on_action_button_down() -> void:
	if _state == State.FIGHT:
		_reeling = true


func _on_action_button_up() -> void:
	_reeling = false


func _start_cast() -> void:
	_reeling = false
	_reel_progress = 0.0
	_tension = 40.0
	_line_break_timer = 0.0
	_cast_t = 0.0
	_bobber_uv = Vector2(randf_range(0.55, 0.82), randf_range(0.58, 0.74))
	_last_fish = {}
	_reward_icon.texture = ICON_HOOK
	_set_state(State.CASTING)
	_play_audio("play_mouse_click")


func _enter_waiting() -> void:
	_wait_duration = randf_range(1.1, 2.3)
	_set_state(State.WAITING)
	_status_label.text = "Поплавок покачивается на воде..."


func _enter_bite() -> void:
	_bite_timer = BITE_WINDOW
	_set_state(State.BITE)
	_play_audio("play_notify")


func _miss_bite() -> void:
	_set_state(State.BROKEN)
	_status_label.text = "Сорвалась. Слишком поздно подсек."
	_hint_label.text = "В следующий раз жми «Подсечь» сразу после всплеска."


func _hook_fish() -> void:
	_tension = 42.0
	_reel_progress = 0.0
	_line_break_timer = 0.0
	_reeling = false
	_set_state(State.FIGHT)
	_play_audio("play_notify")


func _update_fight(delta: float) -> void:
	var pulling := _reeling or Input.is_key_pressed(KEY_SPACE)
	if pulling:
		_tension += 55.0 * delta
	else:
		_tension -= 38.0 * delta
	_tension = clampf(_tension, 0.0, 100.0)

	if _tension >= 94.0:
		_line_break_timer += delta
	else:
		_line_break_timer = 0.0
	if _line_break_timer >= 0.55:
		_break_line()
		return

	if _tension >= SAFE_MIN and _tension <= SAFE_MAX:
		_reel_progress += 30.0 * delta
	elif _tension > SAFE_MAX:
		_reel_progress -= 8.0 * delta
	else:
		_reel_progress -= 3.0 * delta
	_reel_progress = clampf(_reel_progress, 0.0, 100.0)

	if _reel_progress >= 100.0:
		_complete_catch()


func _break_line() -> void:
	_reeling = false
	_reel_progress = 0.0
	_tension = 20.0
	_set_state(State.BROKEN)
	_status_label.text = "Леска лопнула! Слишком сильное натяжение."
	_hint_label.text = "Отпускай кнопку раньше, чем индикатор дойдёт до красной зоны."
	_play_audio("play_error")


func _complete_catch() -> void:
	if _catches >= FISH_TO_CASE and not _key_found:
		_catch_treasure()
		return

	var fish: Dictionary = FISH_DATA[randi() % FISH_DATA.size()]
	_last_fish = fish
	_catches += 1
	if GameState:
		GameState.register_fishing_catch(str(fish["name"]))
		_catches = GameState.fishing_catch_count
	var weight_text := ("%.2f" % float(fish["weight"])).replace(".", ",")
	_catch_log.append("%s — %s кг" % [fish["name"], weight_text])
	_refresh_catch_label()
	_reward_icon.texture = fish["texture"]
	_set_state(State.CAUGHT)
	_status_label.text = "Пойман %s! Вес: %s кг." % [fish["name"], weight_text]
	_hint_label.text = "Заброс снова. Чем больше улова, тем интереснее находки на дне."
	_play_audio("play_success")

	if _catches >= FISH_TO_CASE and not _key_found:
		_status_label.text = "Три рыбы в ведре. Но что-то тяжёлое ещё висит на крючке..."
		_hint_label.text = "Следующий заброс вытащит странную находку."


func _catch_treasure() -> void:
	_key_found = true
	_catch_log.append("Старый кейс — записка с фрагментом «LENINA»")
	_refresh_catch_label()
	_reward_icon.texture = ICON_CASE
	_set_state(State.TREASURE)
	_status_label.text = "Из воды поднят старый ржавый кейс! Внутри записка: «…LENINA…»"
	_hint_label.text = "Фрагмент ключа сохранён в деле. Осталось найти вторую часть."
	_play_audio("play_success")
	if GameState:
		GameState.find_game_key_fragment("LENINA")


func _refresh_catch_label() -> void:
	if _count_label == null:
		return
	_count_label.text = "Улов: %d" % _catches
	if _catch_label == null:
		return
	if _catch_log.is_empty():
		_catch_label.text = "В ведре пусто. Пока что."
	else:
		_catch_label.text = "В ведре: " + ", ".join(_catch_log)


func reset_minigame() -> void:
	_reeling = false
	_catches = 0
	_key_found = false
	_catch_log.clear()
	_last_fish = {}
	_tension = 40.0
	_reel_progress = 0.0
	_bobber_uv = Vector2(0.62, 0.66)
	if GameState:
		GameState.fishing_catch_count = 0
	_reward_icon.texture = ICON_HOOK
	_refresh_catch_label()
	_set_state(State.IDLE)


## --- Публичные геттеры для автотестов ---------------------------------------

func get_state() -> int:
	return _state


func get_state_name() -> String:
	match _state:
		State.IDLE: return "IDLE"
		State.CASTING: return "CASTING"
		State.WAITING: return "WAITING"
		State.BITE: return "BITE"
		State.FIGHT: return "FIGHT"
		State.CAUGHT: return "CAUGHT"
		State.TREASURE: return "TREASURE"
		State.BROKEN: return "BROKEN"
	return "UNKNOWN"


func get_catch_count() -> int:
	return _catches


func get_tension() -> float:
	return _tension


func get_reel_progress() -> float:
	return _reel_progress


func is_key_found() -> bool:
	return _key_found


func get_bobber_texture() -> Texture2D:
	return ICON_BOBBER


func is_line_visible() -> bool:
	return _state == State.CASTING or _state == State.WAITING or _state == State.BITE or _state == State.FIGHT


func get_bobber_uv() -> Vector2:
	return _bobber_uv


func get_cast_t() -> float:
	return _cast_t


func _play_audio(method_name: String) -> void:
	var am := get_node_or_null("/root/AudioManager")
	if am and am.has_method(method_name):
		am.call(method_name)


func _make_panel_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = border
	style.content_margin_left = 4.0
	style.content_margin_top = 2.0
	style.content_margin_right = 4.0
	style.content_margin_bottom = 2.0
	return style


# ---------------------------------------------------------------------------
# Отрисовка озера
# ---------------------------------------------------------------------------

class LakeView extends Control:
	var game: FishingMinigame

	func _draw() -> void:
		var w := size.x
		var h := size.y
		if w < 4.0 or h < 4.0:
			return

		var horizon := h * 0.53
		draw_rect(Rect2(0, 0, w, horizon), Color(0.045, 0.075, 0.145, 1))
		draw_rect(Rect2(0, horizon, w, h - horizon), Color(0.055, 0.19, 0.26, 1))

		# Луна и звёзды.
		var moon_pos := Vector2(w * 0.82, h * 0.16)
		var moon_r := minf(w, h) * 0.055
		draw_circle(moon_pos, moon_r, Color(0.86, 0.88, 0.74, 1))
		draw_circle(moon_pos + Vector2(moon_r * 0.34, -moon_r * 0.22), moon_r * 0.88, Color(0.045, 0.075, 0.145, 1))
		var stars := [
			Vector2(0.08, 0.12), Vector2(0.18, 0.22), Vector2(0.29, 0.09),
			Vector2(0.39, 0.18), Vector2(0.52, 0.11), Vector2(0.64, 0.24),
			Vector2(0.73, 0.08), Vector2(0.91, 0.27), Vector2(0.95, 0.13),
		]
		for star in stars:
			draw_rect(Rect2(Vector2(star.x * w, star.y * h), Vector2(2, 2)), Color(0.75, 0.8, 0.86, 0.8))

		# Дальний берег и отражение луны.
		draw_rect(Rect2(0, horizon - 7, w, 7), Color(0.025, 0.04, 0.045, 1))
		for i in range(1, 9):
			var ripple_y := horizon + (h - horizon) * float(i) / 9.0
			draw_line(Vector2(w * 0.08, ripple_y), Vector2(w * 0.92, ripple_y), Color(0.11, 0.31, 0.4, 0.5), 1.0)
		for i in range(5):
			var ry := horizon + 8.0 + float(i) * 8.0
			var half := (moon_r * 0.7) * (1.0 - float(i) * 0.14)
			draw_line(Vector2(moon_pos.x - half, ry), Vector2(moon_pos.x + half, ry), Color(0.65, 0.68, 0.56, 0.28), 2.0)

		# Камыш по краям.
		for i in range(7):
			var rx := 12.0 + float(i) * 8.0
			var rh := 26.0 + float((i * 7) % 17)
			draw_line(Vector2(rx, h * 0.82), Vector2(rx - 5.0, h * 0.82 - rh), Color(0.08, 0.12, 0.07, 1), 2.0)
		for i in range(6):
			var rx := w - 14.0 - float(i) * 9.0
			var rh := 20.0 + float((i * 11) % 20)
			draw_line(Vector2(rx, h * 0.86), Vector2(rx + 4.0, h * 0.86 - rh), Color(0.08, 0.12, 0.07, 1), 2.0)

		# Пирс и рыбак.
		var dock_y := h * 0.72
		draw_rect(Rect2(0, dock_y, w * 0.30, 6), Color(0.24, 0.15, 0.08, 1))
		draw_rect(Rect2(0, dock_y + 6, w * 0.30, 3), Color(0.13, 0.08, 0.05, 1))
		draw_rect(Rect2(w * 0.18, dock_y + 6, 5, h - dock_y - 6), Color(0.14, 0.09, 0.05, 1))

		var fisherman_x := w * 0.16
		draw_rect(Rect2(fisherman_x - 7, dock_y - 30, 14, 30), Color(0.025, 0.025, 0.03, 1))
		draw_circle(Vector2(fisherman_x, dock_y - 37), 8.0, Color(0.025, 0.025, 0.03, 1))
		draw_rect(Rect2(fisherman_x - 10, dock_y - 42, 20, 5), Color(0.02, 0.02, 0.02, 1))
		draw_line(Vector2(fisherman_x + 6, dock_y - 28), Vector2(fisherman_x + 36, dock_y - 62), Color(0.48, 0.35, 0.2, 1), 2.5)

		if game == null or not game.is_line_visible():
			return

		var tip := Vector2(fisherman_x + 36, dock_y - 62)
		var bobber := _get_bobber_point()
		if game.get_state() == FishingMinigame.State.BITE or game.get_state() == FishingMinigame.State.WAITING:
			bobber.y += sin(Time.get_ticks_msec() / 180.0) * 2.5
		if game.get_state() == FishingMinigame.State.BITE:
			bobber.y += sin(Time.get_ticks_msec() / 45.0) * 4.0
			var wave := 8.0 + sin(Time.get_ticks_msec() / 160.0) * 3.0
			draw_circle(bobber + Vector2(0, 4), wave, Color(0.75, 0.85, 0.95, 0.18))
			draw_circle(bobber + Vector2(0, 4), wave * 0.55, Color(0.8, 0.9, 1.0, 0.22))

		draw_line(tip, bobber, Color(0.85, 0.85, 0.8, 0.9), 1.0)
		var tex := game.get_bobber_texture()
		if tex:
			draw_texture_rect(tex, Rect2(bobber - Vector2(12, 13), Vector2(24, 26)), false)

		if game.get_state() == FishingMinigame.State.FIGHT:
			var fish_x := bobber.x + sin(Time.get_ticks_msec() / 220.0) * 16.0
			var fish_y := bobber.y + 22.0
			draw_circle(Vector2(fish_x, fish_y), 9.0, Color(0.02, 0.08, 0.1, 0.55))
			draw_line(Vector2(fish_x - 11, fish_y), Vector2(fish_x + 11, fish_y), Color(0.02, 0.08, 0.1, 0.55), 3.0)

	func _get_bobber_point() -> Vector2:
		if game == null:
			return size * 0.5
		var dock_y := size.y * 0.72
		var start := Vector2(size.x * 0.16 + 36.0, dock_y - 62.0)
		var target := Vector2(game.get_bobber_uv().x * size.x, game.get_bobber_uv().y * size.y)
		var t := 1.0
		if game.get_state() == FishingMinigame.State.CASTING:
			t = clampf(game.get_cast_t(), 0.0, 1.0)
		var point := start.lerp(target, t)
		point.y -= sin(t * PI) * size.y * 0.18
		return point


# ---------------------------------------------------------------------------
# Индикатор натяжения лески
# ---------------------------------------------------------------------------

class TensionMeter extends Control:
	var value: float = 40.0
	var active: bool = false

	func _draw() -> void:
		var w := size.x
		var h := size.y
		if w < 2.0 or h < 2.0:
			return
		draw_rect(Rect2(0, 0, w, h), Color(0.12, 0.12, 0.12, 1))
		var safe_left := w * FishingMinigame.SAFE_MIN / 100.0
		var safe_width := w * (FishingMinigame.SAFE_MAX - FishingMinigame.SAFE_MIN) / 100.0
		draw_rect(Rect2(0, 2, w, h - 4), Color(0.42, 0.12, 0.1, 1))
		draw_rect(Rect2(safe_left, 2, safe_width, h - 4), Color(0.12, 0.48, 0.16, 1))
		for i in range(1, 10):
			var x := w * float(i) / 10.0
			draw_line(Vector2(x, 0), Vector2(x, h), Color(0, 0, 0, 0.35), 1.0)
		var marker_x := w * clampf(value, 0.0, 100.0) / 100.0
		draw_rect(Rect2(clampf(marker_x - 1.5, 0, w - 3), 0, 3, h), Color(1.0, 0.92, 0.25, 1))
		if active:
			draw_rect(Rect2(0, 0, w, h), Color(1, 1, 1, 0.18), false, 1.0)
