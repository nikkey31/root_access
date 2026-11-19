class_name EndingScreen
extends Control

signal restart_requested
signal close_requested

@onready var title_label: Label = $Panel/Margin/VBox/Header/TitleLabel
@onready var badge_label: Label = $Panel/Margin/VBox/Header/BadgeLabel
@onready var date_label: Label = $Panel/Margin/VBox/Header/DateLabel
@onready var text_label: RichTextLabel = $Panel/Margin/VBox/Scroll/TextLabel
@onready var stats_label: Label = $Panel/Margin/VBox/StatsLabel
@onready var restart_button: Button = $Panel/Margin/VBox/Buttons/RestartButton
@onready var close_button: Button = $Panel/Margin/VBox/Buttons/CloseButton

var _full_text: String = ""
var _char_index: int = 0
var _typewriter_speed: float = 0.015
var _typewriter_timer: float = 0.0

const COLOR_SALVATION: String = "#00e676"
const COLOR_FALSE: String = "#ff5252"
const COLOR_TIMEOUT: String = "#ff1744"
const COLOR_HORROR: String = "#d50000"
const COLOR_CORRUPTION: String = "#ffd600"

func _ready() -> void:
	visible = false
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

func _process(delta: float) -> void:
	if not visible or _char_index >= _full_text.length():
		return
	
	_typewriter_timer -= delta
	if _typewriter_timer <= 0.0:
		_typewriter_timer = _typewriter_speed
		_char_index = mini(_char_index + 3, _full_text.length())
		text_label.text = _full_text.substr(0, _char_index)

