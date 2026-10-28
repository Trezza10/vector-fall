class_name AdvancedEnemy
extends PlaygroundEnemy
const POOL: PackedScene = preload("res://features/enemies/ground_hazard.tscn")
@export var life_link_path: NodePath
var _laser_direction: Vector2 = Vector2.RIGHT
var _trail_carry: float = 0.0
var linked_shield_active: bool:
	get:
		var link: TargetDummy = get_node_or_null(life_link_path) as TargetDummy if not life_link_path.is_empty() else null
		return link != null and link.is_alive
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if definition.kind != EnemyDefinition.Kind.LINKED_ARTILLERY: return
	$ShieldRing.visible = not _dead and linked_shield_active
	$LifeLinkBeam.visible = not _dead and linked_shield_active
	if not _dead:
		_label.text = "LINK SHIELDED" if linked_shield_active else "EXPOSED / ARTILLERY"
		if linked_shield_active:
			var link: Node2D = get_node(life_link_path) as Node2D
			$LifeLinkBeam.points = PackedVector2Array([Vector2.ZERO, to_local(link.global_position)])
func apply_damage(amount: int, source: DamageSource.Kind = DamageSource.Kind.BULLET) -> int:
	if linked_shield_active:
		$ShieldRing.modulate = Color(1, 0.65, 1)
		return 0
	return super.apply_damage(amount, source)
func _commit_damage(amount: int, source: DamageSource.Kind) -> int:
	if linked_shield_active: return 0
	return super._commit_damage(amount, source)
func apply_status(effect: StatusEffectDefinition, direction: Vector2) -> void:
	if not linked_shield_active: super.apply_status(effect, direction)
func reset_health() -> void:
	super.reset_health()
	_trail_carry = 0.0
	if not life_link_path.is_empty():
		var link: TargetDummy = get_node_or_null(life_link_path) as TargetDummy
		if link != null and link.is_node_ready(): link.reset_health()
	if is_node_ready(): $Laser.hide()
func _clear_attack_visuals() -> void:
	super._clear_attack_visuals()
	if is_node_ready(): $Laser.hide()
func _die() -> void:
	super._die()
	$ShieldRing.hide()
	$LifeLinkBeam.hide()
func _update_advanced(delta: float) -> void:
	var offset: Vector2 = _player.global_position - global_position
	if definition.kind == EnemyDefinition.Kind.FIRE_DASH:
		var before: Vector2 = global_position
		var was_burst: bool = _phase == Phase.BURST
		_update_burst(delta, offset.normalized())
		if was_burst:
			var traveled: float = before.distance_to(global_position)
			_trail_carry += traveled
			var spacing: float = maxf(10.0, definition.trail_spacing)
			while _trail_carry >= spacing:
				_trail_carry -= spacing
				_spawn_fire(global_position - _burst_direction * _trail_carry)
		return
	if definition.kind == EnemyDefinition.Kind.LASER:
		_update_laser(delta)
		return
	_move_toward(_player.global_position, definition.move_speed, delta, definition.attack_range * 0.7)
	if _attack_remaining <= 0.0 and offset.length() <= definition.attack_range:
		fire_advanced_volley()
		_attack_remaining = definition.attack_interval
