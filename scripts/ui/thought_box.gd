class_name ThoughtBox
extends Control

## Панель внутренних мыслей Ника Будхайма в стиле визуальных новелл.
## Поддерживает посимвольную печать, очередь мыслей, двухкликовое управление
## (1-й клик допечатывает, 2-й закрывает) и компактный верхний режим во время
## финального 60-секундного таймера.

signal thought_shown(text: String)
signal thought_closed(text: String)
signal queue_emptied()

@export var chars_per_second: float = 48.0
@export var speaker_name: String = "Ник Будхайм"

@onready var click_catcher: Control = $ClickCatcher
@onready var panel: PanelContainer = $BoxPanel
@onready var speaker_label: Label = $BoxPanel/Margin/VBox/HeaderRow/SpeakerLabel
@onready var hint_label: Label = $BoxPanel/Margin/VBox/HeaderRow/HintLabel
@onready var body_label: Label = $BoxPanel/Margin/VBox/BodyLabel

var _queue: Array[String] = []
var _current_text: String = ""
var _is_showing: bool = false
var _is_typing: bool = false
var _typed_chars: float = 0.0
var _compact_top_mode: bool = false

func _ready() -> void:
	visible = false
	speaker_label.text = speaker_name
	click_catcher.gui_input.connect(_on_panel_or_screen_input)
	panel.gui_input.connect(_on_panel_or_screen_input)
	_apply_layout_mode()

func enqueue_thought(text: String) -> void:
	var cleaned := text.strip_edges()
	if cleaned.is_empty():
		return
	if _is_showing:
		_queue.append(cleaned)
		return
	_show_text(cleaned)

func clear_thoughts() -> void:
	_queue.clear()
	_current_text = ""
	_is_showing = false
	_is_typing = false
	_typed_chars = 0.0
	visible = false

func is_active() -> bool:
	return _is_showing

func is_typing() -> bool:
	return _is_typing

func get_current_text() -> String:
	return _current_text

func is_compact_top_mode() -> bool:
	return _compact_top_mode

func set_compact_top_mode(enabled: bool) -> void:
	_compact_top_mode = enabled
	_apply_layout_mode()

## Программный эквивалент клика (1-й вызов допечатывает, 2-й закрывает).
func advance_interaction() -> void:
	if not _is_showing:
		return
	if _is_typing:
		_finish_typing_immediately()
	else:
		_close_current()

func _show_text(text: String) -> void:
	_current_text = text
	_is_showing = true
	_is_typing = true
	_typed_chars = 0.0
	body_label.text = text
	body_label.visible_characters = 0
	hint_label.text = "[клик — допечатать]"
	visible = true
	_apply_layout_mode()
	thought_shown.emit(text)

func _finish_typing_immediately() -> void:
	_is_typing = false
	_typed_chars = float(_current_text.length())
	body_label.visible_characters = -1
	hint_label.text = "[клик — далее]"

func _close_current() -> void:
	var closed := _current_text
	_is_showing = false
	_is_typing = false
	_current_text = ""
	thought_closed.emit(closed)
	if not _queue.is_empty():
		var next_text: String = _queue.pop_front()
		_show_text(next_text)
	else:
		visible = false
		queue_emptied.emit()

func _process(delta: float) -> void:
	if not _is_showing or not _is_typing:
		return
	_typed_chars += chars_per_second * delta
	var count := int(_typed_chars)
	if count >= _current_text.length():
		_finish_typing_immediately()
	else:
		body_label.visible_characters = count

func _on_panel_or_screen_input(event: InputEvent) -> void:
	if not _is_showing:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			advance_interaction()
			get_viewport().set_input_as_handled()

func _unhandled_key_input(event: InputEvent) -> void:
	if not _is_showing:
		return
	if event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and not key.echo and (key.keycode == KEY_SPACE or key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER or key.keycode == KEY_ESCAPE):
			advance_interaction()
			get_viewport().set_input_as_handled()

func _apply_layout_mode() -> void:
	if not is_node_ready():
		return
	if _compact_top_mode:
		# Во время 60-секундного таймера не перехватываем клики по Карте,
		# а саму плашку прижимаем к верхнему краю под полоской таймера.
		click_catcher.visible = false
		click_catcher.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.anchor_left = 0.14
		panel.anchor_right = 0.86
		panel.anchor_top = 0.0
		panel.anchor_bottom = 0.0
		panel.offset_left = 0.0
		panel.offset_right = 0.0
		panel.offset_top = 54.0
		panel.offset_bottom = 132.0
		body_label.add_theme_font_size_override("font_size", 13)
	else:
		click_catcher.visible = true
		click_catcher.mouse_filter = Control.MOUSE_FILTER_STOP
		panel.anchor_left = 0.12
		panel.anchor_right = 0.88
		panel.anchor_top = 1.0
		panel.anchor_bottom = 1.0
		panel.offset_left = 0.0
		panel.offset_right = 0.0
		panel.offset_top = -182.0
		panel.offset_bottom = -64.0
		body_label.add_theme_font_size_override("font_size", 15)