func display_ending(ending_id: int, details: Dictionary = {}) -> void:
	visible = true
	var point_name: String = str(details.get("point", "Не указана"))
	date_label.text = "02.10.2009 03:41 // ДЕТЕКТИВ: НИК БУДХАЙМ (NICK BUDHEIM)"
	
	match ending_id:
		1: # SALVATION
			badge_label.text = "[ ДЕЛО ЗАКРЫТО: ЗАЛОЖНИЦА СПАСЕНА ]"
			badge_label.modulate = Color(COLOR_SALVATION)
			title_label.text = "КОНЦОВКА 1: ГЕРОЙ НОЧИ"
			_full_text = "03:41: Спецназ полиции штурмовал Склад № 3 в Северной промзоне.\n\n"
			_full_text += "Мишель Юхнова обнаружена в изолированном помещении целой и невредимой.\n"
			_full_text += "Подозреваемый Саймон Раклин заблокирован и арестован при попытке покинуть территорию на фургоне (бортовой номер 6752).\n\n"
			_full_text += "Благодаря сопоставлению архивных фото, транспортной накладной и геоданных трагедию удалось предотвратить.\n\n"
			_full_text += "Департамент полиции выражает особую благодарность детективу Будхайму за хладнокровие и высочайший профессионализм."
			stats_label.text = "Итоговая оценка: ОТЛИЧНО (Идеальный исход) | Цель: %s" % point_name

		2: # FALSE_TRAIL
			badge_label.text = "[ ОПЕРАТИВНЫЙ ПРОВАЛ: ЛОЖНЫЙ СЛЕД ]"
			badge_label.modulate = Color(COLOR_FALSE)
			title_label.text = "КОНЦОВКА 2: РОКОВАЯ ОШИБКА"
			_full_text = "03:41: Оперативная группа штурмовала адрес: «%s».\n\n" % point_name
			_full_text += "Помещение оказалось полностью заброшенным. На месте обнаружены лишь следы старых шин.\n\n"
			_full_text += "Услышав сирены полицейских машин в соседнем районе, Саймон Раклин оборвал связь, погрузил заложницу в фургон и покинул город по объездной трассе.\n\n"
			_full_text += "След Мишель Юхновой потерян. Внутреннее расследование признало наведение штурма грубой ошибкой детектива. Будхайм отстранён от должности."
			stats_label.text = "Итоговая оценка: ПРОВАЛ РАССЛЕДОВАНИЯ | Ошибочная цель: %s" % point_name

		3: # TIMEOUT
			badge_label.text = "[ ОПЕРАТИВНЫЙ ТУПИК: ВРЕМЯ ИСТЕКЛО ]"
			badge_label.modulate = Color(COLOR_TIMEOUT)
			title_label.text = "КОНЦОВКА 3: ОПОЗДАНИЕ"
			_full_text = "03:41: 60 секунд истекли. Координатор оперативных служб так и не получил подтверждённых координат штурма.\n\n"
			_full_text += "В 03:42 радиоперехват похитителя замолчал навсегда.\n\n"
			_full_text += "Утром пустой грузовик подозреваемого был обнаружен сожжённым в лесополосе за окружной дорогой. Спасти заложницу не удалось.\n\n"
			_full_text += "Город погружается в панику, родственники пропавшей требуют отставки руководства департамента."
			stats_label.text = "Итоговая оценка: НЕУДАЧА (Превышен лимит времени)"

		4: # HORROR
			badge_label.text = "[ ЧРЕЗВЫЧАЙНОЕ ПРОИСШЕСТВИЕ: НЕЗВАНЫЙ ГОСТЬ ]"
			badge_label.modulate = Color(COLOR_HORROR)
			title_label.text = "КОНЦОВКА 4: НЕЗВАНЫЙ ГОСТЬ"
			_full_text = "03:41: Передача сетевой геометки раскрыла точные координаты квартиры Ника Будхайма.\n\n"
			_full_text += "Спустя 25 минут экран ноутбука с тихим щелчком схлопнулся в узкую полосу и погас. Комната погрузилась в глухую тьму.\n\n"
			_full_text += "В тишине из ночного подъезда раздался тяжёлый стук во входную дверь: ТУК... ТУК... ТУК...\n\n"
			_full_text += "Сообщник маньяка — его родной брат Юджин Рейвенс (Евгений Рейвенс) — выследил домашний адрес криминалиста по сетевому сигналу ноутбука. Ноутбук с уликами похищен, преступники скрылись, а судьба Мишель Юхновой осталась неизвестной."
			stats_label.text = "Итоговая оценка: КРИТИЧЕСКИЙ ПРОВАЛ (Нападение Юджина Рейвенса)"

		5: # CORRUPTION
			badge_label.text = "[ ДЕЛО СДАНО В АРХИВ: СДЕЛКА С ДЬЯВОЛОМ ]"
			badge_label.modulate = Color(COLOR_CORRUPTION)
			title_label.text = "КОНЦОВКА 5: СДЕЛКА С ДЬЯВОЛОМ"
			_full_text = "03:41: Платеж на сумму $100 000 успешно зачислен на офшорный счет.\n\n"
			_full_text += "Команда 'wipe --force' навсегда уничтожила секторы виртуального накопителя. Никаких цифровых улик против Саймона Раклина больше не существует.\n\n"
			_full_text += "Преступник покинул страну по фальшивому паспорту. Детектив Будхайм подал рапорт об увольнении из полиции по собственному желанию — обеспеченным, но навсегда сломленным человеком."
			stats_label.text = "Итоговая оценка: КОРРУПЦИОННЫЙ ИСХОД (Улики стёрты)"

		_:
			badge_label.text = "[ РАССЛЕДОВАНИЕ ЗАВЕРШЕНО ]"
			title_label.text = "ФИНАЛ РАССЛЕДОВАНИЯ"
			_full_text = "Материалы дела переданы в архив."
			stats_label.text = ""

	_char_index = 0
	_typewriter_timer = 0.0
	text_label.text = ""

func _on_restart_pressed() -> void:
	emit_signal("restart_requested")
	if has_node("/root/GameState"):
		get_node("/root/GameState").reset_state()
	if has_node("/root/VFS"):
		get_node("/root/VFS").reset_vfs()
	get_tree().reload_current_scene()

func _on_close_pressed() -> void:
	visible = false
	emit_signal("close_requested")