func fire_advanced_volley() -> int:
	if get_tree().paused or _dead or _projectile_parent == null: return 0
	var offset: Vector2 = _player.global_position - global_position
	var direction: Vector2 = offset.normalized()
	if direction.is_zero_approx(): direction = Vector2.DOWN
	var count: int = 5 if definition.kind == EnemyDefinition.Kind.POISON_LOBBER else 1
	for index: int in range(count):
		var shot: EnemyProjectile = PROJECTILE_SCENE.instantiate() as EnemyProjectile
		shot.heading = direction.rotated((index - 2) * 0.18) if count == 5 else direction
		shot.position = _projectile_parent.to_local(global_position + shot.heading * 55.0)
		shot.speed = definition.bullet_speed
		shot.damage = definition.bullet_damage
		shot.remaining_lifetime = definition.bullet_lifetime
		match definition.kind:
			EnemyDefinition.Kind.POISON_LOBBER:
				shot.flight_duration = 1.1
				shot.hazard_radius = definition.hazard_radius
				shot.hazard_lifetime = definition.hazard_lifetime
				shot.landing_position = global_position + shot.heading * clampf(offset.length(), 200.0, definition.attack_range)
				shot.shot_color = Color(0.55, 1, 0.25)
			EnemyDefinition.Kind.STUNNER:
				shot.effect = PlayerStatus.Kind.STUN
				shot.effect_duration = definition.player_effect_duration
				shot.shot_color = Color(0.7, 0.4, 1)
				shot.visual_size = 1.5
				shot.collision_radius = 8.0
			EnemyDefinition.Kind.REPULSOR:
				shot.effect = PlayerStatus.Kind.KNOCKBACK
				shot.knockback_strength = definition.knockback_strength
				shot.shot_color = Color(0.25, 0.8, 1)
				shot.visual_size = 2.0
				shot.collision_radius = 10.0
			EnemyDefinition.Kind.LINKED_ARTILLERY:
				shot.visual_size = 4.0
				shot.collision_radius = 24.0
				shot.shot_color = Color(1.0, 0.25, 0.55)
		_projectile_parent.add_child(shot)
		shot.reset_physics_interpolation()
	$ShotSound.trigger()
	return count
func _spawn_fire(at: Vector2) -> void:
	var pool: GroundHazard = POOL.instantiate() as GroundHazard
	pool.position = _projectile_parent.to_local(at)
	pool.effect = PlayerStatus.Kind.BURN
	pool.radius = definition.hazard_radius
	pool.lifetime = definition.hazard_lifetime
	_projectile_parent.add_child(pool)
func _update_laser(delta: float) -> void:
	velocity = Vector2.ZERO
	match _phase:
		Phase.HUNT:
			if _attack_remaining <= 0.0 and global_position.distance_to(_player.global_position) <= definition.attack_range:
				_laser_direction = (_player.global_position - global_position).normalized()
				if _laser_direction.is_zero_approx(): _laser_direction = Vector2.DOWN
				_phase = Phase.WINDUP
				_phase_remaining = definition.windup_time
				$WindupSound.trigger()
		Phase.WINDUP:
			_phase_remaining -= delta
			if _phase_remaining <= 0.0:
				_phase = Phase.BURST
				_phase_remaining = definition.laser_duration
				$BurstSound.trigger()
		Phase.BURST:
			_phase_remaining -= delta
			if _phase_remaining <= 0.0:
				_phase = Phase.HUNT
				_attack_remaining = definition.attack_interval
				$Laser.hide()
				return
		Phase.RECOVERY:
			_phase_remaining -= delta
			if _phase_remaining <= 0.0:
				_phase = Phase.HUNT
				_attack_remaining = definition.attack_interval
	if _phase != Phase.WINDUP and _phase != Phase.BURST: return
	var endpoint: Vector2 = global_position + _laser_direction * definition.attack_range
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position, endpoint, 1, [_player.get_rid()])
	var wall: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	if not wall.is_empty(): endpoint = wall.position
	$Laser.points = PackedVector2Array([Vector2.ZERO, to_local(endpoint)])
	$Laser/Core.points = $Laser.points
	$Laser/Core.visible = _phase == Phase.BURST
	$Laser.width = 18.0 if _phase == Phase.BURST else 2.0
	$Laser.default_color = Color(1, 0.3, 0.3, 0.95 if _phase == Phase.BURST else 0.45)
	$Laser.show()
	if _phase == Phase.BURST:
		var closest: Vector2 = Geometry2D.get_closest_point_to_segment(_player.global_position, global_position, endpoint)
		if closest.distance_to(_player.global_position) <= 27.0:
			_player.receive_enemy_attack(definition.bullet_damage, global_position)
