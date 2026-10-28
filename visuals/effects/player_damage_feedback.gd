class_name PlayerDamageFeedback
extends CanvasLayer

@export_range(0.0, 30.0, 0.5) var shake_pixels: float = 10.0
@export_range(0.05, 0.6, 0.01) var shake_duration: float = 0.24
@export_range(0.0, 1.0, 0.05) var flash_intensity: float = 0.9
@export_range(0.1, 1.0, 0.05) var flash_duration: float = 0.35
@export_range(0.2, 1.5, 0.05) var number_duration: float = 0.7
@export_range(0.0, 0.5, 0.05) var low_health_threshold: float = 0.25
@export var damage_color: Color = Color(1.0, 0.25, 0.18)

@onready var _screen: ColorRect = $Screen
@onready var _number: Label = $DamageNumber
@onready var _direction_marker: Polygon2D = $DirectionMarker

var _player: PlaygroundPlayer
var _camera: Camera2D
var _bar: DamageHealthBar
var _base_offset: Vector2
var _source_direction: Vector2 = Vector2.ZERO
var _age: float = 100.0
var _strength: float = 0.0
var _phase: float = 0.0

func configure(player: PlaygroundPlayer, camera: Camera2D, bar: DamageHealthBar) -> void:
	_player = player
	_camera = camera
	_bar = bar
	_base_offset = camera.offset
	player.damage_taken.connect(_on_damage_taken)
	player.health_changed.connect(_on_health_changed)
	player.reset_performed.connect(reset_feedback)
	reset_feedback()

func _on_damage_taken(amount: int, source_direction: Vector2) -> void:
	_age = 0.0
	_strength = clampf(0.7 + float(amount) / float(maxi(1, _player.max_hp)) * 2.0, 0.7, 1.0)
	_source_direction = source_direction
	_phase = randf_range(0.0, TAU)
	var screen_direction: Vector2 = _player.get_canvas_transform().basis_xform(source_direction).normalized()
	(_screen.material as ShaderMaterial).set_shader_parameter("hit_direction", screen_direction)
	(_screen.material as ShaderMaterial).set_shader_parameter("strength", _strength * flash_intensity)
	_number.text = "-%d HP" % amount
	_number.modulate = Color(1, 0.4, 0.3, 1)
	_number.show()
	_direction_marker.visible = not source_direction.is_zero_approx()
	_bar.pulse(damage_color, 0.45)
	_update_marker()

func _process(delta: float) -> void:
	if _camera == null or _player == null: return
	_age += delta
	var envelope: float = pow(maxf(0.0, 1.0 - _age / shake_duration), 2.0)
	var wobble: Vector2 = Vector2(sin(_age * 80.0 + _phase), cos(_age * 93.0 + _phase))
	var kick: Vector2 = (wobble - _source_direction * 0.4) * shake_pixels * _strength * envelope
	_camera.offset = _base_offset + kick.limit_length(shake_pixels)
	var fade: float = pow(maxf(0.0, 1.0 - _age / flash_duration), 2.0)
	(_screen.material as ShaderMaterial).set_shader_parameter("strength", _strength * fade * flash_intensity)
	if _age >= number_duration:
		_number.hide()
		_direction_marker.hide()
	else:
		_update_marker()
		_number.modulate.a = pow(maxf(0.0, 1.0 - _age / number_duration), 0.65)
		_number.scale = Vector2.ONE * (1.0 + 0.35 * exp(-_age * 18.0))
		_direction_marker.modulate.a = maxf(0.0, 1.0 - _age / number_duration)

func _update_marker() -> void:
	var center: Vector2 = _player.get_global_transform_with_canvas().origin
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	center = center.clamp(Vector2(90, 100), viewport_size - Vector2(90, 100))
	_number.position = center + Vector2(-80, -85 - minf(_age, number_duration) * 26.0)
	var direction: Vector2 = _player.get_canvas_transform().basis_xform(_source_direction).normalized()
	_direction_marker.position = center + direction * 52.0
	_direction_marker.rotation = direction.angle() + PI / 2.0

func _on_health_changed(current: int, maximum: int) -> void:
	var fraction: float = float(current) / float(maxi(1, maximum))
	var low: float = clampf(1.0 - fraction / low_health_threshold, 0.0, 1.0) if low_health_threshold > 0.0 else 0.0
	(_screen.material as ShaderMaterial).set_shader_parameter("low_health", low)

func reset_feedback() -> void:
	_age = 100.0
	_strength = 0.0
	_number.hide()
	_direction_marker.hide()
	if _camera != null: _camera.offset = _base_offset
	(_screen.material as ShaderMaterial).set_shader_parameter("strength", 0.0)
	if _player != null: _on_health_changed(_player.current_hp, _player.max_hp)

func _exit_tree() -> void:
	if is_instance_valid(_camera): _camera.offset = _base_offset
