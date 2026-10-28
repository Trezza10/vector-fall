extends SceneTree

var _lab: Node2D
var _shooter: AutoShooter
var _volley_count: int = 0

func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	var packed: PackedScene = load("res://features/movement_playground/movement_playground.tscn")
	_lab = packed.instantiate()
	root.add_child(_lab)
	await process_frame
	var player: PlaygroundPlayer = _lab.get_node("Player")
	_shooter = player.shooter
	_shooter.auto_fire_enabled = false
	await _clear_shots()
	var preset: WeaponDefinition = _shooter.arsenal[0]
	assert(_shooter.active_weapon != preset)
	assert(_shooter.active_weapon.projectile != preset.projectile)
	assert(_shooter.active_weapon.projectile.colors != preset.projectile.colors)
	assert(_shooter.active_weapon.projectile.shape != preset.projectile.shape)
	_shooter.active_weapon.bullet_count = 2
	_shooter.active_weapon.projectile.damage = 7
	_shooter.active_weapon.projectile.colors.fill = Color.RED
	assert(preset.bullet_count == 1 and preset.projectile.damage == 5)
	assert(preset.projectile.colors.fill != Color.RED)
	_shooter.select_weapon(1)
	var angles: PackedFloat32Array = _shooter.active_weapon.spread_angles()
	assert(angles.size() == 3 and is_zero_approx(angles[1]))
	assert(is_equal_approx(angles[0], -angles[2]))
	_shooter.select_weapon(0)
	assert(_shooter.active_weapon.projectile.damage == 5, "Rebuilding starts from clean base data")
	_shooter.active_weapon.bullet_count = 1
	_shooter.active_weapon.projectile.damage = 5
	var dummy: TargetDummy = _lab.get_node("TargetDummies/DummyCenter")
	_shooter.aim_direction = Vector2.UP
	assert(_shooter.fire_volley() == 1)
	_shooter.active_weapon.projectile.damage = 99
	await _frames(30)
	assert(dummy.current_hp == 999995, "In-flight volley keeps its damage snapshot")
	_shooter.active_weapon.projectile.damage = 5
	await _clear_shots()
	var shot_target: TargetDummy = _lab.get_node("LiveTargets/LiveRight")
	_shooter.aim_direction = (shot_target.global_position - player.global_position).normalized()
	for volley: int in range(4): _shooter.fire_volley()
	await _frames(30)
	assert(not shot_target.is_alive and shot_target.current_hp == 0, "Real bullets must kill a 20-HP target")
	shot_target.reset_health()
	await _clear_shots()
	_shooter.aim_direction = Vector2.RIGHT
	_shooter.fire_volley()
	var active_bullet: CombatProjectile = _lab.get_node("Projectiles").get_child(0) as CombatProjectile
	var bullet_position: Vector2 = active_bullet.global_position
	paused = true
	assert(_shooter.fire_volley() == 0)
	await create_timer(0.15).timeout
	assert(active_bullet.global_position == bullet_position, "Active projectiles freeze during pause")
	paused = false
	await _clear_shots()
	var live: TargetDummy = _lab.get_node("LiveTargets/LiveCenter")
	var shot_visual: ShapeVisual = shot_target.get_node("ShapeVisual")
	var live_visual: ShapeVisual = live.get_node("ShapeVisual")
	assert(shot_visual.material != live_visual.material, "Hit shaders must be per-instance")
	assert(live.max_hp == 20 and live.respawn_delay == 5.0)
	var bar: DamageHealthBar = live.get_node("HealthBar")
	assert(live.apply_damage(5) == 5)
	assert(is_equal_approx(bar.health_fraction, 0.75))
	assert(is_equal_approx(bar.damage_fraction, 1.0), "Chip bar delays damage")
	await create_timer(0.3).timeout
	assert(bar.damage_fraction > 0.75 and bar.damage_fraction < 1.0)
	live.apply_damage(5)
	assert(is_equal_approx(bar.health_fraction, 0.5))
	assert(bar.damage_fraction > bar.health_fraction, "Repeated hits keep a visible chip")
	var frozen_chip: float = bar.damage_fraction
	paused = true
	await create_timer(0.15).timeout
	assert(is_equal_approx(bar.damage_fraction, frozen_chip))
	paused = false
	live.apply_damage(50)
	await _frames(1)
	assert(not live.is_alive and live.collision_layer == 0)
	assert(not live.get_node("ShapeVisual").visible)
	assert(live.apply_damage(5) == 0)
	var timer: Timer = live.get_node("RespawnTimer")
	var frozen_time: float = timer.time_left
	paused = true
	await create_timer(0.15).timeout
	assert(is_equal_approx(timer.time_left, frozen_time), "Respawn pauses with gameplay")
	paused = false
	Engine.time_scale = 10.0
	await create_timer(4.5).timeout
	assert(not live.is_alive, "Must not respawn early")
	await create_timer(0.7).timeout
	Engine.time_scale = 1.0
	assert(live.is_alive and live.current_hp == 20 and live.collision_layer == 2)
	assert(is_equal_approx(bar.health_fraction, 1.0) and is_equal_approx(bar.damage_fraction, 1.0))
	# Align three targets to test one hit per body and two extra penetrations.
	var targets: Array[TargetDummy] = []
	for child: Node in _lab.get_node("TargetDummies").get_children():
		var target: TargetDummy = child as TargetDummy
		target.reset_health()
		target.position = Vector2(1200, 650 - targets.size() * 100)
		targets.append(target)
	await _frames(2)
	_shooter.select_weapon(2)
	_shooter.aim_direction = Vector2.UP
	_shooter.fire_volley()
	await _frames(30)
	for target: TargetDummy in targets:
		assert(target.current_hp == 999988, "Piercing hits each body once")
	await _clear_shots()
	# A very fast shot must stop at the arena wall before reaching an outside target.
	player.position = Vector2(2300, 800)
	player.reset_physics_interpolation()
	targets[0].position = Vector2(2430, 800)
	targets[0].reset_health()
	await _frames(2)
	_shooter.active_weapon.projectile.speed = 100000.0
	_shooter.aim_direction = Vector2.RIGHT
	_shooter.fire_volley()
	await _frames(3)
	assert(targets[0].current_hp == 1000000, "Swept shots cannot tunnel through walls")
	await _clear_shots()
	_shooter.select_weapon(0)
	_shooter.volley_fired.connect(_on_volley_fired)
	_shooter.auto_fire_enabled = true
	await _frames(60)
	_shooter.auto_fire_enabled = false
	assert(_volley_count >= 5 and _volley_count <= 6, "Attack rate must match its resource")
	await _clear_shots()
	print("PASS: nested upgrade isolation, arsenal retention, symmetric spread, in-flight snapshot, real projectile damage, chip bars, pause, death, 5-second respawn, piercing, wall sweep, attack rate")
	quit()

func _clear_shots() -> void:
	for shot: Node in _lab.get_node("Projectiles").get_children(): shot.queue_free()
	await process_frame
	await process_frame

func _frames(count: int) -> void:
	for index: int in range(count):
		await physics_frame
	await process_frame

func _on_volley_fired(_count: int) -> void:
	_volley_count += 1
