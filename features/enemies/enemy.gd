class_name PlaygroundEnemy
extends TargetDummy

const PROJECTILE_SCENE: PackedScene = preload("res://features/enemies/enemy_projectile.tscn")
enum Phase { HUNT, WINDUP, BURST, RECOVERY }

@export var definition: EnemyDefinition
@export var player_path: NodePath = ^"../../Player"
@export var projectile_parent_path: NodePath = ^"../../EnemyProjectiles"
@export var starts_dormant: bool = false
@export var split_children: Array[NodePath] = []
@export var split_offset: Vector2 = Vector2.ZERO

@onready var _warning: Line2D = $WarningRing
@onready var _aim_line: Line2D = $AimLine
@onready var _burst_trail: Line2D = $BurstTrail
@onready var _burst_particles: CPUParticles2D = $BurstParticles

var _player: PlaygroundPlayer
var _projectile_parent: Node2D
var _home_position: Vector2
var _engaged: bool = false
var _returning_home: bool = false
var _phase: Phase = Phase.HUNT
var _phase_remaining: float = 0.0
var _attack_remaining: float = 0.0
var _burst_direction: Vector2 = Vector2.RIGHT
var _volley_index: int = 0
var _spiral_angle: float = 0.0
var _dormant: bool = false

func _ready() -> void:
	assert(definition != null, "Assign an EnemyDefinition.")
	max_hp = definition.health
	display_label = definition.display_name.to_upper()
	die_at_zero = true
	super._ready()
	_player = get_node_or_null(player_path) as PlaygroundPlayer
	_projectile_parent = get_node_or_null(projectile_parent_path) as Node2D
	_home_position = global_position
	if starts_dormant: deactivate()

func reset_health() -> void:
	super.reset_health()
	_engaged = false
	_returning_home = false
	_phase = Phase.HUNT
	_phase_remaining = 0.0
	_attack_remaining = definition.attack_interval if definition != null else 1.0
	_volley_index = 0
	_spiral_angle = 0.0
	if is_node_ready():
		_clear_attack_visuals()
		for path: NodePath in split_children:
			var child: PlaygroundEnemy = get_node_or_null(path) as PlaygroundEnemy
			if child != null and child.is_node_ready(): child.deactivate()

func _physics_process(delta: float) -> void:
	if get_tree().paused or _dead or _dormant or _player == null: return
	if _push_velocity.length_squared() >= 1.0:
		_cancel_burst()
		super._physics_process(delta)
		return
	if statuses.is_stunned:
		_cancel_burst()
		velocity = Vector2.ZERO
		return
	var to_player: Vector2 = _player.global_position - global_position
	if global_position.distance_to(_home_position) > definition.leash_radius:
		_returning_home = true
		_engaged = false
	if _returning_home:
		_cancel_burst()
		_move_toward(_home_position, definition.move_speed, delta, 8.0)
		if global_position.distance_to(_home_position) < 10.0: _returning_home = false
		return
	if not _engaged and to_player.length() <= definition.activation_radius:
		_engaged = true
	if to_player.length() > definition.activation_radius * 1.6:
		_engaged = false
	if not _engaged:
		_cancel_burst()
		_move_toward(_home_position, definition.move_speed, delta, 8.0)
		return
	_attack_remaining -= delta
	match definition.kind:
		EnemyDefinition.Kind.POISON_LOBBER, EnemyDefinition.Kind.STUNNER, EnemyDefinition.Kind.REPULSOR, EnemyDefinition.Kind.FIRE_DASH, EnemyDefinition.Kind.LASER, EnemyDefinition.Kind.LINKED_ARTILLERY:
			_update_advanced(delta)
		EnemyDefinition.Kind.SILENCER:
			_update_silencer(delta)
		EnemyDefinition.Kind.RADIAL, EnemyDefinition.Kind.SPIRAL:
			velocity = velocity.move_toward(Vector2.ZERO, definition.acceleration * delta)
			_update_shooting()
		EnemyDefinition.Kind.DASHER, EnemyDefinition.Kind.CHARGER:
			_update_burst(delta, to_player.normalized())
		_:
			_move_toward(_player.global_position, definition.move_speed, delta, definition.contact_radius - 3.0)
	if global_position.distance_to(_player.global_position) <= definition.contact_radius:
		_player.receive_enemy_hit(definition.contact_damage, global_position)

