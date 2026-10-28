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
	player.set_physics_process(false)
	shooter.set_physics_process(false)
	assert(player.dash_charges == 1 and player.max_dash_charges == 1)
	assert(player.try_dash())
	player._finish_dash(true)
	player._update_dash_recharge(0.2)
	var pending: float = player.dash_cooldown_remaining
	var reserve: UpgradePickup = lab.get_node("Pickups/DashReserve")
	var quick: UpgradePickup = lab.get_node("Pickups/QuickDash")
	# Exercise real scene-authored pickup overlap while an original charge is spent.
	player.global_position = reserve.global_position
	player.reset_physics_interpolation()
	for frame: int in range(4): await physics_frame
	assert(not reserve.available)
	assert(player.max_dash_charges == 2 and player.dash_charges == 1)
	assert(is_equal_approx(player.dash_cooldown_remaining, pending))
	assert(player.try_dash(), "New slot is immediately usable while old charge recharges")
	player._finish_dash(true)
	assert(player.dash_charges == 0 and not player.try_dash())
	assert(is_equal_approx(player.dash_cooldown_remaining, pending), "Spending a reserve cannot restart recharge")
	assert(quick.try_collect(player))
	assert(is_equal_approx(player.effective_dash_cooldown, 0.585))
	assert(is_equal_approx(player.dash_cooldown_remaining, pending * 0.9))
	assert(player.dash_cooldown == 0.65 and reserve.modification.dash_charge_bonus == 1)
	pending = player.dash_cooldown_remaining
	paused = true
	player._update_dash_recharge(5.0)
	assert(player.dash_charges == 0 and player.dash_cooldown_remaining == pending)
	assert(not shooter.apply_modifier(quick.modification) and not player.try_dash())
	paused = false
	player._update_dash_recharge(pending)
	assert(player.dash_charges == 1 and is_equal_approx(player.dash_cooldown_remaining, 0.585))
	player._update_dash_recharge(0.585)
	assert(player.dash_charges == 2 and player.dash_cooldown_remaining == 0.0)
	player._update_dash_recharge(20.0)
	assert(player.dash_charges == 2)
	for index: int in range(12):
		shooter.apply_modifier(reserve.modification)
		shooter.apply_modifier(quick.modification)
	assert(player.max_dash_charges == 8 and player.dash_charges == 8)
	assert(is_equal_approx(player.effective_dash_cooldown, 0.2))
	assert(shooter.arsenal[0].projectile.damage == 5 and shooter.active_weapon.projectile.damage == 5)
	shooter.select_weapon(1)
	assert(player.max_dash_charges == 8 and is_equal_approx(player.effective_dash_cooldown, 0.2))
	player.try_dash()
	player.reset_to_spawn()
	assert(player.dash_charges == 8 and player.dash_cooldown_remaining == 0.0 and not player.is_dashing)
	# Reconfigure clears run stacks. Optional timed mobility stacks expire in the same owner.
	shooter.configure(lab.get_node("Projectiles"), player)
	assert(player.max_dash_charges == 1 and player.dash_charges == 1)
	var timed: WeaponModification = reserve.modification.working_copy()
	timed.duration_seconds = 1.0
	timed.dash_cooldown_reduction = 0.2
	shooter.apply_modifier(timed)
	assert(player.max_dash_charges == 2 and player.dash_charges == 2)
	player.try_dash()
	player._finish_dash(true)
	player.try_dash()
	player._finish_dash(true)
	player._update_dash_recharge(0.2)
	var fraction: float = player.dash_cooldown_remaining / player.effective_dash_cooldown
	shooter._update_modifiers(1.1)
	assert(player.max_dash_charges == 1 and player.dash_charges == 0)
	assert(is_equal_approx(player.dash_cooldown_remaining / player.effective_dash_cooldown, fraction))
	player._update_dash_recharge(2.0)
	assert(player.dash_charges == 1 and player.dash_cooldown_remaining == 0.0)
	print("PASS: real dash pickup collection, immediate new slots, chaining, sequential recharge, preserved recharge progress, cooldown stacking/caps, pause, reset, weapon switching and timed expiry")
	lab.queue_free()
	await create_timer(0.5).timeout
	quit()
