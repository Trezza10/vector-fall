extends SceneTree

var _player: PlaygroundPlayer
var _shooter: AutoShooter

func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	var packed: PackedScene = load("res://features/movement_playground/movement_playground.tscn")
	var lab: Node2D = packed.instantiate()
	root.add_child(lab)
	await process_frame
	_player = lab.get_node("Player")
	_shooter = _player.shooter
	_shooter.auto_fire_enabled = false
	assert(not InputMap.has_action("weapon_1") and not InputMap.has_action("weapon_next"))
	var pickups: Node2D = lab.get_node("Pickups")
	assert(pickups.get_child_count() == 21)
	var first: UpgradePickup = pickups.get_node("MultishotA")
	var second: UpgradePickup = pickups.get_node("MultishotB")
	assert(first.modification.duration_seconds == 0.0 and first.respawn_seconds == 8.0)
	# Keep exercising optional timed buffs without modifying the run-long authored defaults.
	first.modification = first.modification.working_copy()
	first.modification.duration_seconds = 30.0
	second.modification = second.modification.working_copy()
	second.modification.duration_seconds = 30.0
	_player.position = first.position
	_player.reset_physics_interpolation()
	await _frames(4)
	assert(not first.available, "Body overlap must collect the pickup")
	assert(_shooter.modifier_stack_count(&"multishot") == 1)
	assert(_shooter.active_weapon.bullet_count == 2)
	assert(not first.try_collect(_player), "A collected pickup cannot apply twice")
	_player.reset_to_spawn()
	Engine.time_scale = 10.0
	await create_timer(8.2).timeout
	assert(first.available, "Pickup must recharge")
	var older_time: float = _shooter.modifier_time_left(&"multishot")
	assert(older_time > 20.0 and older_time < 23.0)
	_player.position = second.position
	_player.reset_physics_interpolation()
	await _frames(3)
	_player.reset_to_spawn()
	assert(_shooter.modifier_stack_count(&"multishot") == 2)
	assert(_shooter.active_weapon.bullet_count == 3)
	assert(is_equal_approx(_shooter.active_weapon.spread_degrees, 16.0))
	assert(_shooter.modifier_time_left(&"multishot") < older_time, "Older stack must not refresh")
	var frozen: float = _shooter.modifier_time_left(&"multishot")
	var timer: Timer = second.get_node("RespawnTimer")
	var frozen_recharge: float = timer.time_left
	paused = true
	await create_timer(1.0).timeout
	assert(is_equal_approx(_shooter.modifier_time_left(&"multishot"), frozen))
	assert(is_equal_approx(timer.time_left, frozen_recharge))
	assert(not first.try_collect(_player), "Cannot collect while paused")
	paused = false
	await create_timer(frozen + 0.4).timeout
	assert(_shooter.modifier_stack_count(&"multishot") == 1, "First stack expires independently")
	assert(_shooter.active_weapon.bullet_count == 2)
	await create_timer(9.0).timeout
	assert(_shooter.modifier_stack_count(&"multishot") == 0)
	assert(_shooter.active_weapon.bullet_count == 1 and _shooter.active_weapon.spread_degrees == 0.0)
	var rapid: WeaponModification = load("res://data/modifications/rapid_fire.tres")
	var damage: WeaponModification = load("res://data/modifications/damage.tres")
	var pierce: WeaponModification = load("res://data/modifications/piercing.tres")
	var speed: WeaponModification = load("res://data/modifications/velocity.tres")
	for modifier: WeaponModification in [rapid, damage, pierce, speed]:
		assert(modifier.duration_seconds == 0.0)
	rapid = rapid.working_copy()
	damage = damage.working_copy()
	pierce = pierce.working_copy()
	speed = speed.working_copy()
	for modifier: WeaponModification in [rapid, damage, pierce, speed]:
		modifier.duration_seconds = 30.0
	var order: Array[WeaponModification] = [rapid, damage, pierce, speed, rapid, damage, pierce, speed]
	for modifier: WeaponModification in order: assert(_shooter.apply_modifier(modifier))
	assert(is_equal_approx(_shooter.active_weapon.attacks_per_second, 7.0))
	assert(_shooter.active_weapon.projectile.damage == 9)
	assert(_shooter.active_weapon.projectile.pierce_count == 2)
	assert(is_equal_approx(_shooter.active_weapon.projectile.speed, 1200.0))
	assert(_shooter.arsenal[0].projectile.damage == 5 and rapid.attack_speed_bonus == 0.2)
	var shooter_scene: PackedScene = load("res://features/combat/auto_shooter.tscn")
	var comparison: AutoShooter = shooter_scene.instantiate()
	lab.add_child(comparison)
	comparison.auto_fire_enabled = false
	comparison.configure(lab.get_node("Projectiles"), _player)
	order.reverse()
	for modifier: WeaponModification in order: comparison.apply_modifier(modifier)
	assert(comparison.active_weapon.projectile.damage == _shooter.active_weapon.projectile.damage)
	assert(comparison.active_weapon.attacks_per_second == _shooter.active_weapon.attacks_per_second)
	assert(comparison.active_weapon.projectile.pierce_count == _shooter.active_weapon.projectile.pierce_count)
	comparison.queue_free()
	var huge: WeaponModification = first.modification.working_copy()
	huge.bullet_count_bonus = 100
	huge.duration_seconds = 0.4
	_shooter.apply_modifier(huge)
	assert(_shooter.active_weapon.bullet_count == 32)
	await create_timer(0.7).timeout
	assert(_shooter.active_weapon.bullet_count == 1, "Cap expiry must rebuild, not subtract from clamped stats")
	var permanent: WeaponModification = load("res://data/modifications/rapid_fire.tres")
	assert(permanent.duration_seconds == 0.0)
	_shooter.apply_modifier(permanent)
	await create_timer(31.0).timeout
	assert(_shooter.modifier_stack_count(&"rapid_fire") == 1)
	assert(is_equal_approx(_shooter.active_weapon.attacks_per_second, 6.0))
	assert(_shooter.active_weapon.projectile.damage == 5 and _shooter.active_weapon.projectile.pierce_count == 0)
	Engine.time_scale = 1.0
	print("PASS: real collection, duplicate prevention, recharge, 30-second independent stacks, pause, combined stats, order independence, preset isolation, cap expiry and configurable run-only duration")
	quit()

func _frames(count: int) -> void:
	for index: int in range(count): await physics_frame
	await process_frame