func _move_toward(target: Vector2, speed: float, delta: float, stop_distance: float) -> void:
	var offset: Vector2 = target - global_position
	var desired: Vector2 = offset.normalized() * speed * statuses.movement_multiplier if offset.length() > stop_distance else Vector2.ZERO
	velocity = velocity.move_toward(desired, definition.acceleration * delta)
	move_and_slide()
	if velocity.length_squared() > 4.0: _visual.rotation = lerp_angle(_visual.rotation, velocity.angle() + PI / 2.0, 1.0 - exp(-12.0 * delta))

func _update_burst(delta: float, to_player: Vector2) -> void:
	match _phase:
		Phase.HUNT:
			_move_toward(_player.global_position, definition.move_speed, delta, definition.contact_radius)
			if _attack_remaining <= 0.0:
				_burst_direction = to_player
				if definition.kind == EnemyDefinition.Kind.DASHER:
					_burst_direction = to_player.rotated(0.95 if _volley_index % 2 == 0 else -0.95)
				_phase = Phase.WINDUP
				_phase_remaining = definition.windup_time
				_warning.show()
				_aim_line.points = PackedVector2Array([Vector2.ZERO, _burst_direction * 130.0])
				_aim_line.show()
				$WindupSound.trigger()
		Phase.WINDUP:
			velocity = Vector2.ZERO
			_phase_remaining -= delta
			_warning.scale = Vector2.ONE * (1.0 + 0.25 * sin(_phase_remaining * 25.0))
			if _phase_remaining <= 0.0:
				_phase = Phase.BURST
				_phase_remaining = definition.burst_duration
				_warning.hide()
				_aim_line.hide()
				_burst_particles.emitting = true
				$BurstSound.trigger()
		Phase.BURST:
			_phase_remaining -= delta
			velocity = _burst_direction * definition.burst_speed * statuses.movement_multiplier
			_visual.rotation = _burst_direction.angle() + PI / 2.0
			var collided: bool = move_and_slide()
			_burst_trail.add_point(global_position)
			while _burst_trail.get_point_count() > 10: _burst_trail.remove_point(0)
			if collided or _phase_remaining <= 0.0:
				velocity = velocity.limit_length(definition.move_speed)
				_phase = Phase.RECOVERY
				_phase_remaining = definition.recovery_time
				_clear_attack_visuals()
		Phase.RECOVERY:
			velocity = velocity.move_toward(Vector2.ZERO, definition.acceleration * delta * 2.0)
			move_and_slide()
			_phase_remaining -= delta
			if _phase_remaining <= 0.0:
				_phase = Phase.HUNT
				_attack_remaining = definition.attack_interval
				_volley_index += 1

func _update_shooting() -> void:
	if definition.kind == EnemyDefinition.Kind.RADIAL:
		_warning.visible = _attack_remaining <= 0.3
		_warning.scale = Vector2.ONE * (1.1 + 0.15 * sin(_attack_remaining * 25.0))
	if _attack_remaining > 0.0: return
	fire_pattern()
	_attack_remaining = maxf(0.05, definition.attack_interval)

func fire_pattern() -> PackedFloat32Array:
	var angles: PackedFloat32Array = []
	if get_tree().paused or _dead or _dormant: return angles
	if definition.kind == EnemyDefinition.Kind.RADIAL:
		var count: int = clampi(definition.bullet_count, 1, 32)
		var offset: float = PI / float(count) if _volley_index % 2 == 1 else 0.0
		for index: int in range(count): angles.append(TAU * float(index) / float(count) + offset)
	else:
		angles.append(_spiral_angle)
		_spiral_angle = fposmod(_spiral_angle + deg_to_rad(definition.spiral_step_degrees), TAU)
	for angle: float in angles: _fire_projectile(angle)
	_volley_index += 1
	$ShotSound.trigger()
	return angles

