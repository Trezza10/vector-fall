extends SceneTree

var _player: PlaygroundPlayer

func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	var packed: PackedScene = load("res://features/movement_playground/movement_playground.tscn")
	var lab: Node2D = packed.instantiate()
	root.add_child(lab)
	await process_frame
	_player = lab.get_node("Player")
	_player.shooter.auto_fire_enabled = false
	_player.control_mode = PlaygroundPlayer.ControlMode.DIRECTIONAL
	var origin: Vector2 = _player.position
	Input.action_press("move_right")
	assert(_player.try_dash())
	assert(not _player.try_dash(), "Active dash cannot stack")
	await _frames(5)
	assert(_player.velocity.length() > _player.max_speed)
	var frozen: Vector2 = _player.position
	var cooldown: float = _player.dash_cooldown_remaining
	var pulse: ColorRect = _player.get_node("DashFeedback/Pulse")
	var strength: float = pulse.material.get_shader_parameter("strength")
	paused = true
	await create_timer(0.15).timeout
	assert(_player.position == frozen)
	assert(_player.dash_cooldown_remaining == cooldown)
	assert(is_equal_approx(pulse.material.get_shader_parameter("strength"), strength))
	assert(not _player.try_dash(), "Cannot dash while paused")
	paused = false
	while _player.is_dashing: await _frames(1)
	var distance: float = _player.position.x - origin.x
	assert(distance > 140.0 and distance < 170.0, "Expected short controlled burst")
	assert(_player.velocity.length() <= _player.max_speed + 0.1)
	assert(not _player.try_dash(), "Cooldown must block immediate repeat")
	Input.action_release("move_right")
	await _frames(40)
	assert(_player.try_dash(), "Cooldown must recover")
	_player.reset_to_spawn()
	assert(not _player.is_dashing and _player.dash_cooldown_remaining == 0.0)
	var trail: Line2D = _player.get_node("DashFeedback/Trail")
	assert(trail.get_point_count() == 0, "Reset must remove stale trail")
	_player.position = Vector2(2350, 800)
	_player.reset_physics_interpolation()
	Input.action_press("move_right")
	assert(_player.try_dash())
	await _frames(3)
	assert(_player.position.x <= 2366.1 and not _player.is_dashing, "Walls stop the dash")
	Input.action_release("move_right")
	_player.reset_to_spawn()
	var shoulder: InputEventJoypadButton = InputEventJoypadButton.new()
	shoulder.button_index = JOY_BUTTON_RIGHT_SHOULDER
	shoulder.pressed = true
	Input.parse_input_event(shoulder)
	await process_frame
	await process_frame
	assert(_player.is_dashing, "Controller right shoulder must trigger dash")
	var release: InputEventJoypadButton = shoulder.duplicate()
	release.pressed = false
	Input.parse_input_event(release)
	_player.reset_to_spawn()
	var menu: PlaygroundPauseMenu = lab.get_node("PauseMenu")
	menu.set_paused(true)
	var space: InputEventKey = InputEventKey.new()
	space.keycode = KEY_SPACE
	space.physical_keycode = KEY_SPACE
	space.pressed = true
	Input.parse_input_event(space)
	await process_frame
	await process_frame
	var space_release: InputEventKey = space.duplicate()
	space_release.pressed = false
	Input.parse_input_event(space_release)
	await process_frame
	await process_frame
	assert(not paused and not _player.is_dashing, "Space to Resume must not leak into a dash")
	print("PASS: burst distance, ease-out, cooldown, pause/tween freeze, reset, wall collision, controller dash, menu input isolation")
	quit()

func _frames(count: int) -> void:
	for index: int in range(count):
		await physics_frame
	await process_frame
