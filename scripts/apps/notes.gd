class_name NotesApp
extends Control

## Текстовый процессор «Заметки» (Notes / Notepad).
## Отображает список ключевых заметок слева и содержимое файла справа.
## Содержимое динамически читается из VFS.

signal note_opened(note_name: String)

@onready var notes_list: ItemList = $VBox/ContentMargin/Split/LeftPanel/NotesList
@onready var file_path_label: Label = $VBox/ContentMargin/Split/RightPanel/HeaderPanel/HeaderRow/FilePathLabel
@onready var date_label: Label = $VBox/ContentMargin/Split/RightPanel/HeaderPanel/HeaderRow/DateLabel
@onready var text_display: RichTextLabel = $VBox/ContentMargin/Split/RightPanel/TextPanel/Margin/TextDisplay
@onready var status_left: Label = $VBox/StatusBar/StatusMargin/StatusRow/StatusLeft
@onready var status_encoding: Label = $VBox/StatusBar/StatusMargin/StatusRow/StatusEncoding

const ICON_FILE := preload("res://assets/icons/file_text.png")

const DEFAULT_NOTES: Array[String] = [
	"пароли.txt",
	"мишель_слежка.txt",
	"инструкция_шифрование.txt",
	"чек_заправка.txt"
]

var current_file: String = ""

func _ready() -> void:
	_populate_notes_list()
	notes_list.item_selected.connect(_on_note_selected)
	
	if notes_list.item_count > 0:
		notes_list.select(0)
		_on_note_selected(0)
		
	if GameState:
		GameState.is_notes_opened = true

func _populate_notes_list() -> void:
	notes_list.clear()
	for file_name in DEFAULT_NOTES:
		var idx = notes_list.add_item(file_name, ICON_FILE)
		notes_list.set_item_tooltip(idx, "Нажмите для просмотра " + file_name)

func _on_note_selected(index: int) -> void:
	if index < 0 or index >= notes_list.item_count:
		return
	var file_name = notes_list.get_item_text(index)
	open_note(file_name)

## Публичный API для открытия любой заметки по имени файла или пути.
func open_note(file_name: String) -> void:
	current_file = file_name
	var vfs = VFS.get_vfs() if VFS else null
	var content = ""
	var full_path = "C:\\ROOT_ACCESS\\" + file_name
	var date_str = "02.10.2009 01:47"

	if vfs:
		var res = vfs.read_file(file_name)
		if res.get("success", false):
			content = res.get("content", "")
			full_path = res.get("full_path", full_path)
		else:
			content = "[color=#cc0000]Ошибка: " + res.get("error", "Не удалось прочитать файл") + "[/color]"
		
		if vfs.files_database.has(full_path):
			var node = vfs.files_database[full_path]
			date_str = node.get("date_str", date_str)

	file_path_label.text = full_path
	date_label.text = date_str
	
	text_display.text = content
	status_left.text = "Файл: %s  |  Длина: %d симв." % [file_name.get_file(), content.length()]
	note_opened.emit(file_name)
	
	# Убеждаемся, что элемент выделен в списке
	for i in range(notes_list.item_count):
		if notes_list.get_item_text(i) == file_name:
			notes_list.select(i)
			break
