extends SceneTree

func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	var lab: Node2D = load("res://features/movement_playground/movement_playground.tscn").instantiate()
	root.add_child(lab)
	var player: PlaygroundPlayer = lab.get_node("Player")
	player.shooter.auto_fire_enabled = false
	player.set_physics_process(false)
	var field: Node2D = lab.get_node("EnemyField")
	var enemies: Array[PlaygroundEnemy] = []
	for child: Node in field.get_children():
		if child is PlaygroundEnemy:
			var enemy: PlaygroundEnemy = child as PlaygroundEnemy
			enemy.set_physics_process(false)
			enemies.append(enemy)
	await physics_frame
	assert(enemies.size() == 8)
	var tank: PlaygroundEnemy = field.get_node("Bulwark")
	var runner: PlaygroundEnemy = field.get_node("Skitter")
	var radial: PlaygroundEnemy = field.get_node("Radial")
	var spiral: PlaygroundEnemy = field.get_node("Spiral")
	var charger: PlaygroundEnemy = field.get_node("Charger")
	var dasher: PlaygroundEnemy = field.get_node("Wisp")
	var splitter: PlaygroundEnemy = field.get_node("Splitter")
	assert(tank.max_hp == 240 and runner.max_hp == 15)
	assert(runner.get_node("CollisionShape2D").shape.radius < tank.get_node("CollisionShape2D").shape.radius)
	var origin: Vector2 = tank.global_position
	tank._physics_process(0.1)
	assert(tank.global_position == origin, "Distant enemies must stay idle at spawn")
	player.global_position = tank.global_position + Vector2(350, 0)
	var runner_origin: Vector2 = runner.global_position
	for index: int in range(30):
		tank._physics_process(1.0 / 60.0)
		runner._physics_process(1.0 / 60.0)
		await physics_frame
	assert(tank.global_position.distance_to(player.global_position) < origin.distance_to(player.global_position))
	assert(runner.global_position.distance_to(runner_origin) > tank.global_position.distance_to(origin) * 2.0)
	var ring_a: PackedFloat32Array = radial.fire_pattern()
	var ring_b: PackedFloat32Array = radial.fire_pattern()
	var ring_c: PackedFloat32Array = radial.fire_pattern()
	assert(ring_a.size() == 12 and ring_b.size() == 12)
	for index: int in range(12):
		assert(is_equal_approx(ring_b[index] - ring_a[index], PI / 12.0))
		assert(is_equal_approx(ring_c[index], ring_a[index]))
	var first: PackedFloat32Array = spiral.fire_pattern()
	var next: PackedFloat32Array = spiral.fire_pattern()
	assert(first.size() == 1 and is_equal_approx(next[0] - first[0], deg_to_rad(19.0)))
	await _clear_shots(lab)
	player.global_position = charger.global_position + Vector2(150, 0)
	charger._attack_remaining = 0.0
	charger._physics_process(0.01)
	assert(charger._phase == PlaygroundEnemy.Phase.WINDUP and charger.get_node("AimLine").visible)
	var locked: Vector2 = charger._burst_direction
	player.global_position += Vector2(0, -150)
	charger._physics_process(charger.definition.windup_time + 0.01)
	assert(charger._phase == PlaygroundEnemy.Phase.BURST and charger._burst_direction == locked)
	var charge_origin: Vector2 = charger.global_position
	await physics_frame
	charger._physics_process(0.02)
	assert(charger.global_position.distance_to(charge_origin) > 10.0 and charger.velocity.length() > 600.0)
	var stun: StatusEffectDefinition = load("res://data/effects/stun.tres")
	charger.apply_status(stun, Vector2.RIGHT)
	charger._physics_process(0.1)
	assert(charger._phase == PlaygroundEnemy.Phase.RECOVERY and charger.velocity == Vector2.ZERO)
	assert(not charger.get_node("AimLine").visible and not charger.get_node("BurstParticles").emitting)
	player.global_position = dasher.global_position + Vector2(150, 0)
	dasher._attack_remaining = 0.0
	dasher._physics_process(0.01)
	assert(dasher._phase == PlaygroundEnemy.Phase.WINDUP and absf(dasher._burst_direction.y) > 0.5)
	var timer: float = dasher._phase_remaining
	dasher.set_physics_process(true)
	paused = true
	assert(radial.fire_pattern().is_empty())
	assert(not player.receive_enemy_hit(1))
	await create_timer(0.1).timeout
	assert(dasher._phase_remaining == timer)
	paused = false
	dasher.set_physics_process(false)
	# Chill scales real pursuit velocity rather than only changing presentation.
	tank.velocity = Vector2.ZERO
	player.global_position = tank.global_position + Vector2(100, 0)
	var ice: StatusEffectDefinition = load("res://data/effects/ice.tres")
	tank.apply_status(ice, Vector2.RIGHT)
	tank._physics_process(0.2)
	assert(tank.velocity.length() < tank.definition.move_speed and tank.velocity.length() > 0.0)
	assert(tank.apply_damage(10, DamageSource.Kind.CRITICAL) == 10)
	assert(tank.get_node("DamageNumbers/Critical").displayed_damage == 10)
	# Split into the three authored fragments; fragments never split or respawn themselves.
	var minis: Node2D = field.get_node("SplitMinis")
	for mini: PlaygroundEnemy in minis.get_children(): assert(not mini.is_alive and not mini.visible)
	var split_position: Vector2 = splitter.global_position
	splitter.apply_damage(10000)
	assert(not splitter.is_alive and minis.get_child_count() == 3)
	for mini: PlaygroundEnemy in minis.get_children():
		assert(mini.is_alive and mini.visible and mini.max_hp == 12)
		assert(mini.global_position == split_position + mini.split_offset)
		mini.set_physics_process(false)
	var mini: PlaygroundEnemy = minis.get_child(0)
	mini.apply_damage(100)
	assert(not mini.is_alive and mini.get_node("RespawnTimer").is_stopped())
	splitter._on_respawn_timeout()
	assert(splitter.is_alive)
	for fragment: PlaygroundEnemy in minis.get_children(): assert(not fragment.is_alive)
	# Hostile shots use real swept collision against player and walls.
	player.reset_to_spawn()
	var shot: EnemyProjectile = load("res://features/enemies/enemy_projectile.tscn").instantiate()
	shot.position = player.global_position - Vector2(90, 0)
	shot.heading = Vector2.RIGHT
	shot.speed = 900.0
	lab.get_node("EnemyProjectiles").add_child(shot)
	paused = true
	var frozen_shot: Vector2 = shot.position
	var frozen_lifetime: float = shot.remaining_lifetime
	await create_timer(0.12).timeout
	assert(shot.position == frozen_shot and shot.remaining_lifetime == frozen_lifetime)
	paused = false
	for frame: int in range(12): await physics_frame
	assert(player.hits_taken == 1 and not is_instance_valid(shot))
	assert(not player.receive_enemy_hit(1), "Grace window prevents contact-hit spam")
	var wall_shot: EnemyProjectile = load("res://features/enemies/enemy_projectile.tscn").instantiate()
	wall_shot.position = Vector2(7150, 900)
	wall_shot.heading = Vector2.RIGHT
	wall_shot.speed = 900.0
	lab.get_node("EnemyProjectiles").add_child(wall_shot)
	for frame: int in range(8): await physics_frame
	assert(not is_instance_valid(wall_shot))
	# Existing player rounds and on-hit effects work against an actual enemy body.
	player.global_position = Vector2(450, 950)
	tank.global_position = Vector2(450, 800)
	tank.reset_health()
	await physics_frame
	var shooter: AutoShooter = player.shooter
	shooter.aim_direction = Vector2.UP
	shooter.active_weapon.projectile.crit_chance = 1.0
	shooter.active_weapon.projectile.on_hit_effects.append(load("res://data/effects/burn.tres"))
	shooter.fire_volley()
	for frame: int in range(18): await physics_frame
	assert(tank.current_hp == tank.max_hp - 10)
	assert(tank.statuses.has_effect(StatusEffectDefinition.Kind.BURN))
	var reset_key: InputEventKey = InputEventKey.new()
	reset_key.physical_keycode = KEY_R
	reset_key.pressed = true
	lab._unhandled_key_input(reset_key)
	await process_frame
	assert(player.hits_taken == 0 and lab.get_node("EnemyProjectiles").get_child_count() == 0)
	for enemy: PlaygroundEnemy in enemies:
		assert(enemy.is_alive and enemy.current_hp == enemy.max_hp and not enemy._engaged)
	print("PASS: eight authored archetypes, HP/size/speed differences, range activation, pursuit, alternating half-step rings, spiral angles, locked charge windup/burst, evasive dash, stun/chill, critical damage, fixed splitting, nonrespawning fragments, real hostile hits/walls, grace, pause and encounter reset")
	lab.queue_free()
	await create_timer(0.5).timeout
	quit()

func _clear_shots(lab: Node2D) -> void:
	for shot: Node in lab.get_node("EnemyProjectiles").get_children(): shot.queue_free()
	await process_frame
