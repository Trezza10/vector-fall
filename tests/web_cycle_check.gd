extends SceneTree
func _initialize() -> void:
	call_deferred("_check")
func _check() -> void:
	var preset: ConfigFile = ConfigFile.new()
	assert(preset.load("res://export_presets.cfg") == OK)
	assert(preset.get_value("preset.0.options", "variant/thread_support") == false)
	assert(preset.get_value("preset.0.options", "progressive_web_app/enabled") == false)
	assert(ProjectSettings.get_setting("rendering/renderer/rendering_method.web") == "gl_compatibility")
	var lab: Node2D = load("res://features/movement_playground/movement_playground.tscn").instantiate()
	root.add_child(lab)
	var player: PlaygroundPlayer = lab.get_node("Player")
	player.shooter.auto_fire_enabled = false
	var touch: PlaygroundTouchControls = lab.get_node("TouchControls")
	touch._enabled = true
	touch.show()
	player.touch_input_enabled = true
	await process_frame
	var move: TouchStick = touch.get_node("MoveStick")
	var aim: TouchStick = touch.get_node("AimStick")
	var left: InputEventScreenTouch = InputEventScreenTouch.new()
	left.index = 2
	left.pressed = true
	left.position = move.get_global_rect().get_center() + Vector2(60, 0)
	move._input(left)
	assert(player._movement_input().x > 0.5)
	var right: InputEventScreenTouch = InputEventScreenTouch.new()
	right.index = 3
	right.pressed = true
	right.position = aim.get_global_rect().get_center() + Vector2(0, -60)
	aim._input(right)
	assert(player.shooting_direction().y < -0.9)
	left.pressed = false
	move._input(left)
	assert(player._movement_input() == Vector2.ZERO and aim.value.y < 0.0)
	var last_aim: Vector2 = player.shooting_direction()
	right.pressed = false
	aim._input(right)
	assert(player.shooting_direction() == last_aim)
	touch._on_dash()
	assert(player.is_dashing)
	var menu: PlaygroundPauseMenu = lab.get_node("PauseMenu")
	touch._on_pause()
	await process_frame
	assert(paused and not touch.visible and player.touch_move == Vector2.ZERO)
	menu.set_paused(false)
	await process_frame
	player.receive_enemy_hit(20)
	touch._on_reset()
	assert(player.current_hp == player.max_hp and not player.is_dashing)
	print("PASS: single-threaded web config, mobile renderer, independent multi-touch move/aim, release and retained aim, dash, pause and reset")
	lab.queue_free()
	await create_timer(0.5).timeout
	quit()
