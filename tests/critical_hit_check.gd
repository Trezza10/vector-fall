extends SceneTree

func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	var lab: Node2D = load("res://features/movement_playground/movement_playground.tscn").instantiate()
	root.add_child(lab)
	await process_frame
	var player: PlaygroundPlayer = lab.get_node("Player")
	var shooter: AutoShooter = player.shooter
	shooter.auto_fire_enabled = false
	for shot: Node in lab.get_node("Projectiles").get_children(): shot.queue_free()
	await process_frame
	var preset: ProjectileDefinition = shooter.arsenal[0].projectile
	assert(shooter.active_weapon.projectile.crit_chance == 0.0)
	shooter.aim_direction = Vector2.UP
	shooter.fire_volley()
	var snapshot: CombatProjectile = lab.get_node("Projectiles").get_child(0)
	var first: UpgradePickup = lab.get_node("Pickups/CritChanceA")
	var second: UpgradePickup = lab.get_node("Pickups/CritChanceB")
	assert(first.try_collect(player) and second.try_collect(player))
	assert(is_equal_approx(shooter.active_weapon.projectile.crit_chance, 0.2))
	assert(shooter.modifier_stack_count(&"crit_chance") == 2)
	assert(snapshot._definition.crit_chance == 0.0 and preset.crit_chance == 0.0)
	var target: TargetDummy = lab.get_node("TargetDummies/DummyCenter")
	assert(snapshot.apply_hit(target) == 5)
	assert(not target.get_node("DamageNumbers/Critical").is_active)
	for index: int in range(12): shooter.apply_modifier(first.modification)
	assert(shooter.active_weapon.projectile.crit_chance == 1.0)
	assert(first.modification.crit_chance_bonus == 0.1)
	for shot: Node in lab.get_node("Projectiles").get_children(): shot.queue_free()
	await process_frame
	target.reset_health()
	shooter.aim_direction = Vector2.UP
	shooter.fire_volley()
	# Exercise the real projectile sweep rather than only invoking the hit method.
	for frame: int in range(30): await physics_frame
	assert(target.current_hp == 999990)
	var crit: FloatingDamageNumber = target.get_node("DamageNumbers/Critical")
	var normal: FloatingDamageNumber = target.get_node("DamageNumbers/Bullet")
	assert(crit.displayed_damage == 10 and not normal.is_active)
	assert(crit.get_node("Value").text == "CRIT 10")
	assert(crit.font_size > normal.font_size and crit.punch_scale > normal.punch_scale)
	assert(crit.number_color.r > 0.9 and crit.number_color.g > 0.6 and crit.number_color.b < 0.3)
	crit.set_process(false)
	crit._process(0.5 - (crit.lifetime - crit.remaining_lifetime))
	target.apply_damage(12, DamageSource.Kind.CRITICAL)
	var alternate: FloatingDamageNumber = target.get_node("DamageNumbers/CriticalAlternate")
	assert(crit.displayed_damage == 10 and alternate.displayed_damage == 12)
	paused = true
	var hp: int = target.current_hp
	assert(not shooter.apply_modifier(first.modification))
	assert(target.apply_damage(10, DamageSource.Kind.CRITICAL) == 0 and target.current_hp == hp)
	paused = false
	target._on_status_damage(2, 1)
	assert(target.get_node("DamageNumbers/Burn").displayed_damage == 2)
	assert(target.get_node("DamageNumbers/Poison").displayed_damage == 1)
	target.reset_health()
	assert(not crit.is_active and not alternate.is_active)
	print("PASS: crit pickup stacking/cap, immutable presets/in-flight chances, normal and guaranteed critical hits, real projectile collision, gold CRIT text/size/punch, overlap, pause, DoT and reset")
	quit()
