extends SceneTree

func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	var packed: PackedScene = load("res://features/target_dummy/floating_damage_number.tscn")
	var number: FloatingDamageNumber = packed.instantiate()
	root.add_child(number)
	await process_frame
	# Reproducible samples verify bounds without relying on random luck.
	number._random.seed = 123456
	var positions: Array[Vector2] = []
	var angles: Array[float] = []
	var arcs: Array[Vector2] = []
	var target: Vector2 = Vector2(400, 400)
	for index: int in range(32):
		number.reset_number()
		number.add_damage(5, target)
		number.set_process(false)
		var origin: Vector2 = number.global_position
		var offset: Vector2 = origin - target - number.spawn_offset
		assert(absf(offset.x) <= number.spawn_scatter.x + 0.001)
		assert(absf(offset.y) <= number.spawn_scatter.y + 0.001)
		assert(absf(rad_to_deg(number.rotation)) <= number.tilt_variation_degrees + 0.001)
		positions.append(origin)
		angles.append(number.rotation)
		number._process(0.3)
		arcs.append(number.global_position - origin)
		assert(number.global_position.y < origin.y)
		var before_hit: Vector2 = number.global_position
		var before_angle: float = number.rotation
		var before_lifetime: float = number.remaining_lifetime
		var before_alpha: float = number.modulate.a
		number.add_damage(5, target)
		number.set_process(false)
		assert(number.displayed_damage == 10)
		assert(number.global_position == before_hit and number.rotation == before_angle)
		assert(number.remaining_lifetime == before_lifetime and number.modulate.a == before_alpha)
		number._process(0.69)
		assert(number.global_position.distance_to(origin) <= number.max_drift + 0.001)
		assert(absf(rad_to_deg(number.rotation)) <= number.tilt_variation_degrees + number.spin_variation_degrees + 0.001)
		number._process(0.01)
		assert(not number.is_active, "Randomness must not extend the one-second window")
	assert(positions[0] != positions[1] and angles[0] != angles[1] and arcs[0] != arcs[1])
	print("PASS: varied spawn/angle/trajectory, bounded scatter/tilt/spin/travel, upward launch, stable aggregation and hard expiry across 32 seeded windows")
	quit()
