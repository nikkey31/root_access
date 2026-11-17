class_name FinalTimerBar
extends PanelContainer

## Тревожная верхняя плашка финального 60-секундного отсчёта (Акт 3–4).
## Скрыта до получения сигнала GameState.timer_started.

@onready var status_label: Label = $Margin/Row/StatusLabel
@onready var timer_label: Label = $Margin/Row/TimerLabel

var _pulse_time: float = 0.0
var _is_critical: bool = false

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func start_display(duration: float) -> void:
	visible = true
	_pulse_time = 0.0
	status_label.text = "ЗВОНОК ИЗ УЧАСТКА · НАЗОВИТЕ ТОЧКУ НА КАРТЕ"
	update_time(duration)

func update_time(time_left: float) -> void:
	var clamped := maxf(time_left, 0.0)
	var secs := int(ceil(clamped))
	var mm := secs / 60
	var ss := secs % 60
	timer_label.text = "%02d:%02d" % [mm, ss]
	_is_critical = clamped <= 15.0
	if not _is_critical:
		timer_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.28, 1.0))

func show_expired() -> void:
	_is_critical = false
	status_label.text = "СВЯЗЬ ПРЕРВАНА · ВРЕМЯ ВЫШЛО"
	timer_label.text = "00:00"
	timer_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2, 1.0))

func hide_display() -> void:
	visible = false
	_is_critical = false

func _process(delta: float) -> void:
	if not visible or not _is_critical:
		return
	_pulse_time += delta * 6.0
	var alpha := 0.55 + 0.45 * absf(sin(_pulse_time))
	timer_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2, alpha))
