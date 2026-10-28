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
	var finger: InputEventScreenTouch = InputEventScreenTouch.new()
	finger.index = 2
	finger.pressed = true
	finger.position = Vector2(500, 300)
	move._input(finger)
	assert(player._movement_input() == Vector2.ZERO, "Touch starts a neutral floating origin")
	assert(move.get_node("Base").visible)
	var drag: InputEventScreenDrag = InputEventScreenDrag.new()
	drag.index = 2
	drag.position = finger.position + Vector2(80, 0)
	move._input(drag)
	assert(player._movement_input().x > 0.5 and player.shooting_direction().x > 0.9)
	var extra: InputEventScreenTouch = finger.duplicate()
	extra.index = 3
	extra.position = Vector2(700, 400)
	move._input(extra)
	assert(player.shooting_direction().x > 0.9, "Other fingers cannot steal steering")
	# Real second-finger button input while steering keeps the direction intact.
	var dash: TouchScreenButton = touch.get_node("Dash")
	extra.position = dash.global_position + Vector2(70, 45)
	assert(not move.can_start_at(extra.position))
	root.push_input(extra, true)
	await process_frame
	assert(player.is_dashing and player._dash_direction.x > 0.9)
	assert(player.touch_move.x > 0.5)
	extra.pressed = false
	root.push_input(extra, true)
	finger.pressed = false
	move._input(finger)
	assert(player._movement_input() == Vector2.ZERO and player.shooting_direction().x > 0.9)
	assert(not move.get_node("Base").visible)
	lab.reset_playground()
	# Reposition near another screen edge; retouch must never dash.
	finger.pressed = true
	finger.position = Vector2(300, 600)
	move._input(finger)
	drag.position = finger.position + Vector2(0, -80)
	move._input(drag)
	assert(player.shooting_direction().y < -0.9 and not player.is_dashing)
	var menu: PlaygroundPauseMenu = lab.get_node("PauseMenu")
	touch._on_pause()
	await process_frame
	assert(paused and not touch.visible and player.touch_move == Vector2.ZERO)
	menu.set_paused(false)
	await process_frame
	player.receive_enemy_hit(20)
	lab.reset_playground()
	assert(player.current_hp == player.max_hp and not player.is_dashing)
	# All authored buttons reserve touch space even when no steering finger is held.
	for name: String in ["Dash", "Pause"]:
		var button: TouchScreenButton = touch.get_node(name)
		var at: Vector2 = button.global_position + Vector2(70, 45)
		assert(not move.can_start_at(at))
		finger.position = at
		move._input(finger)
		assert(move._finger == -1 and player.touch_move == Vector2.ZERO)
	lab._update_combat_hud()
	assert(not touch.has_node("Reset") and not dash.has_node("Label"))
	assert(dash.texture_normal.resource_path.ends_with("dash_icon.svg"))
	assert(not lab.get_node("CanvasLayer/DashMeter").visible)
	assert(not lab.get_node("CanvasLayer/DashHint").visible)
	assert(not lab.get_node("CanvasLayer/PlayerHealthHint").visible)
	assert(lab.get_node("CanvasLayer/PlayerHealth").visible)
	assert(menu.has_node("Overlay/Center/Panel/Margin/Settings/Tabs/Graphics/Content/Fullscreen"))
	print("PASS: single-threaded web config, mobile renderer, fullscreen floating move/aim, extra-finger rejection, real simultaneous dash button, retained aim, reserved button zones, pause and reset")
	lab.queue_free()
	await create_timer(0.5).timeout
	quit()
