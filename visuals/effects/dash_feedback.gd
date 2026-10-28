class_name DashFeedback
extends Node2D

@export_range(0.05, 0.5, 0.01) var trail_lifetime: float = 0.16
@export_range(0.05, 0.6, 0.01) var pulse_duration: float = 0.28

@onready var _trail: Line2D = $Trail
@onready var _sparks: CPUParticles2D = $Sparks
@onready var _pulse: ColorRect = $Pulse

var _points: Array[Vector2] = []
var _ages: Array[float] = []
var _emitting: bool = false
var _flash_tween: Tween
var _previous_position: Vector2
var _current_position: Vector2

func _ready() -> void:
	_trail.global_transform = Transform2D.IDENTITY
	set_physics_process(false)
	set_process(false)

func _physics_process(_delta: float) -> void:
	_previous_position = _current_position
	_current_position = global_position

func _process(delta: float) -> void:
	for index: int in range(_ages.size()): _ages[index] += delta
	while not _ages.is_empty() and _ages[0] > trail_lifetime:
		_ages.pop_front()
		_points.pop_front()
	if _emitting:
		var fraction: float = Engine.get_physics_interpolation_fraction()
		_points.append(_previous_position.lerp(_current_position, fraction))
		_ages.append(0.0)
	_trail.points = PackedVector2Array(_points)
	if not _ages.is_empty():
		_trail.modulate.a = 1.0 - _ages.back() / trail_lifetime
	if not _emitting and _points.is_empty(): set_process(false)

func begin(direction: Vector2) -> void:
	_emitting = true
	_previous_position = global_position
	_current_position = global_position
	set_physics_process(true)
	set_process(true)
	_sparks.rotation = direction.angle() + PI
	_sparks.emitting = true
	_pulse.rotation = direction.angle() + PI / 2.0
	if _flash_tween != null: _flash_tween.kill()
	_set_flash(1.0)
	_flash_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_flash_tween.tween_method(_set_flash, 1.0, 0.0, pulse_duration).set_trans(Tween.TRANS_QUAD)

func finish() -> void:
	_emitting = false
	set_physics_process(false)
	_sparks.emitting = false

func reset() -> void:
	finish()
	if _flash_tween != null: _flash_tween.kill()
	_set_flash(0.0)
	_points.clear()
	_ages.clear()
	_trail.clear_points()
	# Restart disabled emission to discard particles at a previous reset position.
	_sparks.restart()
	_sparks.emitting = false
	set_process(false)

func _set_flash(value: float) -> void:
	var pulse_material: ShaderMaterial = _pulse.material as ShaderMaterial
	pulse_material.set_shader_parameter("strength", value)
