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
	var spawn: Vector2 = _player.global_position
	Input.action_press("move_right")
	await _frames(1)
	assert(_player.velocity.x > 0.0 and _player.velocity.x < _player.max_speed)
	await _frames(20)
	assert(is_equal_approx(_player.velocity.length(), _player.max_speed))
	Input.action_press("move_down")
	await _frames(20)
	assert(is_equal_approx(_player.velocity.length(), _player.max_speed), "Diagonal speed cap")
	var release_position: Vector2 = _player.position
	Input.action_release("move_down")
	Input.action_release("move_right")
	await _frames(12)
	assert(_player.velocity.is_zero_approx(), "Release must brake to a complete stop")
	assert(_player.position.distance_to(release_position) < 30.0, "Braking must stay responsive")
	var stopped_position: Vector2 = _player.position
	await _frames(12)
	assert(_player.position.is_equal_approx(stopped_position), "No drift at rest")
	_player.reset_to_spawn()
	Input.action_press("ui_left")
	await _frames(20)
	assert(_player.velocity.x < 0.0, "Arrow action must move left")
	Input.action_release("ui_left")
	Input.action_press("move_right")
	await _frames(8)
	assert(_player.velocity.x > 0.0, "Reversing must respond quickly")
	Input.action_release("move_right")
	_player.reset_to_spawn()
	_player.position = Vector2(2360, 800)
	_player.reset_physics_interpolation()
	Input.action_press("move_right")
	Input.action_press("move_down")
	await _frames(30)
	assert(_player.position.x <= 2366.1, "Wall collision must prevent escape")
	assert(_player.position.y > 850.0, "Player must slide along the wall")
	Input.action_release("move_right")
	Input.action_release("move_down")
	_player.reset_to_spawn()
	assert(_player.global_position == spawn and _player.velocity == Vector2.ZERO)
	# Same input duration under different physics rates should travel nearly the same distance.
	var distances: Array[float] = []
	for rate: int in [30, 60, 120]:
		Engine.physics_ticks_per_second = rate
		_player.reset_to_spawn()
		Input.action_press("move_right")
		await _frames(rate)
		distances.append(_player.position.x - spawn.x)
		Input.action_release("move_right")
	assert(absf(distances[0] - distances[2]) < 6.0, "Movement must be stable across physics rates")
	Engine.physics_ticks_per_second = 60
	_player.reset_to_spawn()
	print("PASS: acceleration, speed cap, diagonal speed, braking, no drift, arrows, reversal, walls, slide, reset, physics-rate stability")
	quit()

func _frames(count: int) -> void:
	for index: int in range(count):
		await physics_frame
		await process_frame
