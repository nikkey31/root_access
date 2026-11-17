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
			"мишель_слежка.txt",
			"инструкция_шифрование.txt",
			"чек_заправка.txt",
			"location.enc",
			"накладная_доставка.txt",
			"Документы",
			"Работа",
			"Изображения",
			"Корзина",
			"DOCUMENTS",
			"PICTURES"
		]
	},
	"C:\\ROOT_ACCESS\\пароли.txt": {
		"type": "file",
		"is_encrypted": false,
		"content": "Пароль от папки Работа — др Юджина (день и месяц, 4 цифры: ДДММ)\nНакладную удалил, надо бы потом очистить корзину.\n\n— не забыть посмотреть свойства фото у ржавого пикапа",
		"size_str": "1 024 Б",
		"date_str": "02.10.2009 01:47",
		"type_str": "Текстовый документ"
	},
	"C:\\ROOT_ACCESS\\инструкция_шифрование.txt": {
		"type": "file",
		"is_encrypted": false,
		"content": "Инструкция по шифрованию и дешифрованию:\nДешифрование: decrypt <файл> -k <ключ>\nКлюч шифра — её адрес (латиницей, без пробелов)",
		"size_str": "412 Б",
		"date_str": "01.10.2009 19:15",
		"type_str": "Текстовый документ"
	},
	"C:\\ROOT_ACCESS\\мишель_слежка.txt": {
		"type": "file",
		"is_encrypted": false,
		"content": "Объект: Мишель Юхнова\nАдрес: LENINA 54\nМаршрут: Университет -> Остановка 18:20 -> Дом\nАвтобус: Линия 4\nСтатус: Готова к захвату",
		"size_str": "528 Б",
		"date_str": "29.09.2009 21:04",
		"type_str": "Текстовый документ"
	},
	"C:\\ROOT_ACCESS\\чек_заправка.txt": {
		"type": "file",
		"is_encrypted": false,
		"content": "АЗС «Северная» № 14\nДата: 29.09.2009 23:14\nТопливо: Дизель (60 л)\nСумма: 1 380.00 руб.\nСпособ оплаты: Наличные\nМесто: Северная промзона, км 4\nКассир: Смирнова О.",
		"size_str": "320 Б",
		"date_str": "29.09.2009 23:16",
		"type_str": "Текстовый документ"
	},
	"C:\\ROOT_ACCESS\\накладная_доставка.txt": {
		"type": "file",
		"is_encrypted": false,
		"content": "ТРАНСПОРТНАЯ НАКЛАДНАЯ № 441-A\nДата оформления: 01.10.2009\nАренда грузового фургона: бортовой номер 6752\nАрендатор: Рейвенс Е. В.\nПункт назначения: Склад № 3 (Северная промзона)\nГруз: Оборудование и тара (опломбировано)\nСтатус: Доставлено",
		"size_str": "1,2 КБ",
		"date_str": "01.10.2009 22:30",
		"type_str": "Текстовый документ"
	},
	"C:\\ROOT_ACCESS\\старый_чек_автосервис.txt": {
		"type": "file",
		"is_encrypted": false,
		"content": "Автосервис «Мотор-Гарант»\nЗаказ-наряд № 882 от 12.09.2009\nКлиент: Рейвенс Е.\nАвтомобиль: Пикап\nРаботы: Замена сайлентблоков, диагностика подвески.\nОплачено: 4 200 руб.",
		"size_str": "612 Б",
		"date_str": "12.09.2009 14:10",
		"type_str": "Текстовый документ"
	},
	"C:\\ROOT_ACCESS\\черновик_письма.txt": {
		"type": "file",
		"is_encrypted": false,
		"content": "Черновик (не отправлено):\nЗдравствуйте, по поводу оплаты аренды бокса за октябрь — переведу наличными до пятницы. Квитанцию за свет забрал.",
		"size_str": "410 Б",
		"date_str": "28.09.2009 03:22",
		"type_str": "Текстовый документ"
	},
	"C:\\ROOT_ACCESS\\location.enc": {
		"type": "file",
		"is_encrypted": true,
		"key": "LENINA54",
		"unlocked_file": "record.wav",
		"unlocked_content": "[AUDIO DATA: '...время почти вышло. Грузовик 6-7-5-2... Она останется здесь навсегда...']",
		"size_str": "4 096 Б",
		"date_str": "02.10.2009 02:03",
		"type_str": "Зашифрованный файл"
	},
	"C:\\ROOT_ACCESS\\Документы": {
		"type": "dir",
		"items": [
			"пароли.txt",
			"мишель_слежка.txt",
			"инструкция_шифрование.txt",
			"чек_заправка.txt",
			"readme.txt"
		],
		"type_str": "Папка"
	},
	"C:\\ROOT_ACCESS\\Документы\\readme.txt": {
		"type": "file",
		"is_encrypted": false,
		"content": "RootAccess System Documentation (c) 1998-2009",
		"size_str": "84 Б",
		"date_str": "01.09.2009 12:00",
		"type_str": "Текстовый документ"
	},
	"C:\\ROOT_ACCESS\\DOCUMENTS": {
		"type": "dir",
		"items": [
			"пароли.txt",
			"мишель_слежка.txt",
			"инструкция_шифрование.txt",
			"чек_заправка.txt",
			"readme.txt"
		],
		"type_str": "Папка"
	},
	"C:\\ROOT_ACCESS\\DOCUMENTS\\readme.txt": {
		"type": "file",
		"is_encrypted": false,
		"content": "RootAccess System Documentation (c) 1998-2009",
		"size_str": "84 Б",
		"date_str": "01.09.2009 12:00",
		"type_str": "Текстовый документ"
	},
	"C:\\ROOT_ACCESS\\Работа": {
		"type": "dir",
		"items": [
			"мишель_слежка.txt",
			"инструкция_шифрование.txt",
			"location.enc"
		],
		"is_locked": true,
		"type_str": "Защищённая папка"
	},
	"C:\\ROOT_ACCESS\\WORK": {
		"type": "dir",
		"items": [
			"мишель_слежка.txt",
			"инструкция_шифрование.txt",
			"location.enc"
		],
		"is_locked": true,
		"type_str": "Защищённая папка"
	},
	"C:\\ROOT_ACCESS\\Изображения": {
		"type": "dir",
		"items": [
			"IMG_2042.jpg",
			"IMG_2041.jpg",
			"IMG_2038.jpg",
			"truck_6752.jpg",
			"birthday_eugene.jpg"
		],
		"type_str": "Папка"
	},
	"C:\\ROOT_ACCESS\\PICTURES": {
		"type": "dir",
		"items": [
			"IMG_2042.jpg",
			"IMG_2041.jpg",
			"IMG_2038.jpg",
			"truck_6752.jpg",
			"birthday_eugene.jpg"
		],
		"type_str": "Папка"
	},
	"C:\\ROOT_ACCESS\\Корзина": {
		"type": "dir",
		"items": [
			"накладная_доставка.txt",
			"старый_чек_автосервис.txt",
			"черновик_письма.txt"
		],
		"type_str": "Корзина"
	},
	"C:\\ROOT_ACCESS\\RECYCLE_BIN": {
		"type": "dir",
		"items": [
			"накладная_доставка.txt",
			"старый_чек_автосервис.txt",
			"черновик_письма.txt"
		],
		"type_str": "Корзина"
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
			var node = files_database.get(full_item_path, {})
			result.append({
				"name": item,
				"full_path": full_item_path,
				"is_dir": is_dir,
				"is_encrypted": is_enc,
				"is_locked": node.get("is_locked", false),
				"size_str": node.get("size_str", "1 КБ" if not is_dir else ""),
				"date_str": node.get("date_str", "02.10.2009 01:45"),
				"type_str": node.get("type_str", "Папка" if is_dir else ("Зашифрованный файл" if is_enc else "Текстовый документ"))
			})
		return result
	return []

func read_file(file_path: String) -> Dictionary:
	var resolved = _resolve_path(file_path)
	var node = null
	if files_database.has(resolved):
		node = files_database[resolved]
	else:
		# Fallback: поиск по имени файла
		var base_name = file_path.replace("/", "\\").split("\\")[-1]
		for key in files_database.keys():
			if key.ends_with("\\" + base_name) or key == base_name:
				node = files_database[key]
				resolved = key
				break
	
	if node == null:
		return {
			"success": false,
			"error": "Файл не найден: " + file_path
		}
	
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
		"is_encrypted": false,
		"full_path": resolved
	}

