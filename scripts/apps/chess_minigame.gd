class_name ChessMinigame
extends Control

## Ретро-шахматы «GNU Chess 98 v4.1» из папки «Игры».
##
## Это эндшпиль-задачка «мат в 2 хода» из незаконченной партии Саймона.
## Доска 8x8, фигуры из спрайтов, история ходов с пасхалкой в нотации.

const PUZZLE_FEN := "r1k4r/1q1nQ1p1/3B2p1/2n5/p5P1/P6P/5P2/2KRR3 w - - 2 30"
const EXPECTED_FROM := ["e7", "e1"]
const EXPECTED_TO := ["e8", "e8"]

const LIGHT_SQUARE := Color(0.91, 0.84, 0.68, 1.0)
const DARK_SQUARE := Color(0.53, 0.39, 0.25, 1.0)
const SELECTED_BORDER := Color(1.0, 0.84, 0.12, 1.0)
const TARGET_BORDER := Color(0.08, 0.58, 0.18, 1.0)
const CHESS_DIR := "res://assets/icons/games/chess/"

const PIECE_TEXTURES := {
	"w_king": preload("res://assets/icons/games/chess/white_king.png"),
	"w_queen": preload("res://assets/icons/games/chess/white_queen.png"),
	"w_rook": preload("res://assets/icons/games/chess/white_rook.png"),
	"w_bishop": preload("res://assets/icons/games/chess/white_bishop.png"),
	"w_knight": preload("res://assets/icons/games/chess/white_knight.png"),
	"w_pawn": preload("res://assets/icons/games/chess/white_pawn.png"),
	"b_king": preload("res://assets/icons/games/chess/black_king.png"),
	"b_queen": preload("res://assets/icons/games/chess/black_queen.png"),
	"b_rook": preload("res://assets/icons/games/chess/black_rook.png"),
	"b_bishop": preload("res://assets/icons/games/chess/black_bishop.png"),
	"b_knight": preload("res://assets/icons/games/chess/black_knight.png"),
	"b_pawn": preload("res://assets/icons/games/chess/black_pawn.png"),
}

const KIND_NAMES := {
	"k": "king",
	"q": "queen",
	"r": "rook",
	"b": "bishop",
	"n": "knight",
	"p": "pawn",
}

var _board: Dictionary = {}
var _cells: Array[Button] = []
var _cell_pieces: Array[TextureRect] = []
var _selected_square: String = ""
var _valid_target: String = ""
var _stage: int = 0
var _solved: bool = false
var _history_text: String = ""

var _board_grid: GridContainer
var _history_label: RichTextLabel
var _status_label: Label
var _stage_label: Label
var _hint_button: Button
var _reset_button: Button


func _ready() -> void:
	_build_ui()
	_reset_puzzle()


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
	title.text = "ШАХМАТЫ — GNU Chess 98 v4.1"
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", Color(0.08, 0.12, 0.08))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	_stage_label = Label.new()
	_stage_label.text = "Задача: мат в 2 хода"
	_stage_label.add_theme_font_size_override("font_size", 10)
	_stage_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))
	header.add_child(_stage_label)

	var content := HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 6)
	outer.add_child(content)

	var board_panel := PanelContainer.new()
	board_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.31, 0.24, 0.17), Color(0.1, 0.08, 0.06)))
	content.add_child(board_panel)
	var board_center := CenterContainer.new()
	board_panel.add_child(board_center)
	_board_grid = GridContainer.new()
	_board_grid.columns = 8
	_board_grid.add_theme_constant_override("h_separation", 0)
	_board_grid.add_theme_constant_override("v_separation", 0)
	board_center.add_child(_board_grid)

	for index in range(64):
		var cell := _create_cell(index)
		_board_grid.add_child(cell)
		_cells.append(cell)

	var side := VBoxContainer.new()
	side.custom_minimum_size = Vector2(196, 0)
	side.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side.add_theme_constant_override("separation", 4)
	content.add_child(side)

	var history_caption := Label.new()
	history_caption.text = "История ходов"
	history_caption.add_theme_font_size_override("font_size", 10)
	history_caption.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))
	side.add_child(history_caption)

	var history_panel := PanelContainer.new()
	history_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	history_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.97, 0.96, 0.9), Color(0.42, 0.42, 0.38)))
	side.add_child(history_panel)
	var history_margin := MarginContainer.new()
	history_margin.add_theme_constant_override("margin_left", 5)
	history_margin.add_theme_constant_override("margin_top", 4)
	history_margin.add_theme_constant_override("margin_right", 5)
	history_margin.add_theme_constant_override("margin_bottom", 4)
	history_panel.add_child(history_margin)
	_history_label = RichTextLabel.new()
	_history_label.bbcode_enabled = true
	_history_label.fit_content = false
	_history_label.scroll_active = true
	_history_label.custom_minimum_size = Vector2(184, 0)
	_history_label.add_theme_font_size_override("normal_font_size", 10)
	_history_label.add_theme_font_size_override("bold_font_size", 10)
	history_margin.add_child(_history_label)

	var side_buttons := HBoxContainer.new()
	side_buttons.add_theme_constant_override("separation", 4)
	side.add_child(side_buttons)
	_hint_button = Button.new()
	_hint_button.text = "Подсказка"
	_hint_button.custom_minimum_size = Vector2(0, 26)
	_hint_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hint_button.focus_mode = Control.FOCUS_NONE
	_hint_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_hint_button.pressed.connect(_show_hint)
	side_buttons.add_child(_hint_button)
	_reset_button = Button.new()
	_reset_button.text = "Заново"
	_reset_button.custom_minimum_size = Vector2(0, 26)
	_reset_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_reset_button.focus_mode = Control.FOCUS_NONE
	_reset_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_reset_button.pressed.connect(_reset_puzzle)
	side_buttons.add_child(_reset_button)

	var status_panel := PanelContainer.new()
	status_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.93, 0.91, 0.82), Color(0.35, 0.35, 0.3)))
	outer.add_child(status_panel)
	var status_margin := MarginContainer.new()
	status_margin.add_theme_constant_override("margin_left", 6)
	status_margin.add_theme_constant_override("margin_top", 3)
	status_margin.add_theme_constant_override("margin_right", 6)
	status_margin.add_theme_constant_override("margin_bottom", 3)
	status_panel.add_child(status_margin)
	_status_label = Label.new()
	_status_label.text = "Ход белых. Партия остановлена на 34-м ходу."
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_size_override("font_size", 10)
	_status_label.add_theme_color_override("font_color", Color(0.08, 0.08, 0.06))
	status_margin.add_child(_status_label)


