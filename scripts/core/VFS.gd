extends Node

## Виртуальная файловая система (VFS) игры «Root Access».
## Единое хранилище дерева дисков, папок, заметок, папки «Работа» и Корзины
## для Проводника, Заметок и Терминала.

static var instance: Node

# По спецификации рабочая папка Терминала по умолчанию - корень диска C:.
var current_directory: String = "C:\\ROOT_ACCESS"
var _initial_files_database: Dictionary = {}

func _ready() -> void:
	instance = self
	_initial_files_database = files_database.duplicate(true)

func reset_vfs() -> void:
	if not _initial_files_database.is_empty():
		files_database = _initial_files_database.duplicate(true)
	current_directory = "C:\\ROOT_ACCESS"
	print("[VFS] Состояние виртуальной файловой системы сброшено.")

func wipe_storage() -> void:
	files_database.clear()
	files_database["C:\\ROOT_ACCESS"] = {
		"type": "dir",
		"items": ["CORRUPTED_SECTOR_0.RAW", "CORRUPTED_SECTOR_1.RAW"],
		"type_str": "Повреждённый том"
	}
	files_database["C:\\ROOT_ACCESS\\CORRUPTED_SECTOR_0.RAW"] = {
		"type": "file",
		"content": "[DATA DESTROYED BY WIPE UTILITY 0x00000000]",
		"size_str": "0 КБ",
		"date_str": "02.10.2009 03:41",
		"type_str": "Повреждённый сектор"
	}
	files_database["C:\\ROOT_ACCESS\\CORRUPTED_SECTOR_1.RAW"] = {
		"type": "file",
		"content": "[BAD CHECKSUM // ZERO FILL]",
		"size_str": "0 КБ",
		"date_str": "02.10.2009 03:41",
		"type_str": "Повреждённый сектор"
	}
	print("[VFS] Виртуальное хранилище полностью стёрто командой wipe!")

const MY_DOCS_FILES: Array[String] = [
	"пароли.txt",
	"список_дел.txt",
	"дела_на_неделю.txt",
	"покупки.txt",
	"контакты.txt",
	"гараж_инвентарь.txt",
	"долги.txt",
	"рецепт_плова.txt",
	"черновик_объявления.txt",
	"сон_29_09.txt",
	"заметка_шум.txt",
]

