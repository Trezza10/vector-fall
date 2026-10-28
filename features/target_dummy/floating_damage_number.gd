class_name FloatingDamageNumber
extends Node2D

@export var number_color: Color = Color.WHITE:
	set(value):
		number_color = value
		if is_node_ready(): _label.add_theme_color_override("font_color", number_color)
@export var text_prefix: String = ""
@export_range(12, 60, 1) var font_size: int = 22
@export_range(0.2, 3.0, 0.05) var lifetime: float = 1.0
@export_range(0.0, 1.0, 0.05) var fade_delay: float = 0.2
@export_range(1.0, 2.0, 0.05) var punch_scale: float = 1.4
@export_range(0.05, 0.5, 0.01) var punch_duration: float = 0.22
@export var spawn_offset: Vector2 = Vector2(0, -88)
@export var drift_velocity: Vector2 = Vector2(12, -42)
@export_range(0.0, 200.0, 1.0) var max_drift: float = 64.0
@export_group("Variation")
@export var spawn_scatter: Vector2 = Vector2(6, 6)
@export_range(0.0, 60.0, 1.0) var drift_angle_variation_degrees: float = 25.0
@export_range(0.0, 60.0, 1.0) var horizontal_drift_variation: float = 24.0
@export_range(0.0, 0.5, 0.01) var speed_variation: float = 0.25
@export_range(0.0, 30.0, 1.0) var tilt_variation_degrees: float = 12.0
@export_range(0.0, 30.0, 1.0) var spin_variation_degrees: float = 10.0
@export_range(0.0, 60.0, 1.0) var arc_gravity: float = 24.0
@export_range(0.0, 0.3, 0.01) var punch_variation: float = 0.1

@onready var _label: Label = $Value

var _total: int = 0
var _active: bool = false
var _age: float = 0.0
var _punch_age: float = 0.0
var _travel_elapsed: float = 0.0
var _origin: Vector2
var _random: RandomNumberGenerator = RandomNumberGenerator.new()
var _sampled_velocity: Vector2
var _initial_angle: float = 0.0
var _angular_velocity: float = 0.0
var _sampled_gravity: float = 0.0
var _window_punch: float = 1.4

var displayed_damage: int:
	get: return _total

var is_active: bool:
	get: return _active

var remaining_lifetime: float:
	get: return maxf(0.0, lifetime - _age) if _active else 0.0

func _ready() -> void:
	_random.randomize()
	_label.add_theme_color_override("font_color", number_color)
	_label.add_theme_font_size_override("font_size", font_size)
	reset_number()

func add_damage(amount: int, target_position: Vector2) -> void:
	if amount <= 0 or get_tree().paused: return
	if not _active:
		_total = 0
		_sample_motion(target_position)
		global_position = _origin
		rotation = _initial_angle
		_travel_elapsed = 0.0
		_age = 0.0
		modulate.a = 1.0
	_total += amount
	_punch_age = 0.0
	_active = true
	_label.text = text_prefix + str(_total)
	_label.add_theme_color_override("font_color", number_color)
	_label.add_theme_font_size_override("font_size", font_size)
	scale = Vector2.ONE * _window_punch
	show()
	set_process(true)

func _process(delta: float) -> void:
	_age += delta
	_punch_age += delta
	_travel_elapsed += delta
	if _age + 0.00001 >= lifetime:
		reset_number()
		return
	# Repeat hits punch the total but never extend this number's lifetime or fade.
	var travel: Vector2 = _sampled_velocity * _travel_elapsed
	travel.y += 0.5 * _sampled_gravity * _travel_elapsed * _travel_elapsed
	global_position = _origin + travel.limit_length(max_drift)
	rotation = _initial_angle + _angular_velocity * _travel_elapsed
	var punch: float = clampf(_punch_age / maxf(punch_duration, 0.01), 0.0, 1.0)
	var recovery: float = pow(1.0 - punch, 3.0) * cos(punch * PI)
	scale = Vector2.ONE * (1.0 + (_window_punch - 1.0) * recovery)
	var fade: float = clampf((_age - fade_delay) / maxf(lifetime - fade_delay, 0.01), 0.0, 1.0)
	modulate.a = 1.0 - fade * fade

func _sample_motion(target_position: Vector2) -> void:
	var scatter: Vector2 = spawn_scatter.abs()
	_origin = target_position + spawn_offset + Vector2(
		_random.randf_range(-scatter.x, scatter.x), _random.randf_range(-scatter.y, scatter.y))
	var angle: float = deg_to_rad(drift_angle_variation_degrees)
	_sampled_velocity = drift_velocity.rotated(_random.randf_range(-angle, angle))
	_sampled_velocity *= _random.randf_range(1.0 - speed_variation, 1.0 + speed_variation)
	_sampled_velocity.x += _random.randf_range(-horizontal_drift_variation, horizontal_drift_variation)
	_sampled_velocity.y = minf(_sampled_velocity.y, -22.0)
	_initial_angle = deg_to_rad(_random.randf_range(-tilt_variation_degrees, tilt_variation_degrees))
	_angular_velocity = deg_to_rad(_random.randf_range(-spin_variation_degrees, spin_variation_degrees))
	_sampled_gravity = arc_gravity * _random.randf_range(0.65, 1.15)
	_window_punch = maxf(1.0, punch_scale + _random.randf_range(-punch_variation, punch_variation))

func reset_number() -> void:
	_total = 0
	_active = false
	_age = 0.0
	_punch_age = 0.0
	_travel_elapsed = 0.0
	scale = Vector2.ONE
	rotation = 0.0
	modulate.a = 1.0
	hide()
	set_process(false)