func _create_cell(index: int) -> Button:
	var cell := Button.new()
	cell.custom_minimum_size = Vector2(52, 52)
	cell.focus_mode = Control.FOCUS_NONE
	cell.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	cell.pressed.connect(_on_cell_pressed.bind(index))
	var piece := TextureRect.new()
	piece.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	piece.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	piece.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(piece)
	piece.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	piece.offset_left = 4
	piece.offset_top = 4
	piece.offset_right = -4
	piece.offset_bottom = -4
	_cell_pieces.append(piece)
	return cell


func _reset_puzzle() -> void:
	_stage = 0
	_solved = false
	_selected_square = ""
	_valid_target = ""
	_load_fen(PUZZLE_FEN)
	_history_text = "[color=#000080][b]Партия № 034[/b][/color]\nСаймон Раклин — GNU Chess 98\nХод белых. Мат в 2 хода.\n"
	_history_label.text = _history_text
	_status_label.text = "Ход белых. Партия остановлена на 34-м ходу."
	_stage_label.text = "Задача: мат в 2 хода"
	_refresh_board()


func _load_fen(fen: String) -> void:
	_board.clear()
	var rows := fen.split(" ")[0].split("/")
	for row_index in range(mini(8, rows.size())):
		var file_index := 0
		var row_text: String = rows[row_index]
		for char_index in range(row_text.length()):
			var symbol := row_text.substr(char_index, 1)
			if symbol.is_valid_int():
				file_index += int(symbol)
				continue
			if file_index >= 8:
				break
			var color := "w" if symbol == symbol.to_upper() else "b"
			var kind := symbol.to_lower()
			var square := _coords_to_square(file_index, 8 - row_index)
			_board[square] = {"color": color, "kind": kind}
			file_index += 1


func _refresh_board() -> void:
	for index in range(64):
		var square := _index_to_square(index)
		var piece: Dictionary = _board.get(square, {})
		var piece_rect := _cell_pieces[index]
		if piece.is_empty():
			piece_rect.texture = null
			piece_rect.visible = false
		else:
			var key := "%s_%s" % [piece["color"], KIND_NAMES[piece["kind"]]]
			piece_rect.texture = PIECE_TEXTURES.get(key, null)
			piece_rect.visible = true
		_style_cell(index, square)