var files_database: Dictionary = {
	"Мой компьютер": {
		"type": "dir",
		"items": [
			"Дискета 3,5 (A:)",
			"Локальный диск (C:)",
			"CD-дисковод (D:)"
		],
		"type_str": "Системная папка"
	},
	"Мой компьютер\\Дискета 3,5 (A:)": {
		"type": "device",
		"error_msg": "Устройство не готово.\nДисковод A: пуст или дискета повреждена.",
		"size_str": "",
		"date_str": "",
		"type_str": "Дисковод 3,5"
	},
	"Мой компьютер\\Локальный диск (C:)": {
		"type": "dir_link",
		"target": "C:\\ROOT_ACCESS",
		"size_str": "20 ГБ",
		"date_str": "",
		"type_str": "Локальный диск"
	},
	"Мой компьютер\\CD-дисковод (D:)": {
		"type": "device",
		"error_msg": "Вставьте диск в дисковод D:.",
		"size_str": "",
		"date_str": "",
		"type_str": "Компакт-диск"
	},

	# Корень локального диска C:
	"C:\\ROOT_ACCESS": {
		"type": "dir",
		"items": [
			"Мои документы",
			"Архив_2008",
			"Фото",
			"Загрузки",
			"Windows",
			"Работа"
		],
		"type_str": "Локальный диск"
	},
	"C:\\ROOT_ACCESS\\Мои документы": {
		"type": "dir",
		"items": [
			"пароли.txt",
			"список_дел.txt",
			"дела_на_неделю.txt",
			"покупки.txt",
			"контакты.txt",
			"гараж_инвентарь.txt",
			"долги.txt",
			"рецепт_плова.txt",
			"черновик_объявления.txt",
			"сон_29_09.txt",
			"заметка_шум.txt"
		],
		"type_str": "Папка"
	},
	"C:\\ROOT_ACCESS\\Документы": {
		"type": "dir",
		"items": [
			"пароли.txt",
			"список_дел.txt",
			"дела_на_неделю.txt",
			"покупки.txt",
			"контакты.txt",
			"гараж_инвентарь.txt",
			"долги.txt",
			"рецепт_плова.txt",
			"черновик_объявления.txt",
			"сон_29_09.txt",
			"заметка_шум.txt"
		],
		"type_str": "Папка"
	},
	"C:\\ROOT_ACCESS\\Архив_2008": {
		"type": "dir",
		"items": [
			"заказ_запчастей_2008.txt",
			"квартальный_отчёт.txt"
		],
		"type_str": "Папка"
	},
	"C:\\ROOT_ACCESS\\Фото": {
		"type": "app_link",
		"app_id": "gallery",
		"size_str": "",
		"date_str": "30.09.2009 00:38",
		"type_str": "Папка изображений"
	},
	"C:\\ROOT_ACCESS\\Загрузки": {
		"type": "dir",
		"items": [
			"setup_winamp.exe",
			"photo_resize.zip"
		],
		"type_str": "Папка"
	},
	"C:\\ROOT_ACCESS\\Windows": {
		"type": "dir",
		"access_denied": true,
		"items": [],
		"date_str": "14.03.2008 11:20",
		"type_str": "Системная папка"
	},
	"C:\\ROOT_ACCESS\\Работа": {
		"type": "dir",
		"items": [
			"location.enc",
			"график_работ.txt",
			"смета_гараж.txt",
			"заказы_октябрь.txt",
			"инструкция_шифрование.txt",
			"IMG_0501.JPG"
		],
		"is_locked": true,
		"date_str": "02.10.2009 02:03",
		"type_str": "Защищённая папка"
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

	# --- Файлы в «Мои документы» (11 заметок: бытовые + тревожные + пароли.txt) ---
	"C:\\ROOT_ACCESS\\Мои документы\\пароли.txt": {
		"type": "file",
		"is_encrypted": false,
		"content": "=== ПАРОЛИ (не терять!) ===\n\n\nрабочая: murzik_77_work   (старая: murzik77)\nавтофорум: garage_king / murzik77\nmail.ru: murzik_77\ngmail: Murzik77!\nфорум железа:garage_king_77\nскайп: simon_r77 или murzik_77 не помню\nICQ забыл, восстанавливать\nНакладную удалил потом очистить корзину\nбанк: НЕ ЗАПИСЫВАТЬ\nПапка Работа: др Юджина\nвайфай (мой) Rakhlinhom_77\nвайфай у брата:jenya_wifi\nдомофон 380\nкодовый замок гаража 1507\nстарый ноут (вход) . пусто",
		"size_str": "648 Б",
		"date_str": "02.10.2009 01:47",
		"type_str": "Текстовый документ"
	},
	"C:\\ROOT_ACCESS\\Мои документы\\список_дел.txt": {
		"type": "file",
		"is_encrypted": false,
		"content": "СУББОТА\n- кота к ветеринару (прививка)\n- корм, 2 пачки, курица\n- левая педаль в пикапе скрипит — смазать\n- вернуть диски в прокат\n- Жене позвонить насчёт фургона\n- проверить засов изнутри, не должно быть щели\n- лампочка в коридоре",
		"size_str": "380 Б",
		"date_str": "26.09.2009 09:15",
		"type_str": "Текстовый документ"
	},
	"C:\\ROOT_ACCESS\\Мои документы\\дела_на_неделю.txt": {
		"type": "file",
		"is_encrypted": false,
		"content": "ПН — записаться в сервис, замена масла в пикапе\nВТ — оплатить интернет, 350\nСР — справка для кота у ветеринара\nЧТ — ДР у Жени!!! подарок не забыть\nПТ — диски в прокат, взять новые\nСБ — гараж, разобрать верстак\nВС — маме позвонить",
		"size_str": "364 Б",
		"date_str": "21.09.2009 08:40",
		"type_str": "Текстовый документ"
	},
	"C:\\ROOT_ACCESS\\Мои документы\\покупки.txt": {
		"type": "file",
		"is_encrypted": false,
		"content": "молоко, хлеб, курица, чай, сахар, кофе\nкорм коту (курица)\nлампочка в коридор, батарейки АА\nхлорка 2 бутылки, перчатки резиновые",
		"size_str": "224 Б",
		"date_str": "25.09.2009 18:10",
		"type_str": "Текстовый документ"
	},
	"C:\\ROOT_ACCESS\\Мои документы\\контакты.txt": {
		"type": "file",
		"is_encrypted": false,
		"content": "Женя ............................ 555-0124\nМама ............................ 555-0211\nАвтосервис «Мотор» .............. 555-0377\nВетклиника ...................... 555-0452\nПрокат фургонов (Сергеич) ....... 555-0518\nСторож гаражей .................. 555-0630",
		"size_str": "412 Б",
		"date_str": "14.09.2009 20:05",
		"type_str": "Текстовый документ"
	},
	"C:\\ROOT_ACCESS\\Мои документы\\гараж_инвентарь.txt": {
		"type": "file",
		"is_encrypted": false,
		"content": "ЯЩИК 1: ключи рожковые, отвёртки\nЯЩИК 2: скотч армированный (4 рул.), стяжки (100 шт), изолента\nСТЕЛЛАЖ: перчатки, фонарь, канистра 10 л (пустая)\nПОД ВЕРСТАКОМ: верёвка 20 м, брезент, чистые тряпки\nФлакон без этикетки — в верхнем ящике, подальше от батареи\nДокупить: аккумулятор для фонаря",
		"size_str": "488 Б",
		"date_str": "23.09.2009 22:30",
		"type_str": "Текстовый документ"
	},
	"C:\\ROOT_ACCESS\\Мои документы\\долги.txt": {
		"type": "file",
		"is_encrypted": false,
		"content": "Женя — 3000 (07.09, вернул)\nСерёга — 1500 (до 15.10)\nСторож гаража — 500 за ключ",
		"size_str": "142 Б",
		"date_str": "18.09.2009 12:15",
		"type_str": "Текстовый документ"
	},
	"C:\\ROOT_ACCESS\\Мои документы\\рецепт_плова.txt": {
		"type": "file",
		"is_encrypted": false,
		"content": "Плов в казане:\n1. Раскалить масло до дымка, обжарить баранину до корки.\n2. Лук полукольцами, морковь соломкой, зира и барбарис.\n3. Залить кипятком на палец выше риса, накрыть на 35 мин.",
		"size_str": "312 Б",
		"date_str": "26.09.2009 20:42",
		"type_str": "Текстовый документ"
	},
	"C:\\ROOT_ACCESS\\Мои документы\\черновик_объявления.txt": {
		"type": "file",
		"is_encrypted": false,
		"content": "Продам генератор б/у (рабочий) и комплект зимней резины R15.\nСамовывоз из гаража в будни после 19:00.\nЗвонить строго вечером, на неизвестные днём не отвечаю.",
		"size_str": "276 Б",
		"date_str": "19.09.2009 23:05",
		"type_str": "Текстовый документ"
	},
	"C:\\ROOT_ACCESS\\Мои документы\\сон_29_09.txt": {
		"type": "file",
		"is_encrypted": false,
		"content": "Опять не спал до четырёх. В коридоре тихо, только холодильник гудит и Мурзик ходит по столу.\nКогда люди говорят — они всегда врут. Когда молчат — им наконец можно верить.\nГлавное не оставлять свет включённым, соседи вечно смотрят в окна.",
		"size_str": "418 Б",
		"date_str": "29.09.2009 04:12",
		"type_str": "Текстовый документ"
	},
	"C:\\ROOT_ACCESS\\Мои документы\\заметка_шум.txt": {
		"type": "file",
		"is_encrypted": false,
		"content": "Поролон 50 мм гасит плохо, низкие частоты всё равно проходят через бетон.\nВойлок в два слоя + старые одеяла на створку держат заметно лучше.\nПроверял в дождь при радио на полную — у ворот снаружи ничего не слышно.",
		"size_str": "390 Б",
		"date_str": "27.09.2009 02:48",
		"type_str": "Текстовый документ"
	},

	# --- Файлы в «Архив_2008» ---
	"C:\\ROOT_ACCESS\\Архив_2008\\заказ_запчастей_2008.txt": {
		"type": "file",
		"is_encrypted": false,
		"content": "Заказ № 114 (ноябрь 2008)\n- Колодки тормозные передние — 1 компл.\n- Тросик сцепления — 1 шт.\n- Фильтр воздушный — 2 шт.",
		"size_str": "210 Б",
		"date_str": "18.11.2008 15:20",
		"type_str": "Текстовый документ"
	},
	"C:\\ROOT_ACCESS\\Архив_2008\\квартальный_отчёт.txt": {
		"type": "file",
		"is_encrypted": false,
		"content": "Отчёт по аренде помещений за IV кв. 2008.\nЗадолженностей по электроэнергии нет. Счётчик опломбирован.",
		"size_str": "186 Б",
		"date_str": "24.12.2008 17:04",
		"type_str": "Текстовый документ"
	},

	# --- Файлы в «Загрузки» ---
	"C:\\ROOT_ACCESS\\Загрузки\\setup_winamp.exe": {
		"type": "unsupported",
		"error_msg": "Нет программы для открытия файла setup_winamp.exe.\nЗапуск сторонних установщиков отключён политикой безопасности.",
		"size_str": "5,4 МБ",
		"date_str": "11.08.2009 21:30",
		"type_str": "Приложение"
	},
	"C:\\ROOT_ACCESS\\Загрузки\\photo_resize.zip": {
		"type": "unsupported",
		"error_msg": "Нет программы для открытия архива photo_resize.zip.",
		"size_str": "1,1 МБ",
		"date_str": "15.09.2009 19:14",
		"type_str": "Архив ZIP"
	},

	# --- Файлы в защищённой папке «Работа» (6 файлов) ---
	"C:\\ROOT_ACCESS\\Работа\\график_работ.txt": {
		"type": "file",
		"is_encrypted": false,
		"content": "ГРАФИК (М.)   нед. 21–28.09\nпн–пт  07:40 — выход (дом, адрес см. метку на карте), авт. №14\n       08:30–15:10 — учёба\n       15:30–17:45 — библиотека\n       18:05 — обратно, одна\nвт, чт — до 20:00\nсб — работа в кафе у остановки, 10:00–16:00\nвс — дома\nСтарт: ср, 30.09, вечер",
		"size_str": "462 Б",
		"date_str": "29.09.2009 21:04",
		"type_str": "Текстовый документ"
	},
	"C:\\ROOT_ACCESS\\Работа\\смета_гараж.txt": {
		"type": "file",
		"is_encrypted": false,
		"content": "Ремонт крыши гаража (по знакомству)\nшифер — 12 листов ........ 2 400\nбрус 50×100 — 6 шт ....... 1 800\nработа — Женя, за пиво ... 0",
		"size_str": "244 Б",
		"date_str": "16.09.2009 18:15",
		"type_str": "Текстовый документ"
	},
	"C:\\ROOT_ACCESS\\Работа\\заказы_октябрь.txt": {
		"type": "file",
		"is_encrypted": false,
		"content": "03.10 — свечи зажигания, 4 шт (для пикапа)\n07.10 — масляный фильтр\n10.10 — ремень ГРМ (проверить по пробегу)",
		"size_str": "204 Б",
		"date_str": "30.09.2009 14:50",
		"type_str": "Текстовый документ"
	},
	"C:\\ROOT_ACCESS\\Работа\\инструкция_шифрование.txt": {
		"type": "file",
		"is_encrypted": false,
		"content": "Дешифрование: decrypt <файл> -k <ключ>\nКлюч шифра — её адрес (латиницей, без пробелов)\nПример: decrypt test.enc -k ABC123",
		"size_str": "238 Б",
		"date_str": "01.10.2009 19:15",
		"type_str": "Текстовый документ"
	},
	"C:\\ROOT_ACCESS\\Работа\\IMG_0501.JPG": {
		"type": "image",
		"is_encrypted": false,
		"image_path": "res://assets/photos/IMG_0501.JPG",
		"content": "[IMAGE: IMG_0501.JPG]",
		"size_str": "241 КБ",
		"date_str": "28.09.2009 17:42",
		"type_str": "Изображение JPEG"
	},
	"C:\\ROOT_ACCESS\\Работа\\location.enc": {
		"type": "file",
		"is_encrypted": true,
		"key": "LENINA54",
		"unlocked_file": "record.wav",
		"unlocked_content": "[AUDIO DATA: '...время почти вышло. Грузовик 6-7-5-2... Она останется здесь навсегда...']",
		"size_str": "4 096 Б",
		"date_str": "02.10.2009 02:03",
		"type_str": "Зашифрованный файл"
	},

	# --- Файлы в «Корзина» (ровно 3 файла) ---
	"C:\\ROOT_ACCESS\\Корзина\\накладная_доставка.txt": {
		"type": "file",
		"is_encrypted": false,
		"content": "ТРАНСПОРТНАЯ НАКЛАДНАЯ № 441-A\nДата оформления: 01.10.2009\nАренда грузового фургона: бортовой номер 6752\nАрендатор: Рейвенс Е. В.\nПункт назначения: Склад № 3 (Северная промзона)\nГруз: Оборудование и тара (опломбировано)\nСтатус: Доставлено",
		"size_str": "1,2 КБ",
		"date_str": "01.10.2009 22:30",
		"type_str": "Текстовый документ"
	},
	"C:\\ROOT_ACCESS\\Корзина\\старый_чек_автосервис.txt": {
		"type": "file",
		"is_encrypted": false,
		"content": "Автосервис «Мотор»\nЗаказ-наряд № 882 от 12.09.2009\nКлиент: Рейвенс Е.\nАвтомобиль: Пикап\nРаботы: Замена сайлентблоков, диагностика подвески.\nОплачено: 4 200 руб.",
		"size_str": "612 Б",
		"date_str": "12.09.2009 14:10",
		"type_str": "Текстовый документ"
	},
	"C:\\ROOT_ACCESS\\Корзина\\черновик_письма.txt": {
		"type": "file",
		"is_encrypted": false,
		"content": "Черновик (не отправлено):\nЗдравствуйте, по поводу оплаты аренды бокса за октябрь — переведу наличными до пятницы. Квитанцию за свет забрал.",
		"size_str": "410 Б",
		"date_str": "28.09.2009 03:22",
		"type_str": "Текстовый документ"
	}
}

func _init() -> void:
	if not instance:
		instance = self

static func get_vfs() -> Node:
	return instance

func get_current_directory() -> String:
	return current_directory

func get_my_docs_files() -> Array[String]:
	return MY_DOCS_FILES.duplicate()

func list_dir(path: String = "") -> Array:
	var target = current_directory if path.strip_edges() == "" else _resolve_path(path)
	if files_database.has(target) and files_database[target]["type"] == "dir":
		var items: Array = files_database[target]["items"]
		var result: Array = []
		for item in items:
			var full_item_path = target + "\\" + item
			var node: Dictionary = files_database.get(full_item_path, {})
			if node.is_empty():
				# Fallback для алиаса Документы -> Мои документы
				var alt_path = "C:\\ROOT_ACCESS\\Мои документы\\" + item
				if files_database.has(alt_path):
					full_item_path = alt_path
					node = files_database[alt_path]
			var node_type: String = str(node.get("type", "file"))
			var is_dir: bool = (node_type == "dir" or node_type == "dir_link" or node_type == "app_link")
			var is_enc: bool = bool(node.get("is_encrypted", false))
			result.append({
				"name": item,
				"full_path": full_item_path,
				"node_type": node_type,
				"is_dir": is_dir,
				"is_encrypted": is_enc,
				"is_locked": bool(node.get("is_locked", false)),
				"access_denied": bool(node.get("access_denied", false)),
				"error_msg": str(node.get("error_msg", "")),
				"target": str(node.get("target", "")),
				"app_id": str(node.get("app_id", "")),
				"image_path": str(node.get("image_path", "")),
				"size_str": str(node.get("size_str", "1 КБ" if not is_dir else "")),
				"date_str": str(node.get("date_str", "02.10.2009 01:45")),
				"type_str": str(node.get("type_str", "Папка" if is_dir else ("Зашифрованный файл" if is_enc else "Текстовый документ")))
			})
		return result
	return []

func read_file(file_path: String) -> Dictionary:
	var resolved = _resolve_path(file_path)
	var node = null
	if files_database.has(resolved):
		node = files_database[resolved]
	else:
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
			"error": "Файл зашифрован. Требуется дешифрование."
		}

	return {
		"success": true,
		"content": node.get("content", ""),
		"is_encrypted": false,
		"full_path": resolved
	}

