extends Node

## Виртуальная файловая система (VFS) игры «Root Access».
## Реализует требование FR-CORE-2: единый API для Терминала и Проводника.
## При отсутствии загруженного внешнего ядра работает в автономном режиме.

static var instance: VFS

var current_directory: String = "C:\\ROOT_ACCESS"

# Виртуальное дерево файлов и папок по утверждённому сценарию SCENARIO.md
var files_database: Dictionary = {
	"C:\\ROOT_ACCESS": {
		"type": "dir",
		"items": [
			"пароли.txt",
			"инструкция_шифрование.txt",
			"мишель_слежка.txt",
			"location.enc",
			"накладная_доставка.txt",
			"DOCUMENTS",
			"PICTURES"
		]
	},
	"C:\\ROOT_ACCESS\\пароли.txt": {
		"type": "file",
		"is_encrypted": false,
		"content": "Пароль от папки Работа — др Юджина (день и месяц, 4 цифры: ДДММ)\nНакладную удалил, надо бы потом очистить корзину"
	},
	"C:\\ROOT_ACCESS\\инструкция_шифрование.txt": {
		"type": "file",
		"is_encrypted": false,
		"content": "Инструкция по шифрованию и дешифрованию:\nДешифрование: decrypt <файл> -k <ключ>\nКлюч шифра — её адрес (латиницей, без пробелов)"
	},
	"C:\\ROOT_ACCESS\\мишель_слежка.txt": {
		"type": "file",
		"is_encrypted": false,
		"content": "Объект: Мишель Юхнова\nАдрес: LENINA 54\nМаршрут: Университет -> Остановка 18:20 -> Дом\nАвтобус: Линия 4\nСтатус: Готова к захвату"
	},
	"C:\\ROOT_ACCESS\\накладная_доставка.txt": {
		"type": "file",
		"is_encrypted": false,
		"content": "Накладная № 441-A\nАренда грузового фургона (бортовой номер 6752).\nАрендатор: Е. Рейвенс.\nВыгрузка оборудования: Склад № 3 (Северная промзона)"
	},
	"C:\\ROOT_ACCESS\\location.enc": {
		"type": "file",
		"is_encrypted": true,
		"key": "LENINA54",
		"unlocked_file": "record.wav",
		"unlocked_content": "[AUDIO DATA: '...время почти вышло. Грузовик 6-7-5-2... Она останется здесь навсегда...']"
	},
	"C:\\ROOT_ACCESS\\DOCUMENTS": {
		"type": "dir",
		"items": ["readme.txt"]
	},
	"C:\\ROOT_ACCESS\\DOCUMENTS\\readme.txt": {
		"type": "file",
		"is_encrypted": false,
		"content": "RootAccess System Documentation (c) 1998-2009"
	},
	"C:\\ROOT_ACCESS\\PICTURES": {
		"type": "dir",
		"items": ["truck_6752.jpg", "birthday_eugene.jpg"]
	}
}

func _init() -> void:
	if not instance:
		instance = self

static func get_vfs() -> VFS:
	return instance

func get_current_directory() -> String:
	return current_directory

func list_dir(path: String = "") -> Array:
	var target = current_directory if path.strip_edges() == "" else _resolve_path(path)
	if files_database.has(target) and files_database[target]["type"] == "dir":
		var items: Array = files_database[target]["items"]
		var result: Array = []
		for item in items:
			var full_item_path = target + "\\" + item
			var is_dir = files_database.has(full_item_path) and files_database[full_item_path]["type"] == "dir"
			var is_enc = files_database.has(full_item_path) and files_database[full_item_path].get("is_encrypted", false)
			result.append({
				"name": item,
				"is_dir": is_dir,
				"is_encrypted": is_enc
			})
		return result
	return []

func read_file(file_path: String) -> Dictionary:
	var resolved = _resolve_path(file_path)
	if not files_database.has(resolved):
		return {
			"success": false,
			"error": "Файл не найден: " + file_path
		}
	
	var node = files_database[resolved]
	if node["type"] == "dir":
		return {
			"success": false,
			"error": "Указанный путь является каталогом, а не файлом: " + file_path
		}
	
	if node.get("is_encrypted", false):
		return {
			"success": false,
			"is_encrypted": true,
			"error": "Файл зашифрован. Используйте утилиту дешифрования: decrypt " + file_path + " -k <ключ>"
		}
	
	return {
		"success": true,
		"content": node.get("content", ""),
		"is_encrypted": false
	}

func decrypt_file(file_path: String, key: String) -> Dictionary:
	var resolved = _resolve_path(file_path)
	if not files_database.has(resolved):
		return {
			"success": false,
			"error": "Зашифрованный файл не найден: " + file_path
		}
	
	var node = files_database[resolved]
	if not node.get("is_encrypted", false):
		return {
			"success": false,
			"error": "Файл не зашифрован."
		}
	
	var expected_key: String = node.get("key", "").strip_edges()
	var entered_key: String = key.strip_edges()
	
	if expected_key == "" or entered_key.to_upper() != expected_key.to_upper():
		return {
			"success": false,
			"error": "Ошибка контрольной суммы: неверный ключ дешифрования!"
		}
	
	# Успех расшифровки
	var unlocked_name: String = node.get("unlocked_file", "unlocked.txt")
	var parent_dir = resolved.get_base_dir()
	var unlocked_full_path = parent_dir + "\\" + unlocked_name
	
	files_database[unlocked_full_path] = {
		"type": "file",
		"is_encrypted": false,
		"content": node.get("unlocked_content", "")
	}
	
	if files_database.has(parent_dir):
		var dir_items: Array = files_database[parent_dir]["items"]
		if not unlocked_name in dir_items:
			dir_items.append(unlocked_name)
	
	return {
		"success": true,
		"unlocked_file": unlocked_name,
		"content": node.get("unlocked_content", "")
	}

func _resolve_path(path: String) -> String:
	var clean = path.strip_edges()
	if clean.begins_with("C:\\") or clean.begins_with("c:\\"):
		return clean
	return current_directory + "\\" + clean
