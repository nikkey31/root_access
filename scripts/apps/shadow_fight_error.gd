class_name ShadowFightError
extends Control

## Битый ярлык shadow_fight_1.exe.
## Показывает классическую ошибку RetroOS/Win98 и запускает мысль Ника.

const ERROR_TEXT := "Невозможно запустить игру: критические файлы ресурсов повреждены (CRC Error 0x8004F012)"
const DETAILS_TEXT := "Модуль: SHADOW.EXE\nКонтрольная сумма: CRC 0x8004F012\nПовреждённых секторов: 3\nИсточник: C:\\ROOT_ACCESS\\Игры\\shadow_fight_1.exe\n\nФайл повреждён или несовместим с текущей версией RetroOS."

var _details_panel: PanelContainer
var _details_visible: bool = false
var _ok_button: Button
var _details_button: Button


func _ready() -> void:
	_build_ui()
	if GameState:
		GameState.mark_shadow_fight_error()
	_play_audio("play_error")


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color(0.75, 0.75, 0.75, 1.0)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 6)
	margin.add_child(outer)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	outer.add_child(top)

	var icon := ErrorIcon.new()
	icon.custom_minimum_size = Vector2(54, 54)
	icon.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(icon)

	var message_column := VBoxContainer.new()
	message_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	message_column.add_theme_constant_override("separation", 2)
	top.add_child(message_column)

	var title := Label.new()
	title.text = "Ошибка приложения"
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(0.05, 0.05, 0.05))
	title.add_theme_color_override("font_shadow_color", Color(1, 1, 1, 0.7))
	title.add_theme_constant_override("shadow_offset_x", 1)
	title.add_theme_constant_override("shadow_offset_y", 1)
	message_column.add_child(title)

	var message := Label.new()
	message.text = ERROR_TEXT
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_font_size_override("font_size", 11)
	message.add_theme_color_override("font_color", Color(0.08, 0.08, 0.08))
	message_column.add_child(message)

	var app_label := Label.new()
	app_label.text = "Приложение: shadow_fight_1.exe"
	app_label.add_theme_font_size_override("font_size", 10)
	app_label.add_theme_color_override("font_color", Color(0.28, 0.28, 0.28))
	message_column.add_child(app_label)

	_details_panel = PanelContainer.new()
	_details_panel.visible = false
	_details_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.95, 0.94, 0.88), Color(0.38, 0.38, 0.34)))
	outer.add_child(_details_panel)
	var details_margin := MarginContainer.new()
	details_margin.add_theme_constant_override("margin_left", 6)
	details_margin.add_theme_constant_override("margin_top", 4)
	details_margin.add_theme_constant_override("margin_right", 6)
	details_margin.add_theme_constant_override("margin_bottom", 4)
	_details_panel.add_child(details_margin)
	var details := Label.new()
	details.text = DETAILS_TEXT
	details.add_theme_font_size_override("font_size", 9)
	details.add_theme_color_override("font_color", Color(0.15, 0.15, 0.15))
	details_margin.add_child(details)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer.add_child(spacer)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	buttons.add_theme_constant_override("separation", 6)
	outer.add_child(buttons)

	_details_button = Button.new()
	_details_button.text = "Подробнее..."
	_details_button.custom_minimum_size = Vector2(100, 26)
	_details_button.focus_mode = Control.FOCUS_NONE
	_details_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_details_button.pressed.connect(_toggle_details)
	buttons.add_child(_details_button)

	_ok_button = Button.new()
	_ok_button.text = "ОК"
	_ok_button.custom_minimum_size = Vector2(72, 26)
	_ok_button.focus_mode = Control.FOCUS_NONE
	_ok_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_ok_button.pressed.connect(_close_window)
	buttons.add_child(_ok_button)

	var hint := Label.new()
	hint.text = "Совет RetroOS: проверьте целостность файлов командой chkdsk."
	hint.add_theme_font_size_override("font_size", 9)
	hint.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
	outer.add_child(hint)


func _toggle_details() -> void:
	_details_visible = not _details_visible
	_details_panel.visible = _details_visible
	_details_button.text = "Свернуть" if _details_visible else "Подробнее..."
	_play_audio("play_mouse_click")


func _close_window() -> void:
	var node: Node = self
	while node != null:
		if node is WindowFrame:
			(node as WindowFrame).close()
			return
		node = node.get_parent()
	visible = false


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


func _play_audio(method_name: String) -> void:
	var am := get_node_or_null("/root/AudioManager")
	if am and am.has_method(method_name):
		am.call(method_name)


## --- Публичный API для автотестов ------------------------------------------

func get_error_text() -> String:
	return ERROR_TEXT


func get_details_text() -> String:
	return DETAILS_TEXT


func is_details_visible() -> bool:
	return _details_visible


func press_ok() -> void:
	_close_window()


class ErrorIcon extends Control:
	func _draw() -> void:
		var radius := minf(size.x, size.y) * 0.42
		if radius <= 0.0:
			return
		var center := size * 0.5
		draw_circle(center, radius, Color(0.55, 0.02, 0.02, 1.0))
		draw_circle(center, radius * 0.9, Color(0.82, 0.08, 0.08, 1.0))
		draw_circle(center, radius * 0.75, Color(0.95, 0.95, 0.9, 1.0))
		draw_line(center + Vector2(-radius * 0.4, -radius * 0.4), center + Vector2(radius * 0.4, radius * 0.4), Color(0.8, 0.05, 0.05, 1.0), 5.0)
		draw_line(center + Vector2(-radius * 0.4, radius * 0.4), center + Vector2(radius * 0.4, -radius * 0.4), Color(0.8, 0.05, 0.05, 1.0), 5.0)