func decrypt_file(file_path: String, key: String) -> Dictionary:
	var resolved = _resolve_path(file_path)
	if not files_database.has(resolved):
		# Fallback по имени
		var base_name = file_path.replace("/", "\\").split("\\")[-1]
		for k in files_database.keys():
			if k.ends_with("\\" + base_name):
				resolved = k
				break

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
		"content": node.get("unlocked_content", ""),
		"size_str": "820 КБ",
		"date_str": "02.10.2009 03:40",
		"type_str": "Звуковой файл WAV"
	}
	
	if files_database.has(parent_dir):
		var dir_items: Array = files_database[parent_dir]["items"]
		if not unlocked_name in dir_items:
			dir_items.append(unlocked_name)
	
	# Уведомляем GameState
	if GameState:
		GameState.verify_decryption(resolved.get_file(), key)
	
	return {
		"success": true,
		"unlocked_file": unlocked_name,
		"content": node.get("unlocked_content", "")
	}

func _resolve_path(path: String) -> String:
	var clean = path.strip_edges().replace("/", "\\")
	if clean == "" or clean == "." or clean == "C:" or clean == "C:\\":
		return "C:\\ROOT_ACCESS"
	if clean == "Документы" or clean == "DOCUMENTS":
		return "C:\\ROOT_ACCESS\\Документы"
	if clean == "Работа" or clean == "WORK":
		return "C:\\ROOT_ACCESS\\Работа"
	if clean == "Корзина" or clean == "RECYCLE_BIN":
		return "C:\\ROOT_ACCESS\\Корзина"
	if clean == "Изображения" or clean == "PICTURES":
		return "C:\\ROOT_ACCESS\\Изображения"
	if clean.begins_with("C:\\ROOT_ACCESS") or clean.begins_with("c:\\root_access"):
		return clean
	if clean.begins_with("C:\\") or clean.begins_with("c:\\"):
		var rel = clean.substr(3)
		if rel == "Документы" or rel == "DOCUMENTS":
			return "C:\\ROOT_ACCESS\\Документы"
		if rel == "Работа" or rel == "WORK":
			return "C:\\ROOT_ACCESS\\Работа"
		if rel == "Корзина" or rel == "RECYCLE_BIN":
			return "C:\\ROOT_ACCESS\\Корзина"
		if rel == "Изображения" or rel == "PICTURES":
			return "C:\\ROOT_ACCESS\\Изображения"
		return "C:\\ROOT_ACCESS\\" + rel
	return current_directory + "\\" + clean