func change_directory(path: String) -> Dictionary:
	var clean = path.strip_edges().replace("/", "\\")
	if clean == "" or clean == ".":
		return {"success": true, "path": current_directory}
	
	if clean == "..":
		if current_directory == "C:\\ROOT_ACCESS" or current_directory == "C:\\":
			return {"success": true, "path": current_directory}
		var base = current_directory.get_base_dir()
		if base == "" or not base.begins_with("C:"):
			base = "C:\\ROOT_ACCESS"
		current_directory = base
		return {"success": true, "path": current_directory}
	
	if clean == "\\" or clean == "C:" or clean == "C:\\":
		current_directory = "C:\\ROOT_ACCESS"
		return {"success": true, "path": current_directory}
	
	if clean == "Документы" or clean == "C:\\ROOT_ACCESS\\Документы":
		current_directory = "C:\\ROOT_ACCESS\\Документы"
		return {"success": true, "path": current_directory}

	var rel = current_directory + "\\" + clean
	if (rel.ends_with("\\Работа") or rel.ends_with("\\WORK")) and GameState:
		if not GameState.is_work_folder_unlocked:
			return {
				"success": false,
				"error": "Доступ запрещён: каталог «Работа» защищён паролем. Требуется авторизация в Проводнике."
			}
	if files_database.has(rel):
		var rel_type: String = str(files_database[rel].get("type", ""))
		if rel_type == "dir" or rel_type == "dir_link":
			current_directory = rel
			return {"success": true, "path": current_directory}

	var resolved = _resolve_path(clean)
	# Проверка на защищённую папку Работа
	if (resolved.ends_with("\\Работа") or resolved.ends_with("\\WORK")) and GameState:
		if not GameState.is_work_folder_unlocked:
			return {
				"success": false,
				"error": "Доступ запрещён: каталог «Работа» защищён паролем. Требуется авторизация в Проводнике."
			}
	
	if files_database.has(resolved):
		var res_type: String = str(files_database[resolved].get("type", ""))
		if res_type == "dir" or res_type == "dir_link":
			current_directory = resolved
			return {"success": true, "path": current_directory}
		
	return {
		"success": false,
		"error": "Системе не удается найти указанный путь: " + path
	}