func _style_cell(index: int, square: String) -> void:
	var file_index := _square_file(square)
	var rank_index := _square_rank(square)
	var is_light := ((file_index + (8 - rank_index)) % 2 == 0)
	var base := LIGHT_SQUARE if is_light else DARK_SQUARE
	var border := Color(0, 0, 0, 0)
	var border_width := 0
	if square == _selected_square:
		border = SELECTED_BORDER
		border_width = 3
	elif square == _valid_target:
		border = TARGET_BORDER
		border_width = 3
	var style := _make_cell_style(base, base.lightened(0.06), border, border_width)
	var cell := _cells[index]
	cell.add_theme_stylebox_override("normal", style)
	cell.add_theme_stylebox_override("hover", style)
	cell.add_theme_stylebox_override("pressed", style)
	cell.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _make_cell_style(base: Color, hover: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = base
	style.content_margin_left = 0.0
	style.content_margin_top = 0.0
	style.content_margin_right = 0.0
	style.content_margin_bottom = 0.0
	if border_width > 0:
		style.border_width_left = border_width
		style.border_width_top = border_width
		style.border_width_right = border_width
		style.border_width_bottom = border_width
		style.border_color = border
	return style


func _on_cell_pressed(index: int) -> void:
	if _solved:
		return
	var square := _index_to_square(index)
	if _selected_square == "":
		var piece: Dictionary = _board.get(square, {})
		if piece.is_empty() or piece.get("color", "") != "w":
			_status_label.text = "Выбери белую фигуру. Саймон играл белыми."
			return
		_selected_square = square
		if square == EXPECTED_FROM[_stage]:
			_valid_target = EXPECTED_TO[_stage]
			_status_label.text = "Фигура выбрана. Куда поведёт форсированный вариант?"
		else:
			_valid_target = ""
			_status_label.text = "Саймон видел только один форсированный ход. Ищи жертву."
		_refresh_board()
		return

	if square == _selected_square:
		_selected_square = ""
		_valid_target = ""
		_refresh_board()
		return

	var target_piece: Dictionary = _board.get(square, {})
	if not target_piece.is_empty() and target_piece.get("color", "") == "w":
		# Переключение выбора на другую свою фигуру.
		_selected_square = square
		_valid_target = EXPECTED_TO[_stage] if square == EXPECTED_FROM[_stage] else ""
		_status_label.text = "Фигура выбрана."
		_refresh_board()
		return

	var from := _selected_square
	_selected_square = ""
	_valid_target = ""
	_attempt_move(from, square)


func _attempt_move(from: String, to: String) -> bool:
	if _solved or _stage < 0 or _stage >= EXPECTED_FROM.size():
		return false
	if from != EXPECTED_FROM[_stage] or to != EXPECTED_TO[_stage]:
		_status_label.text = "Неверно. Саймон жертвовал только ферзя — искал единственный форсированный ход."
		_refresh_board()
		_play_audio("play_error")
		return false

	_apply_move(from, to)
	if _stage == 0:
		_history_text += "[color=#000080]34. Qe8+![/color]"
		_apply_move("h8", "e8")
		_history_text += " [color=#000080]Rxe8[/color]\n"
		_stage = 1
		_stage_label.text = "Мат в 1 ход"
		_status_label.text = "Шах! Чёрные ответили единственным образом. Теперь — мат."
		_play_audio("play_notify")
	else:
		_history_text += "[color=#000080]35. Rxe8#[/color]  [b]1-0[/b]\n"
		_solved = true
		_stage = 2
		_stage_label.text = "Матовое положение"
		_status_label.text = "МАТ! В истории ходов осталась странная пометка Саймона."
		_history_text += "[color=#6b6b6b]; «Тихий омут, поворот 54» — С.Р.[/color]\n"
		_play_audio("play_success")
		if GameState:
			GameState.solve_chess_puzzle()

	_history_label.text = _history_text
	_history_label.scroll_to_line(_history_label.get_line_count())
	_refresh_board()
	return true


func _apply_move(from: String, to: String) -> void:
	var piece: Dictionary = _board.get(from, {})
	if piece.is_empty():
		return
	_board.erase(from)
	_board[to] = piece


func _show_hint() -> void:
	if _solved:
		_status_label.text = "Задача уже решена. Пасхалка — в истории ходов."
		return
	if _stage == 0:
		_status_label.text = "Подсказка: единственный шах — ферзь с e7 на e8. Это жертва."
	else:
		_status_label.text = "Подсказка: ладья входит по открытой линии e и ставит мат."


func _coords_to_square(file_index: int, rank: int) -> String:
	return "%s%d" % [char(97 + file_index), rank]


func _square_file(square: String) -> int:
	return square.unicode_at(0) - 97


func _square_rank(square: String) -> int:
	return int(square.substr(1, 1))


func _index_to_square(index: int) -> String:
	var row := index / 8
	var col := index % 8
	return _coords_to_square(col, 8 - row)


func _make_panel_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = border
	style.content_margin_left = 4.0
	style.content_margin_top = 3.0
	style.content_margin_right = 4.0
	style.content_margin_bottom = 3.0
	return style


func _play_audio(method_name: String) -> void:
	var am := get_node_or_null("/root/AudioManager")
	if am and am.has_method(method_name):
		am.call(method_name)


## --- Публичный API для автотестов ------------------------------------------

func try_move(from: String, to: String) -> bool:
	_selected_square = ""
	_valid_target = ""
	return _attempt_move(from, to)


func get_stage() -> int:
	return _stage


func is_puzzle_solved() -> bool:
	return _solved


func get_history_text() -> String:
	return _history_text


func get_status_text() -> String:
	return _status_label.text if _status_label else ""


func get_board_piece(square: String) -> Dictionary:
	return _board.get(square, {})
