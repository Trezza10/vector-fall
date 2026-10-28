extends SceneTree

func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	var scene: PackedScene = load("res://features/movement_playground/movement_playground.tscn")
	var lab: Node2D = scene.instantiate()
	root.add_child(lab)
	await process_frame
	var player: PlaygroundPlayer = lab.get_node("Player")
	var shooter: AutoShooter = player.shooter
	shooter.auto_fire_enabled = false
	for shot: Node in lab.get_node("Projectiles").get_children(): shot.queue_free()
	await process_frame
	var dummy: TargetDummy = lab.get_node("TargetDummies/DummyCenter")
	var burn_mod: WeaponModification = load("res://data/modifications/burn.tres")
	var burn: StatusEffectDefinition = burn_mod.on_hit_effects[0]
	var poison: StatusEffectDefinition = load("res://data/effects/poison.tres")
	var ice: StatusEffectDefinition = load("res://data/effects/ice.tres")
	var stun: StatusEffectDefinition = load("res://data/effects/stun.tres")
	var knock: StatusEffectDefinition = load("res://data/effects/knockback.tres")
	var mark: StatusEffectDefinition = load("res://data/effects/mark.tres")
	assert(shooter.apply_modifier(burn_mod))
	assert(shooter.active_weapon.projectile.on_hit_effects[0] != burn)
	shooter.aim_direction = Vector2.UP
	shooter.fire_volley()
	shooter.active_weapon.projectile.on_hit_effects[0].potency = 99.0
	await _frames(26)
	assert(dummy.statuses.has_effect(StatusEffectDefinition.Kind.BURN))
	assert(dummy.statuses.effect_strength(StatusEffectDefinition.Kind.BURN) == 2.0)
	assert(burn.potency == 2.0, "Effect snapshots must isolate both presets and live bullets")
	var health: int = dummy.current_hp
	await create_timer(0.6).timeout
	assert(dummy.current_hp < health, "Burn ticks after the bullet disappears")
	dummy.reset_health()
	dummy.apply_status(burn, Vector2.UP)
	dummy.apply_status(poison, Vector2.UP)
	dummy.statuses.set_physics_process(false)
	dummy.statuses._physics_process(0.4)
	dummy.apply_status(burn, Vector2.UP)
	dummy.statuses.set_physics_process(false)
	dummy.statuses._physics_process(0.1)
	assert(dummy.current_hp == 999997, "Refreshing burn must not reset its tick clock")
	dummy.reset_health()
	dummy.apply_status(ice, Vector2.UP)
	assert(is_equal_approx(dummy.statuses.movement_multiplier, 0.85))
	dummy.apply_status(stun, Vector2.UP)
	assert(dummy.statuses.is_stunned and dummy.statuses.movement_multiplier == 0.0)
	dummy.statuses.set_physics_process(false)
	dummy.statuses._physics_process(0.4)
	assert(not dummy.statuses.is_stunned and is_equal_approx(dummy.statuses.movement_multiplier, 0.85))
	dummy.statuses._physics_process(3.0)
	assert(dummy.statuses.movement_multiplier == 1.0)
	dummy.reset_health()
	dummy.apply_status(mark, Vector2.UP)
	assert(dummy.apply_damage(20) == 23, "Mark amplifies later damage")
	dummy.reset_health()
	var start: Vector2 = dummy.position
	dummy.apply_status(knock, Vector2.RIGHT)
	await _frames(35)
	assert(dummy.position.x > start.x + 15.0 and dummy.position.x < start.x + 20.0)
	dummy.position = Vector2(2340, 800)
	dummy.reset_physics_interpolation()
	var strong_push: StatusEffectDefinition = knock.duplicate(false) as StatusEffectDefinition
	strong_push.potency = 100.0
	dummy.apply_status(strong_push, Vector2.RIGHT)
	await _frames(35)
	assert(dummy.position.x <= 2355.0, "Knockback must respect arena collision")
	dummy.reset_health()
	dummy.apply_status(poison, Vector2.UP)
	var remaining: float = dummy.statuses.effect_time_left(StatusEffectDefinition.Kind.POISON)
	health = dummy.current_hp
	paused = true
	await create_timer(0.2).timeout
	assert(dummy.current_hp == health)
	assert(dummy.statuses.effect_time_left(StatusEffectDefinition.Kind.POISON) == remaining)
	paused = false
	dummy.reset_health()
	shooter.configure(lab.get_node("Projectiles"), player)
	for name: String in ["burn", "poison", "ice", "stun", "knockback", "mark"]:
		var modifier: WeaponModification = load("res://data/modifications/" + name + ".tres")
		for count: int in range(10): shooter.apply_modifier(modifier)
	assert(shooter.active_weapon.projectile.on_hit_effects.size() == 6)
	for effect: StatusEffectDefinition in shooter.active_weapon.projectile.on_hit_effects:
		match effect.kind:
			StatusEffectDefinition.Kind.BURN: assert(effect.potency == 20.0)
			StatusEffectDefinition.Kind.ICE: assert(is_equal_approx(effect.potency, 0.8))
			StatusEffectDefinition.Kind.STUN: assert(effect.duration_seconds == 2.0)
			StatusEffectDefinition.Kind.KNOCKBACK: assert(effect.potency == 100.0)
			StatusEffectDefinition.Kind.MARK: assert(effect.potency == 1.0)
	assert(shooter.arsenal[0].projectile.on_hit_effects.is_empty())
	var live: TargetDummy = lab.get_node("LiveTargets/LiveCenter")
	var spawn: Vector2 = live.position
	live.position += Vector2(100, 0)
	var lethal: StatusEffectDefinition = burn.duplicate(false) as StatusEffectDefinition
	lethal.potency = 30.0
	lethal.tick_interval = 0.1
	live.apply_status(lethal, Vector2.UP)
	live.statuses.set_physics_process(false)
	live.statuses._physics_process(0.1)
	assert(not live.is_alive and not live.statuses.has_effect(StatusEffectDefinition.Kind.BURN))
	Engine.time_scale = 10.0
	await create_timer(5.3).timeout
	Engine.time_scale = 1.0
	assert(live.is_alive and live.current_hp == 20 and live.position == spawn)
	assert(live.statuses.movement_multiplier == 1.0 and live.statuses.damage_multiplier == 1.0)
	print("PASS: real on-hit snapshot, burn/poison ticks, refresh cadence, chill/stun expiry, mark, physical knockback and walls, pause, stacked caps, lethal DoT cleanup and clean respawn")
	quit()

func _frames(count: int) -> void:
	for index: int in range(count): await physics_frame
	await process_frame
