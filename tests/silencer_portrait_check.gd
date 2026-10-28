extends SceneTree
func _initialize() -> void:
	call_deferred("_check")
func _check() -> void:
	var lab: Node2D = load("res://features/movement_playground/movement_playground.tscn").instantiate()
	root.add_child(lab)
	var player: PlaygroundPlayer = lab.get_node("Player")
	player.set_physics_process(false)
	player.shooter.set_physics_process(false)
	player.shooter.auto_fire_enabled = false
	for enemy: Node in lab.get_node("EnemyField").get_children():
		if enemy is PlaygroundEnemy: enemy.set_physics_process(false)
	var enemy: PlaygroundEnemy = lab.get_node("EnemyField/Silencer")
	player.global_position = enemy.global_position + Vector2(150, 0)
	enemy._attack_remaining = 0.0
	enemy._physics_process(0.01)
	assert(enemy._phase == PlaygroundEnemy.Phase.WINDUP)
	assert(enemy.get_node("WarningRing").visible)
	assert(player.shooter.silence_remaining == 0.0)
	# Escape during the warning avoids silence.
	player.global_position += Vector2(200, 0)
	enemy._physics_process(1.0)
	assert(player.shooter.silence_remaining == 0.0)
	enemy.reset_encounter()
	player.global_position = enemy.global_position + Vector2(150, 0)
	enemy._attack_remaining = 0.0
	enemy._physics_process(0.01)
	enemy._physics_process(1.0)
	assert(player.shooter.silence_remaining == 2.5)
	assert(player.shooter.fire_volley() == 0)
	assert(player.try_dash(), "Silence must allow dash")
	paused = true
	await create_timer(0.1).timeout
	assert(player.shooter.silence_remaining == 2.5)
	paused = false
	player.shooter._physics_process(2.6)
	assert(player.shooter.silence_remaining == 0.0)
	assert(player.shooter.fire_volley() > 0, "Firing resumes after silence")
	player.shooter.apply_silence(2.5)
	player.reset_to_spawn()
	assert(player.shooter.silence_remaining == 0.0)
	root.size = Vector2i(390, 844)
	await process_frame
	await process_frame
	assert(root.content_scale_size == Vector2i(900, 1440))
	var touch: PlaygroundTouchControls = lab.get_node("TouchControls")
	touch._enabled = true
	await process_frame
	var bounds: Rect2 = Rect2(Vector2.ZERO, root.get_visible_rect().size)
	assert(bounds.encloses(touch.get_node("MoveStick").get_global_rect()))
	assert(bounds.encloses(touch.get_node("AimStick").get_global_rect()))
	assert(lab.get_node("CanvasLayer/PlayerHealth").anchor_top == 0.0)
	root.size = Vector2i(844, 390)
	await process_frame
	assert(root.content_scale_size == Vector2i(1440, 900))
	print("PASS: silencer telegraph/escape/hit/expiry/pause/reset; dash allowed; portrait and landscape layout")
	lab.queue_free()
	await process_frame
	quit()
