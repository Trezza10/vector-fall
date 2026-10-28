extends SceneTree
var lab: Node2D
var player: PlaygroundPlayer
func _initialize() -> void:
	call_deferred("_check")
func _frames(count: int) -> void:
	for index: int in range(count): await physics_frame
func _place(at: Vector2) -> void:
	player.reset_to_spawn()
	player.global_position = at
	await _frames(3)
func _check() -> void:
	lab = load("res://features/movement_playground/movement_playground.tscn").instantiate()
	root.add_child(lab)
	player = lab.get_node("Player")
	player.shooter.auto_fire_enabled = false
	player.set_physics_process(false)
	player.incoming_status.set_physics_process(false)
	var field: Node2D = lab.get_node("EnvironmentField")
	for child: Node in field.get_children():
		if child is EnvironmentalObstacle: child.set_physics_process(false)
	await _frames(2)
	var spikes: EnvironmentalObstacle = field.get_node("StaticA")
	await _place(spikes.global_position)
	spikes._physics_process(0.01)
	assert(player.current_hp == 92 and spikes.phase == EnvironmentalObstacle.Phase.ACTIVE)
	spikes._physics_process(0.1)
	assert(player.current_hp == 92, "Hazards respect damage interval and hit grace")
	player._hurt_remaining = 0.0
	spikes._physics_process(0.5)
	assert(player.current_hp == 84, "Standing on static spikes remains dangerous")
	var trap: EnvironmentalObstacle = field.get_node("PressureA")
	trap.reset_obstacle()
	await _place(trap.global_position)
	assert(trap.z_index < player.z_index, "Floor plates must render beneath the player")
	assert(not trap.get_node("Danger").visible)
	trap._physics_process(0.01)
	assert(trap.phase == EnvironmentalObstacle.Phase.WARNING and player.current_hp == 100)
	player.global_position.x += 250.0
	await _frames(3)
	trap._physics_process(trap.warning_time + 0.01)
	assert(trap.phase == EnvironmentalObstacle.Phase.ACTIVE and trap.get_node("Danger").visible)
	assert(player.current_hp == 100, "Leaving the pressure plate during warning evades spikes")
	trap._physics_process(trap.active_time + 0.01)
	assert(trap.phase == EnvironmentalObstacle.Phase.COOLDOWN)
	trap._physics_process(trap.cooldown_time + 0.01)
	assert(trap.phase == EnvironmentalObstacle.Phase.DORMANT)
	await _place(trap.global_position)
	trap._physics_process(0.01)
	trap._physics_process(trap.warning_time + 0.01)
	assert(player.current_hp == 92, "Rearmed pressure spikes hurt if the player stays")
	var shock: EnvironmentalObstacle = field.get_node("ShockA")
	shock.reset_obstacle()
	await _place(shock.global_position)
	shock._physics_process(0.01)
	assert(player.current_hp == 100 and shock.phase == EnvironmentalObstacle.Phase.WARNING)
	shock._physics_process(shock.warning_time + 0.01)
	assert(player.current_hp == 97 and player.incoming_status.is_stunned and not player.try_dash())
	var remaining: float = shock.remaining
	var stun_time: float = player.incoming_status.stun_remaining
	shock.set_physics_process(true)
	player.incoming_status.set_physics_process(true)
	paused = true
	await create_timer(0.15).timeout
	assert(shock.remaining == remaining and player.incoming_status.stun_remaining == stun_time)
	paused = false
	shock.set_physics_process(false)
	player.incoming_status.set_physics_process(false)
	var gate: EnvironmentalObstacle = field.get_node("LaserGate")
	gate.reset_obstacle()
	await _place(gate.global_position)
	gate._physics_process(0.01)
	assert(player.current_hp == 100 and gate.phase == EnvironmentalObstacle.Phase.WARNING)
	gate._physics_process(gate.warning_time + 0.01)
	assert(player.current_hp == 94 and gate.get_node("Danger").visible)
	gate._physics_process(gate.active_time + 0.01)
	await _place(gate.global_position)
	gate._physics_process(0.01)
	assert(player.current_hp == 100 and gate.phase == EnvironmentalObstacle.Phase.COOLDOWN, "Inactive laser is safe to cross")
	var cover: StaticBody2D = field.get_node("CoverA")
	await _place(cover.global_position - Vector2(220, 0))
	var collision: KinematicCollision2D = player.move_and_collide(Vector2(300, 0))
	assert(collision != null and collision.get_collider() == cover)
	assert(player.global_position.x < cover.global_position.x - 80.0)
	await _place(cover.global_position - Vector2(300, 0))
	player.shooter.aim_direction = Vector2.RIGHT
	assert(player.shooter.fire_volley() == 1)
	await _frames(25)
	assert(lab.get_node("Projectiles").get_child_count() == 0, "Solid cover stops real player bullets")
	player.global_position += Vector2(0, 400)
	await _frames(2)
	var shot: EnemyProjectile = load("res://features/enemies/enemy_projectile.tscn").instantiate()
	shot.position = cover.global_position - Vector2(300, 0)
	shot.heading = Vector2.RIGHT
	shot.speed = 1800.0
	lab.get_node("EnemyProjectiles").add_child(shot)
	await _frames(15)
	assert(not is_instance_valid(shot), "Solid cover stops hostile rounds")
	lab.reset_playground()
	await _frames(2)
	assert(player.current_hp == player.max_hp and not player.incoming_status.is_stunned)
	assert(trap.phase == EnvironmentalObstacle.Phase.DORMANT and gate.phase == EnvironmentalObstacle.Phase.DORMANT)
	assert(not trap.get_node("Danger").visible and not gate.get_node("Danger").visible)
	assert(spikes.phase == EnvironmentalObstacle.Phase.ACTIVE)
	assert(lab.get_node("GridBackground").size.y == lab.get_node("Player/Camera2D").limit_bottom)
	print("PASS: static spike damage/grace; hidden spike warning/escape/rearm; shock/stun; paused timers; laser warning/live/safe crossing; physical cover and both projectile types; reset and expanded world bounds")
	lab.queue_free()
	await process_frame
	quit()
