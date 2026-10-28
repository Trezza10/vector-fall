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
	finger.position = move.get_global_rect().get_center() + Vector2(70, 0)
	move._input(finger)
	assert(player._movement_input().x > 0.5)
	assert(player.shooting_direction().x > 0.9)
	assert(not player.is_dashing, "First touch must only steer")
	var extra: InputEventScreenTouch = finger.duplicate()
	extra.index = 3
	extra.position = move.get_global_rect().get_center() + Vector2(0, -70)
	move._input(extra)
	assert(player.shooting_direction().x > 0.9, "Other fingers cannot steal the pad")
	finger.pressed = false
	move._input(finger)
	assert(player._movement_input() == Vector2.ZERO)
	assert(player.shooting_direction().x > 0.9, "Release retains aim")
	# Quick retouch then drag chooses the dash direction before spending a charge.
	finger.pressed = true
	finger.position = move.get_global_rect().get_center()
	move._input(finger)
	assert(not player.is_dashing, "Wait for directional intent")
	var drag: InputEventScreenDrag = InputEventScreenDrag.new()
	drag.index = 2
	drag.position = move.get_global_rect().get_center() + Vector2(0, -75)
	move._input(drag)
	assert(player.is_dashing and player._dash_direction.y < -0.9)
	var charges: int = player.dash_charges
	move._input(drag)
	assert(player.dash_charges == charges, "One dash per retouch")
	var menu: PlaygroundPauseMenu = lab.get_node("PauseMenu")
	touch._on_pause()
	await process_frame
	assert(paused and not touch.visible and player.touch_move == Vector2.ZERO)
	menu.set_paused(false)
	await process_frame
	player.receive_enemy_hit(20)
	touch._on_reset()
	assert(player.current_hp == player.max_hp and not player.is_dashing)
	finger.pressed = true
	finger.position = move.get_global_rect().get_center() + Vector2(70, 0)
	move._input(finger)
	assert(not player.is_dashing, "Reset must clear dash gesture history")
	finger.pressed = false
	move._input(finger)
	await create_timer(0.35).timeout
	finger.pressed = true
	move._input(finger)
	assert(not player.is_dashing, "Slow retouch only steers")
	finger.pressed = false
	finger.canceled = true
	move._input(finger)
	finger.pressed = true
	finger.canceled = false
	move._input(finger)
	assert(not player.is_dashing, "Canceled touches cannot arm dash")
	move.reset_stick()
	print("PASS: single-threaded web config, mobile renderer, one-thumb move/aim, extra-finger rejection, retained aim, retouch-drag dash direction/charges, pause and reset")
	lab.queue_free()
	await create_timer(0.5).timeout
	quit()
