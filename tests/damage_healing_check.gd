extends SceneTree

func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	var lab: Node2D = load("res://features/movement_playground/movement_playground.tscn").instantiate()
	root.add_child(lab)
	var player: PlaygroundPlayer = lab.get_node("Player")
	player.shooter.auto_fire_enabled = false
	for child: Node in lab.get_node("EnemyField").get_children():
		if child is PlaygroundEnemy: child.set_physics_process(false)
	await process_frame
	var feedback: PlayerDamageFeedback = lab.get_node("PlayerDamageFeedback")
	var camera: Camera2D = player.get_node("Camera2D")
	var bar: DamageHealthBar = lab.get_node("CanvasLayer/PlayerHealth")
	var repair: UpgradePickup = lab.get_node("Pickups/RepairEntrance")
	assert(repair.healing_amount == 25 and repair.respawn_seconds == 10.0)
	assert(not repair.try_collect(player) and repair.available, "Full HP never consumes a repair")
	assert(player.receive_enemy_hit(35, player.global_position - Vector2(100, 0)))
	assert(player.current_hp == 65 and feedback.get_node("DamageNumber").text == "-35 HP")
	assert(feedback.get_node("DirectionMarker").visible)
	var material: ShaderMaterial = feedback.get_node("Screen").material
	var direction: Vector2 = material.get_shader_parameter("hit_direction")
	assert(direction.x < -0.9 and absf(direction.y) < 0.01)
	feedback._process(0.03)
	assert(camera.offset.length() > 0.0 and camera.offset.length() <= feedback.shake_pixels + 0.001)
	var age: float = feedback._age
	assert(not player.receive_enemy_hit(1) and feedback._age == age)
	var offset: Vector2 = camera.offset
	paused = true
	await create_timer(0.12).timeout
	assert(feedback._age == age and camera.offset == offset)
	assert(player.heal(5) == 0 and not repair.try_collect(player))
	paused = false
	feedback.reset_feedback()
	assert(camera.offset == Vector2.ZERO and not feedback.get_node("DamageNumber").visible)
	# Real body overlap collects the existing reusable pickup in healing mode.
	player.global_position = repair.global_position
	player.reset_physics_interpolation()
	for frame: int in range(4): await physics_frame
	assert(not repair.available and player.current_hp == 90)
	assert(bar.modulate.g > bar.modulate.r and bar.modulate.g > bar.modulate.b)
	assert(bar.health_fraction < 0.9 and bar.health_fraction >= 0.65)
	assert(repair.get_node("PickupSound").playing)
	assert(not repair.try_collect(player) and player.shooter.modifier_stack_count(&"repair") == 0)
	await create_timer(0.6).timeout
	assert(is_equal_approx(bar.health_fraction, 0.9) and is_equal_approx(bar.damage_fraction, 0.9))
	assert(player.heal(999) == 10 and player.current_hp == 100)
	var fill: float = bar.health_fraction
	var tint: Color = bar.modulate
	paused = true
	await create_timer(0.12).timeout
	assert(bar.health_fraction == fill and bar.modulate == tint)
	paused = false
	await create_timer(0.7).timeout
	assert(bar.health_fraction == 1.0 and bar.modulate == Color.WHITE)
	assert(player.heal(1) == 0 and player.heal(0) == 0 and player.heal(-2) == 0)
	assert(player.receive_enemy_hit(90, player.global_position + Vector2(100, 0)))
	assert(float(material.get_shader_parameter("low_health")) > 0.0)
	assert((material.get_shader_parameter("hit_direction") as Vector2).x > 0.9)
	await create_timer(1.1).timeout
	assert(camera.offset == Vector2.ZERO and not feedback.get_node("DamageNumber").visible)
	assert(is_zero_approx(float(material.get_shader_parameter("strength"))))
	assert(player.heal(15) == 15)
	assert(is_zero_approx(float(material.get_shader_parameter("low_health"))))
	assert(player.receive_enemy_hit(1))
	assert(is_equal_approx(bar.health_fraction, 0.24), "Damage interrupts the healing fill immediately")
	assert(bar.modulate.r > bar.modulate.g, "Damage replaces the green pulse")
	while player._hurt_remaining > 0.0: await physics_frame
	player.receive_enemy_hit(1000)
	assert(not player.is_alive and player.heal(100) == 0)
	var reset: InputEventKey = InputEventKey.new()
	reset.physical_keycode = KEY_R
	reset.pressed = true
	lab._unhandled_key_input(reset)
	assert(camera.offset == Vector2.ZERO and bar.modulate == Color.WHITE)
	assert(bar.health_fraction == 1.0 and bar.damage_fraction == 1.0)
	assert(not feedback.get_node("DamageNumber").visible and not feedback.get_node("DirectionMarker").visible)
	assert(is_zero_approx(float(material.get_shader_parameter("strength"))))
	assert(is_zero_approx(float(material.get_shader_parameter("low_health"))))
	print("PASS: bounded shake, source direction, damage label/flash, grace rejection, pause/reset cleanup, real healing pickup, green bar fill/pulse, pickup sound, full/paused/dead rejection, HP clamp and low-health recovery")
	lab.queue_free()
	await create_timer(0.5).timeout
	quit()
