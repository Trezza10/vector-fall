extends SceneTree

func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	var scene: PackedScene = load("res://features/movement_playground/movement_playground.tscn")
	var lab: Node2D = scene.instantiate()
	root.add_child(lab)
	await process_frame
	var player: PlaygroundPlayer = lab.get_node("Player")
	player.shooter.auto_fire_enabled = false
	for shot: Node in lab.get_node("Projectiles").get_children(): shot.queue_free()
	await process_frame
	var dummy: TargetDummy = lab.get_node("TargetDummies/DummyCenter")
	var numbers: TargetDamageNumbers = dummy.get_node("DamageNumbers")
	var bullet: FloatingDamageNumber = numbers.get_node("Bullet")
	var burn_number: FloatingDamageNumber = numbers.get_node("Burn")
	var poison_number: FloatingDamageNumber = numbers.get_node("Poison")
	var other: FloatingDamageNumber = lab.get_node("TargetDummies/DummyLeft/DamageNumbers/Bullet")
	assert(numbers.get_child_count() == 16)
	dummy.apply_damage(5)
	assert(bullet.displayed_damage == 5 and bullet.scale.x > 1.0 and bullet.visible)
	var origin: Vector2 = bullet.global_position
	await create_timer(0.3).timeout
	assert(bullet.global_position.y < origin.y and bullet.modulate.a < 1.0)
	var existing: Vector2 = bullet.global_position
	var remaining: float = bullet.remaining_lifetime
	var alpha: float = bullet.modulate.a
	dummy.apply_damage(7)
	assert(bullet.displayed_damage == 12 and bullet.global_position == existing)
	assert(bullet.remaining_lifetime == remaining and bullet.modulate.a == alpha)
	assert(bullet.scale.x >= bullet.punch_scale - bullet.punch_variation - 0.001)
	assert(bullet.scale.x <= bullet.punch_scale + bullet.punch_variation + 0.001)
	assert(not other.is_active and numbers.get_child_count() == 16)
	paused = true
	await create_timer(0.15).timeout
	assert(bullet.remaining_lifetime == remaining and bullet.global_position == existing)
	paused = false
	await create_timer(0.8).timeout
	assert(not bullet.is_active, "Chained hit cannot extend the one-second window")
	dummy.reset_health()
	dummy.apply_damage(1)
	bullet.set_process(false)
	bullet._process(0.49)
	dummy.apply_damage(2)
	assert(bullet.displayed_damage == 3)
	bullet._process(0.01)
	var alternate: FloatingDamageNumber = numbers.get_node("BulletAlternate")
	dummy.apply_damage(4)
	alternate.set_process(false)
	assert(bullet.is_active and alternate.is_active)
	assert(bullet.displayed_damage == 3 and alternate.displayed_damage == 4)
	dummy.apply_damage(2)
	assert(bullet.displayed_damage == 3 and alternate.displayed_damage == 6)
	assert(alternate.remaining_lifetime == 1.0)
	bullet._process(0.5)
	assert(not bullet.is_active and alternate.is_active)
	alternate._process(0.5)
	dummy.apply_damage(8)
	assert(bullet.displayed_damage == 8 and alternate.displayed_damage == 6)
	dummy.reset_health()
	assert(not bullet.is_active and not alternate.is_active)
	dummy.apply_damage(1)
	bullet.set_process(false)
	bullet._process(0.6)
	dummy.apply_damage(4, DamageSource.Kind.BURN)
	dummy.apply_damage(2, DamageSource.Kind.POISON)
	burn_number.set_process(false)
	poison_number.set_process(false)
	assert(burn_number.displayed_damage == 4 and poison_number.displayed_damage == 2)
	assert(bullet.global_position != burn_number.global_position and burn_number.global_position != poison_number.global_position)
	var label: Label = bullet.get_node("Value")
	assert(label.get_theme_color("font_color") == Color.WHITE)
	assert(label.get_theme_font("font") is SystemFont)
	assert(burn_number.number_color.r > burn_number.number_color.g)
	assert(poison_number.number_color.g > poison_number.number_color.r)
	bullet._process(0.4)
	burn_number._process(0.4)
	poison_number._process(0.4)
	assert(not bullet.is_active and burn_number.is_active and poison_number.is_active)
	var burn: StatusEffectDefinition = load("res://data/effects/burn.tres")
	var poison: StatusEffectDefinition = load("res://data/effects/poison.tres")
	dummy.apply_status(burn, Vector2.UP)
	dummy.apply_status(poison, Vector2.UP)
	dummy.statuses.set_physics_process(false)
	dummy.statuses._physics_process(0.5)
	assert(not bullet.is_active)
	assert(burn_number.displayed_damage == 6 and poison_number.displayed_damage == 3)
	dummy.reset_health()
	var mark: StatusEffectDefinition = load("res://data/effects/mark.tres")
	dummy.apply_status(mark, Vector2.UP)
	dummy._on_status_damage(2, 1)
	assert(dummy.current_hp == 999996, "Preserve combined-tick vulnerability rounding")
	assert(burn_number.displayed_damage + poison_number.displayed_damage == 4)
	poison_number.number_color = Color.CYAN
	dummy.apply_damage(2, DamageSource.Kind.POISON)
	var poison_label: Label = poison_number.get_node("Value")
	assert(poison_label.get_theme_color("font_color") == Color.CYAN)
	dummy.reset_health()
	assert(not bullet.is_active and not burn_number.is_active and not poison_number.is_active)
	var live: TargetDummy = lab.get_node("LiveTargets/LiveCenter")
	live._on_status_damage(20, 20)
	var lethal_burn: FloatingDamageNumber = live.get_node("DamageNumbers/Burn")
	var lethal_poison: FloatingDamageNumber = live.get_node("DamageNumbers/Poison")
	assert(not live.is_alive and lethal_burn.displayed_damage + lethal_poison.displayed_damage == 20)
	await create_timer(1.1).timeout
	assert(not lethal_burn.visible and not lethal_poison.visible)
	Engine.time_scale = 10.0
	await create_timer(4.2).timeout
	Engine.time_scale = 1.0
	assert(live.is_alive and not lethal_burn.is_active and not lethal_poison.is_active)
	print("PASS: hard one-second windows, overlapping rollover with frozen old totals, punch without lifetime/alpha reset, source totals/colors/positions, monospace font, DoT attribution, unchanged damage rounding, pause and respawn")
	quit()