func decrypt_file(file_path: String, key: String) -> Dictionary:
	var resolved = _resolve_path(file_path)
	if not files_database.has(resolved):
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
	var expected_key: String = node.get("key", "").strip_edges().to_upper().replace(" ", "")
	var entered_key: String = key.strip_edges().to_upper().replace(" ", "")

	if expected_key == "" or entered_key != expected_key:
		return {
			"success": false,
			"error": "Ошибка контрольной суммы: неверный ключ дешифрования!"
		}

	var unlocked_name: String = node.get("unlocked_file", "record.wav")
	var parent_dir = resolved.get_base_dir()
	var unlocked_full_path = parent_dir + "\\" + unlocked_name

	var record_node = {
		"type": "file",
		"is_encrypted": false,
		"content": node.get("unlocked_content", ""),
		"size_str": "820 КБ",
		"date_str": "02.10.2009 03:40",
		"type_str": "Звуковой файл WAV"
	}

	files_database[unlocked_full_path] = record_node
	files_database["C:\\ROOT_ACCESS\\Работа\\" + unlocked_name] = record_node
	files_database["C:\\ROOT_ACCESS\\WORK\\" + unlocked_name] = record_node

	var target_dirs = [parent_dir, "C:\\ROOT_ACCESS\\Работа", "C:\\ROOT_ACCESS\\WORK", "C:\\ROOT_ACCESS"]
	for d in target_dirs:
		if files_database.has(d):
			var dir_items: Array = files_database[d]["items"]
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
	if clean == "Мой компьютер":
		return "Мой компьютер"
	if clean == "" or clean == "." or clean == "C:" or clean == "C:\\":
		return "C:\\ROOT_ACCESS"
	if clean == "Мои документы" or clean == "Документы" or clean == "DOCUMENTS":
		return "C:\\ROOT_ACCESS\\Мои документы"
	if clean == "Работа" or clean == "WORK":
		return "C:\\ROOT_ACCESS\\Работа"
	if clean == "Корзина" or clean == "RECYCLE_BIN":
		return "C:\\ROOT_ACCESS\\Корзина"
	if clean == "Архив_2008":
		return "C:\\ROOT_ACCESS\\Архив_2008"
	if clean == "Загрузки":
		return "C:\\ROOT_ACCESS\\Загрузки"
	if clean == "Windows":
		return "C:\\ROOT_ACCESS\\Windows"
	if clean.begins_with("C:\\ROOT_ACCESS") or clean.begins_with("c:\\root_access"):
		return clean
	if clean.begins_with("C:\\") or clean.begins_with("c:\\"):
		var rel = clean.substr(3)
		if rel == "Мои документы" or rel == "Документы" or rel == "DOCUMENTS":
			return "C:\\ROOT_ACCESS\\Мои документы"
		if rel == "Работа" or rel == "WORK":
			return "C:\\ROOT_ACCESS\\Работа"
		if rel == "Корзина" or rel == "RECYCLE_BIN":
			return "C:\\ROOT_ACCESS\\Корзина"
		return "C:\\ROOT_ACCESS\\" + rel
	return current_directory + "\\" + clean
