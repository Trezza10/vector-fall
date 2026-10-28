class_name PlaygroundPlayer
extends CharacterBody2D

enum ControlMode { DIRECTIONAL, CURSOR_STEERING }

signal dash_started
signal hit_received(amount: int)
signal damage_taken(amount: int, source_direction: Vector2)
signal reset_performed
signal health_changed(current: int, maximum: int)
signal died

signal dash_finished

@export_range(50.0, 1000.0, 10.0) var max_speed: float = 360.0
@export_range(100.0, 10000.0, 100.0) var acceleration: float = 2400.0
@export_range(100.0, 10000.0, 100.0) var braking: float = 3000.0
@export_range(100.0, 10000.0, 100.0) var turn_acceleration: float = 3600.0
@export_range(1.0, 40.0, 0.5) var facing_response: float = 18.0
@export_group("Dash")
@export_range(400.0, 2000.0, 10.0) var dash_speed: float = 1150.0
@export_range(0.08, 0.4, 0.01) var dash_duration: float = 0.18
@export_range(0.2, 3.0, 0.05) var dash_cooldown: float = 0.65

@export_range(1, 8, 1) var base_dash_charges: int = 1
@export_range(0.1, 1.0, 0.05) var minimum_dash_cooldown: float = 0.2

@export_group("Health")
@export_range(1, 10000, 1) var max_hp: int = 100
@export_group("Incoming Hit Feedback")
@export_range(0.1, 2.0, 0.05) var hit_grace_period: float = 0.45

@onready var _visual: ShapeVisual = $ShapeVisual
@onready var _dash_feedback: DashFeedback = $DashFeedback
@onready var shooter: AutoShooter = $AutoShooter

var _current_hp: int = 100
var touch_input_enabled: bool = false
var touch_move: Vector2 = Vector2.ZERO
var touch_aim: Vector2 = Vector2.ZERO
var hits_taken: int = 0
var _hurt_remaining: float = 0.0

var _spawn_position: Vector2
var _using_controller: bool = false
var control_mode: ControlMode = ControlMode.DIRECTIONAL
var _dash_remaining: float = 0.0
var _cooldown_remaining: float = 0.0
var _dash_charges: int = 1
var _dash_capacity: int = 1
var _dash_recharge_time: float = 0.65
var _dash_direction: Vector2 = Vector2.UP
var _last_direction: Vector2 = Vector2.UP
var _last_aim: Vector2 = Vector2.UP

var current_hp: int:
	get: return _current_hp

var is_alive: bool:
	get: return _current_hp > 0

var is_dashing: bool:
	get: return _dash_remaining > 0.0

var dash_cooldown_remaining: float:
	get: return _cooldown_remaining

var dash_charges: int:
	get: return _dash_charges

var max_dash_charges: int:
	get: return _dash_capacity

var effective_dash_cooldown: float:
	get: return _dash_recharge_time

func _ready() -> void:
	_spawn_position = global_position
	_current_hp = maxi(1, max_hp)
	_dash_capacity = clampi(base_dash_charges, 1, 8)
	_dash_charges = _dash_capacity
	_dash_recharge_time = maxf(minimum_dash_cooldown, dash_cooldown)
	shooter.modifiers_changed.connect(_refresh_dash_upgrades)

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadMotion:
		if absf((event as InputEventJoypadMotion).axis_value) > 0.2:
			_using_controller = true
	elif event is InputEventJoypadButton and event.is_pressed():
		_using_controller = true
	elif event is InputEventKey and event.is_pressed():
		_using_controller = false
	elif event is InputEventMouseMotion:
		if (event as InputEventMouseMotion).relative.length_squared() > 1.0:
			_using_controller = false

