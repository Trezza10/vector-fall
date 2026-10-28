extends SceneTree

var _damage_events: int = 0

func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	var packed: PackedScene = load("res://features/movement_playground/movement_playground.tscn")
	var lab: Node2D = packed.instantiate()
	root.add_child(lab)
	await process_frame
	var owner_player: PlaygroundPlayer = lab.get_node("Player")
	owner_player.shooter.auto_fire_enabled = false
	var targets: Node2D = lab.get_node("TargetDummies")
	assert(targets.get_child_count() == 3)
	var first: TargetDummy = targets.get_node("DummyLeft")
	var second: TargetDummy = targets.get_node("DummyCenter")
	first.damage_received.connect(_on_damage_received)
	assert(first.current_hp == 1000000 and second.current_hp == 1000000)
	assert(first.apply_damage(25) == 25)
	assert(first.current_hp == 999975 and second.current_hp == 1000000)
	assert(_damage_events == 1)
	assert(first.apply_damage(0) == 0 and first.apply_damage(-25) == 0)
	assert(first.current_hp == 999975 and _damage_events == 1)
	paused = true
	assert(first.apply_damage(100) == 0)
	paused = false
	assert(first.apply_damage(2000000) == 999975)
	assert(first.current_hp == 0 and not first.is_queued_for_deletion())
	assert(first.apply_damage(5) == 0)
	first.reset_health()
	assert(first.current_hp == 1000000)
	var target_position: Vector2 = first.position
	var player: PlaygroundPlayer = lab.get_node("Player")
	player.control_mode = PlaygroundPlayer.ControlMode.DIRECTIONAL
	player.position = target_position + Vector2(0, 120)
	player.reset_physics_interpolation()
	Input.action_press("move_up")
	for index: int in range(50):
		await physics_frame
		await process_frame
	Input.action_release("move_up")
	assert(first.position == target_position, "Dummy must remain stationary")
	assert(player.position.y > target_position.y + 45.0, "Dummy must block the player")
	print("PASS: authored targets, million HP, isolated damage, signal, invalid damage, pause, non-removal, reset, stationary collision")
	quit()

func _on_damage_received(_amount: int, _remaining_hp: int) -> void:
	_damage_events += 1
