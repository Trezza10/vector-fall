class_name DamageHealthBar
extends Control

@export var show_maximum: bool = false
@export var value_prefix: String = ""

@export_range(0.0, 1.0, 0.01) var chip_delay: float = 0.18
@export_range(0.05, 2.0, 0.05) var chip_duration: float = 0.45

@onready var _front: ProgressBar = $Health
@onready var _chip: ProgressBar = $Damage
@onready var _label: Label = $Value

@export var animate_healing: bool = false
@export_range(0.1, 1.0, 0.05) var heal_duration: float = 0.4
@export var heal_color: Color = Color(0.4, 1.0, 0.45)

var _fill_tween: Tween
var _pulse_tween: Tween
var _last_current: int = -1
var _chip_tween: Tween

var health_fraction: float:
	get: return _front.value

var damage_fraction: float:
	get: return _chip.value

func set_health(current: int, maximum: int, animate: bool = true) -> void:
	if _chip_tween != null: _chip_tween.kill()
	if _fill_tween != null: _fill_tween.kill()
	var healing: bool = _last_current >= 0 and current > _last_current and animate and animate_healing
	_last_current = current
	var previous: float = _front.value
	var fraction: float = clampf(float(current) / float(maxi(maximum, 1)), 0.0, 1.0)
	if not healing: _front.value = fraction
	var value_text: String = "1M" if maximum >= 1000000 and current == maximum else str(current)
	if show_maximum: value_text = "%d / %d" % [current, maximum]
	_label.text = value_prefix + value_text
	if not animate:
		if _pulse_tween != null: _pulse_tween.kill()
		modulate = Color.WHITE
		_chip.value = fraction
		return
	if healing:
		_chip.value = previous
		_fill_tween = create_tween().set_parallel(true)
		_fill_tween.tween_property(_front, "value", fraction, heal_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_fill_tween.tween_property(_chip, "value", fraction, heal_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		pulse(heal_color, heal_duration + 0.2)
		return
	_chip.value = maxf(_chip.value, fraction)
	_chip_tween = create_tween()
	_chip_tween.tween_interval(chip_delay)
	_chip_tween.tween_property(_chip, "value", fraction, chip_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func pulse(color: Color, duration: float = 0.4) -> void:
	if _pulse_tween != null: _pulse_tween.kill()
	modulate = color
	_pulse_tween = create_tween()
	_pulse_tween.tween_property(self, "modulate", Color.WHITE, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