func _physics_process(delta: float) -> void:
	_hurt_remaining = maxf(0.0, _hurt_remaining - delta)
	_visual.modulate = Color.WHITE.lerp(Color(1.0, 0.25, 0.2), minf(_hurt_remaining * 3.0, 0.65))
	if not is_alive:
		velocity = Vector2.ZERO
		_visual.modulate = Color(0.4, 0.22, 0.2)
		return
	(_visual.material as ShaderMaterial).set_shader_parameter("flash", clampf(_hurt_remaining / hit_grace_period, 0.0, 1.0) * 0.85)
	shooter.aim_direction = shooting_direction()
	_update_dash_recharge(delta)
	var direction: Vector2 = _movement_input()
	if not direction.is_zero_approx(): _last_direction = direction.normalized()
	if is_dashing:
		_update_dash(delta)
		return
	_visual.scale = _visual.scale.lerp(Vector2.ONE, 1.0 - exp(-24.0 * delta))
	var target_velocity: Vector2 = direction * max_speed
	var response: float = acceleration
	if direction.is_zero_approx():
		response = braking
	elif velocity.dot(direction) < 0.0:
		response = turn_acceleration
	velocity = velocity.move_toward(target_velocity, response * delta)
	if move_and_slide(): $WallSound.trigger()
	if velocity.length() > 60.0: $MoveSound.trigger()
	var facing: Vector2 = _facing_input(direction)
	if not facing.is_zero_approx():
		var target_angle: float = facing.angle() + PI / 2.0
		_visual.rotation = lerp_angle(_visual.rotation, target_angle,
			1.0 - exp(-facing_response * delta))

func reset_to_spawn() -> void:
	$ResetSound.trigger()
	_current_hp = maxi(1, max_hp)
	shooter.firing_blocked = false
	health_changed.emit(_current_hp, max_hp)
	hits_taken = 0
	_hurt_remaining = 0.0
	_visual.modulate = Color.WHITE
	(_visual.material as ShaderMaterial).set_shader_parameter("flash", 0.0)
	_finish_dash()
	_cooldown_remaining = 0.0
	_dash_charges = _dash_capacity
	_dash_feedback.reset()
	_last_direction = Vector2.UP
	global_position = _spawn_position
	velocity = Vector2.ZERO
	_visual.rotation = 0.0
	_visual.scale = Vector2.ONE
	reset_physics_interpolation()
	reset_performed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dash") and not event.is_echo():
		try_dash()
		get_viewport().set_input_as_handled()

func try_dash() -> bool:
	if get_tree().paused or not is_alive or is_dashing or _dash_charges <= 0: return false
	var direction: Vector2 = _movement_input()
	if direction.is_zero_approx(): direction = _facing_input(Vector2.ZERO)
	if direction.is_zero_approx(): direction = _last_direction
	_dash_direction = direction.normalized()
	_dash_remaining = dash_duration
	# Spending another charge does not restart an already-running recharge.
	if _dash_charges == _dash_capacity: _cooldown_remaining = _dash_recharge_time
	_dash_charges -= 1
	_visual.rotation = _dash_direction.angle() + PI / 2.0
	_dash_feedback.begin(_dash_direction)
	$DashSound.trigger()
	dash_started.emit()
	return true

func _update_dash(delta: float) -> void:
	# A fast attack with an eased tail lands at normal movement speed.
	# Integrate the curve over this tick rather than sampling it at the tick boundary.
	var start: float = _dash_remaining / dash_duration
	var end: float = maxf(0.0, _dash_remaining - delta) / dash_duration
	var boost_distance: float = (dash_speed - max_speed) * dash_duration / 1.7
	boost_distance *= pow(start, 1.7) - pow(end, 1.7)
	var speed: float = max_speed + boost_distance / delta
	velocity = _dash_direction * speed
	_visual.scale = _visual.scale.lerp(Vector2(0.8, 1.4), 1.0 - exp(-40.0 * delta))
	var collided: bool = move_and_slide()
	_dash_remaining = maxf(0.0, _dash_remaining - delta)
	if collided:
		$WallSound.trigger()
		velocity = Vector2.ZERO
	if collided or not is_dashing:
		velocity = velocity.limit_length(max_speed)
		_finish_dash(true)

func _finish_dash(completed: bool = false) -> void:
	var was_active: bool = is_dashing or completed
	_dash_remaining = 0.0
	if _dash_feedback != null: _dash_feedback.finish()
	if was_active: dash_finished.emit()

