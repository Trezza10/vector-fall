extends SceneTree

func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	var packed: PackedScene = load("res://features/movement_playground/movement_playground.tscn")
	var lab: Node2D = packed.instantiate()
	root.add_child(lab)
	await process_frame
	var player: PlaygroundPlayer = lab.get_node("Player")
	player.shooter.auto_fire_enabled = false
	var menu: PlaygroundPauseMenu = lab.get_node("PauseMenu")
	player.control_mode = PlaygroundPlayer.ControlMode.DIRECTIONAL
	var start: InputEventJoypadButton = InputEventJoypadButton.new()
	start.button_index = JOY_BUTTON_START
	start.pressed = true
	Input.parse_input_event(start)
	await process_frame
	await process_frame
	assert(paused, "Controller Start must pause")
	var start_release: InputEventJoypadButton = start.duplicate()
	start_release.pressed = false
	Input.parse_input_event(start_release)
	var frozen: Vector2 = player.position
	Input.action_press("move_right")
	await create_timer(0.15).timeout
	assert(player.position == frozen, "Player must freeze while menu remains active")
	Input.action_release("move_right")
	var base: String = "Overlay/Center/Panel/Margin/"
	var resume: Button = menu.get_node(base + "Main/Resume")
	assert(resume.has_focus(), "Controller must have a focused menu item")
	var down: InputEventJoypadButton = InputEventJoypadButton.new()
	down.button_index = JOY_BUTTON_DPAD_DOWN
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	await process_frame
	var settings: Button = menu.get_node(base + "Main/Settings")
	assert(settings.has_focus(), "D-pad must navigate the menu")
	var down_release: InputEventJoypadButton = down.duplicate()
	down_release.pressed = false
	Input.parse_input_event(down_release)
	await process_frame
	await process_frame
	var accept: InputEventJoypadButton = InputEventJoypadButton.new()
	accept.button_index = JOY_BUTTON_A
	accept.pressed = true
	Input.parse_input_event(accept)
	await process_frame
	await process_frame
	var accept_release: InputEventJoypadButton = accept.duplicate()
	accept_release.pressed = false
	Input.parse_input_event(accept_release)
	await process_frame
	await process_frame
	assert(menu.get_node(base + "Settings").visible, "Controller A must open Settings")
	var tabs: TabContainer = menu.get_node(base + "Settings/Tabs")
	assert(not tabs.is_tab_disabled(1) and tabs.is_tab_disabled(2), "WIP tabs disabled")
	var mode: OptionButton = menu.get_node(base + "Settings/Tabs/Controls/Content/Mode")
	mode.select(1)
	var apply: Button = menu.get_node(base + "Settings/Buttons/Apply")
	apply.pressed.emit()
	assert(player.control_mode == PlaygroundPlayer.ControlMode.CURSOR_STEERING)
	var persisted: ControlPreferences = ControlPreferences.new()
	persisted.load_preferences()
	assert(persisted.control_mode == PlaygroundPlayer.ControlMode.CURSOR_STEERING)
	var back: InputEventJoypadButton = InputEventJoypadButton.new()
	back.button_index = JOY_BUTTON_B
	back.pressed = true
	Input.parse_input_event(back)
	await process_frame
	await process_frame
	assert(menu.get_node(base + "Main").visible, "Controller B must return to main menu")
	var back_release: InputEventJoypadButton = back.duplicate()
	back_release.pressed = false
	Input.parse_input_event(back_release)
	await process_frame
	var resume_accept: InputEventJoypadButton = accept.duplicate()
	Input.parse_input_event(resume_accept)
	await process_frame
	await process_frame
	var resume_release: InputEventJoypadButton = accept_release.duplicate()
	Input.parse_input_event(resume_release)
	await process_frame
	await process_frame
	assert(not paused)
	# Controller movement remains available in cursor mode, with analog magnitude retained.
	Input.action_press("pad_right", 0.6)
	assert(player._movement_input().x > 0.0 and player._movement_input().x < 1.0)
	Input.action_press("aim_up")
	assert(player._facing_input(Vector2.RIGHT).y < 0.0)
	Input.action_release("pad_right")
	Input.action_release("aim_up")
	Input.action_press("move_right")
	assert(player._movement_input() == Vector2.ZERO, "Cursor mode ignores A/S/D")
	Input.action_release("move_right")
	print("PASS: controller pause/navigation, frozen gameplay, WIP tabs, apply, saved settings, analog movement and aim")
	quit()