func _fire_projectile(angle: float) -> void:
	if _projectile_parent == null: return
	var shot: EnemyProjectile = PROJECTILE_SCENE.instantiate() as EnemyProjectile
	shot.heading = Vector2.from_angle(angle)
	shot.speed = definition.bullet_speed
	shot.damage = definition.bullet_damage
	shot.remaining_lifetime = definition.bullet_lifetime
	shot.position = _projectile_parent.to_local(global_position + shot.heading * (definition.contact_radius - 12.0))
	_projectile_parent.add_child(shot)
	shot.reset_physics_interpolation()

func _cancel_burst() -> void:
	if _phase == Phase.WINDUP or _phase == Phase.BURST:
		velocity = velocity.limit_length(definition.move_speed)
		_phase = Phase.RECOVERY
		_phase_remaining = definition.recovery_time
	_clear_attack_visuals()

func _clear_attack_visuals() -> void:
	_warning.hide()
	_aim_line.hide()
	_burst_particles.emitting = false
	_burst_trail.clear_points()

func _die() -> void:
	_clear_attack_visuals()
	super._die()
	for path: NodePath in split_children:
		var child: PlaygroundEnemy = get_node_or_null(path) as PlaygroundEnemy
		if child != null: child.activate(global_position + child.split_offset)
	if not respawn_on_death: _label.hide()

func activate(at: Vector2) -> void:
	_dormant = false
	show()
	_label.show()
	global_position = at
	_home_position = at
	reset_physics_interpolation()
	reset_health()
	_engaged = true
	set_physics_process(true)

func deactivate() -> void:
	_dormant = true
	_dead = true
	_respawn_timer.stop()
	statuses.clear_effects()
	_damage_numbers.reset_numbers()
	_clear_attack_visuals()
	hide()
	set_deferred("collision_layer", 0)
	set_physics_process(false)
	set_process(false)

func reset_encounter() -> void:
	if starts_dormant:
		deactivate()
		return
	_dormant = false
	global_position = _spawn_position
	_home_position = _spawn_position
	reset_physics_interpolation()
	reset_health()
	_label.show()
	show()
	set_physics_process(true)

func _update_silencer(delta: float) -> void:
	if _phase == Phase.WINDUP:
		velocity = Vector2.ZERO
		_phase_remaining -= delta
		_warning.scale = Vector2.ONE * definition.silence_radius / 43.0
		_warning.modulate.a = 0.45 + 0.5 * absf(sin(_phase_remaining * 12.0))
		if _phase_remaining <= 0.0:
			if _player.is_alive and global_position.distance_to(_player.global_position) <= definition.silence_radius:
				_player.shooter.apply_silence(definition.silence_duration)
			$BurstSound.trigger()
			_phase = Phase.RECOVERY
			_phase_remaining = 0.3
	elif _phase == Phase.RECOVERY:
		_phase_remaining -= delta
		_warning.scale += Vector2.ONE * delta * 6.0
		_warning.modulate.a = maxf(0.0, _phase_remaining / 0.3)
		if _phase_remaining <= 0.0:
			_phase = Phase.HUNT
			_attack_remaining = definition.attack_interval
			_warning.hide()
	else:
		_move_toward(_player.global_position, definition.move_speed, delta, definition.silence_radius * 0.75)
		if _attack_remaining <= 0.0 and global_position.distance_to(_player.global_position) <= definition.silence_radius:
			_phase = Phase.WINDUP
			_phase_remaining = definition.windup_time
			_warning.default_color = Color(0.8, 0.4, 1.0)
			_warning.scale = Vector2.ONE * definition.silence_radius / 43.0
			_warning.show()
			$WindupSound.trigger()

func _update_advanced(_delta: float) -> void:
	pass