func _movement_input() -> Vector2:
	var controller: Vector2 = Input.get_vector("pad_left", "pad_right", "pad_up", "pad_down")
	if not controller.is_zero_approx(): return controller
	if touch_input_enabled: return touch_move.limit_length()
	if control_mode == ControlMode.CURSOR_STEERING:
		if Input.is_action_pressed("move_up"):
			return _cursor_direction()
		return Vector2.ZERO
	# Combine keyboard schemes before limiting length so diagonals never gain speed.
	var direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	direction += Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	return direction.limit_length()

func _facing_input(movement: Vector2) -> Vector2:
	var aim: Vector2 = Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	if not aim.is_zero_approx(): return aim
	if touch_input_enabled:
		if not touch_aim.is_zero_approx(): return touch_aim
		return touch_move if not touch_move.is_zero_approx() else _last_aim
	var controller: Vector2 = Input.get_vector("pad_left", "pad_right", "pad_up", "pad_down")
	if not controller.is_zero_approx(): return movement
	if not _using_controller:
		return _cursor_direction()
	return movement

func shooting_direction() -> Vector2:
	var aim: Vector2 = Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	if aim.is_zero_approx():
		if touch_input_enabled:
			aim = touch_aim if not touch_aim.is_zero_approx() else touch_move
		elif _using_controller: aim = _movement_input()
		else: aim = _cursor_direction()
	if not aim.is_zero_approx(): _last_aim = aim.normalized()
	return _last_aim

func _cursor_direction() -> Vector2:
	var offset: Vector2 = get_global_mouse_position() - global_position
	# Avoid jitter when the cursor is directly over the player.
	if offset.length_squared() < 64.0: return Vector2.ZERO
	return offset.normalized()

func _update_dash_recharge(delta: float) -> void:
	if get_tree().paused or _dash_charges >= _dash_capacity: return
	_cooldown_remaining -= delta
	while _cooldown_remaining <= 0.00001 and _dash_charges < _dash_capacity:
		_dash_charges += 1
		if _dash_charges < _dash_capacity: _cooldown_remaining += _dash_recharge_time
		else: _cooldown_remaining = 0.0

func _refresh_dash_upgrades() -> void:
	var previous_capacity: int = _dash_capacity
	var previous_interval: float = _dash_recharge_time
	_dash_capacity = clampi(base_dash_charges + shooter.dash_charge_bonus, 1, 8)
	_dash_recharge_time = maxf(minimum_dash_cooldown,
		dash_cooldown * (1.0 - clampf(shooter.dash_cooldown_reduction, 0.0, 0.8)))
	# Grant only newly added slots; existing spent charges keep their progress.
	_dash_charges = clampi(_dash_charges + maxi(0, _dash_capacity - previous_capacity), 0, _dash_capacity)
	if _dash_charges >= _dash_capacity:
		_cooldown_remaining = 0.0
	else:
		_cooldown_remaining *= _dash_recharge_time / maxf(previous_interval, 0.001)

## Enemy contact and projectiles share health, feedback and one grace window.
func receive_enemy_hit(amount: int, source_position: Vector2 = Vector2.INF) -> bool:
	if get_tree().paused or not is_alive or amount <= 0 or _hurt_remaining > 0.0: return false
	var applied: int = mini(amount, _current_hp)
	_current_hp -= applied
	_hurt_remaining = hit_grace_period
	hits_taken += 1
	_visual.modulate = Color(1.0, 0.35, 0.25)
	(_visual.material as ShaderMaterial).set_shader_parameter("flash", 1.0)
	$IncomingHitSound.trigger()
	health_changed.emit(_current_hp, max_hp)
	hit_received.emit(applied)
	var direction: Vector2 = (source_position - global_position).normalized() if source_position.is_finite() else Vector2.ZERO
	damage_taken.emit(applied, direction)
	if not is_alive:
		_finish_dash()
		_dash_feedback.reset()
		velocity = Vector2.ZERO
		shooter.firing_blocked = true
		$DepletedSound.trigger()
		died.emit()
	return true

func heal(amount: int) -> int:
	if get_tree().paused or not is_alive or amount <= 0: return 0
	var restored: int = mini(amount, maxi(0, max_hp - _current_hp))
	if restored == 0: return 0
	_current_hp += restored
	health_changed.emit(_current_hp, max_hp)
	return restored
