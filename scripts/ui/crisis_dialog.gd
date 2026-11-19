class_name CrisisDialog
extends Control

## Модальное окно кризисных событий финала: взятка Саймона ($100,000) и фишинг-ловушка с геометкой.
## Реализует психологический тёмный паттерн из сценария: красная рамка у кнопки отмены
## приучает игрока к шаблону «красная = закрыть», после чего в окне фишинга красной
## рамкой обведена кнопка «Продолжить», ведущая к утечке координат и концовке с Юджином.

signal bribe_cancelled
signal phishing_accepted
signal phishing_cancelled

enum Mode { NONE, BRIBE, PHISHING }

@onready var modal_backdrop: ColorRect = $ModalBackdrop
@onready var window_panel: PanelContainer = $Center/WindowPanel
@onready var title_label: Label = $Center/WindowPanel/VBox/TitleBar/HBox/TitleLabel
@onready var btn_close: Button = $Center/WindowPanel/VBox/TitleBar/HBox/BtnClose
@onready var message_label: Label = $Center/WindowPanel/VBox/Margin/ContentVBox/MessageLabel
@onready var btn_primary: Button = $Center/WindowPanel/VBox/Margin/ContentVBox/ButtonBox/BtnPrimary
@onready var btn_cancel: Button = $Center/WindowPanel/VBox/Margin/ContentVBox/ButtonBox/BtnCancel

var current_mode: Mode = Mode.NONE

func _ready() -> void:
	visible = false
	btn_close.pressed.connect(_on_close_pressed)
	btn_primary.pressed.connect(_on_primary_pressed)
	btn_cancel.pressed.connect(_on_cancel_pressed)

func show_bribe() -> void:
	current_mode = Mode.BRIBE
	title_label.text = "Анонимное входящее сообщение — Пейджер"
	message_label.text = "ОТПРАВИТЕЛЬ: Саймон Раклин\nТЕМА: ПРЕДЛОЖЕНИЕ\n\nНик, ты умный парень. У тебя осталась минута. Спецназу из участка нужно минимум 9 минут — они не успеют.\n\nЯ предлагаю тебе $100 000 наличными. Банковская ячейка № 442, ключ и код под козырьком на выходе из твоего подъезда.\n\nВсё, что от тебя требуется — ввести прямо сейчас в Терминале команду:\n\n    wipe --force\n\nСотри данные диска — и эти деньги твои. Либо погибнут все."

	btn_primary.visible = false
	btn_cancel.visible = true
	btn_cancel.text = "  Отмена  "
	_apply_red_border(btn_cancel, true)

	visible = true

func show_phishing() -> void:
	current_mode = Mode.PHISHING
	title_label.text = "Служба безопасности RetroOS — Сетевой запрос"
	message_label.text = "ВНИМАНИЕ: Удалённый узел [Host-982] запрашивает подтверждение сетевого сертификата, имя ПК и передачу геометки устройства [Координаты шлюза: Квартира Ника Будхайма] для калибровки соединения.\n\nРазрешить передачу сетевых данных и геометки устройства?"

	# Тёмный паттерн UX: в предыдущем окне красной была «Отмена».
	# Здесь красной рамкой обведена «Продолжить», чтобы спровоцировать клик на автомате.
	btn_primary.visible = true
	btn_primary.text = "  Продолжить  "
	_apply_red_border(btn_primary, true)

	btn_cancel.visible = true
	btn_cancel.text = "  Отмена  "
	_apply_red_border(btn_cancel, false)

	visible = true

func _apply_red_border(btn: Button, red: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.75, 0.75, 0.75, 1.0)
	style.content_margin_left = 16.0
	style.content_margin_top = 4.0
	style.content_margin_right = 16.0
	style.content_margin_bottom = 4.0
	if red:
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.9, 0.1, 0.1, 1.0)
	else:
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.4, 0.4, 0.4, 1.0)
	btn.add_theme_stylebox_override("normal", style)

	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.85, 0.85, 0.85, 1.0)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed := style.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.65, 0.65, 0.65, 1.0)
	btn.add_theme_stylebox_override("pressed", pressed)

func _on_primary_pressed() -> void:
	if current_mode == Mode.PHISHING:
		visible = false
		phishing_accepted.emit()

func _on_cancel_pressed() -> void:
	_dismiss()

func _on_close_pressed() -> void:
	_dismiss()

func _dismiss() -> void:
	visible = false
	var prev_mode := current_mode
	current_mode = Mode.NONE
	if prev_mode == Mode.BRIBE:
		bribe_cancelled.emit()
	elif prev_mode == Mode.PHISHING:
		phishing_cancelled.emit()

func close_dialog() -> void:
	visible = false
	current_mode = Mode.NONE
