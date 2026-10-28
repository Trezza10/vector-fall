extends SceneTree

var _actual_damage: int = 0
var _deaths: int = 0

func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	var lab: Node2D = load("res://features/movement_playground/movement_playground.tscn").instantiate()
	root.add_child(lab)
	var player: PlaygroundPlayer = lab.get_node("Player")
	player.shooter.auto_fire_enabled = false
	for child: Node in lab.get_node("EnemyField").get_children():
		if child is PlaygroundEnemy: child.set_physics_process(false)
	await process_frame
	for shot: Node in lab.get_node("Projectiles").get_children(): shot.queue_free()
	var bar: DamageHealthBar = lab.get_node("CanvasLayer/PlayerHealth")
	player.hit_received.connect(func(amount: int) -> void: _actual_damage += amount)
	player.died.connect(func() -> void: _deaths += 1)
	assert(player.current_hp == 100 and player.is_alive)
	assert(bar.health_fraction == 1.0 and bar.damage_fraction == 1.0)
	assert(bar.get_node("Value").text == "PLAYER  100 / 100")
	assert(bar.get_node("Health").size.x == 280.0, "Shared bar fills authored HUD width")
	assert(not player.receive_enemy_hit(0) and not player.receive_enemy_hit(-2))
	assert(player.receive_enemy_hit(25))
	assert(player.current_hp == 75 and player.hits_taken == 1 and _actual_damage == 25)
	assert(is_equal_approx(bar.health_fraction, 0.75) and bar.damage_fraction == 1.0)
	var sound: ActionSound = player.get_node("IncomingHitSound")
	assert(sound.playing and sound.bus == &"Combat")
	var cooldown: float = sound._cooldown
	assert(not player.receive_enemy_hit(25) and player.current_hp == 75)
	assert(sound._cooldown == cooldown, "Grace hits must not retrigger audio")
	bar._chip_tween.pause()
	bar._chip_tween.custom_step(0.28)
	assert(bar.damage_fraction > 0.75 and bar.damage_fraction < 1.0)
	bar._chip_tween.play()
	var chip: float = bar.damage_fraction
	var grace: float = player._hurt_remaining
	paused = true
	assert(not player.receive_enemy_hit(1))
	await create_timer(0.15).timeout
	assert(bar.damage_fraction == chip and player._hurt_remaining == grace and sound.stream_paused)
	paused = false
	while player._hurt_remaining > 0.0: await physics_frame
	# Exercise real enemy contact, then a hostile projectile sweep.
	var tank: PlaygroundEnemy = lab.get_node("EnemyField/Bulwark")
	tank.global_position = player.global_position + Vector2(57, 0)
	tank._home_position = tank.global_position
	await physics_frame
	tank._physics_process(1.0 / 60.0)
	assert(player.current_hp == 74)
	while player._hurt_remaining > 0.0: await physics_frame
	var shot: EnemyProjectile = load("res://features/enemies/enemy_projectile.tscn").instantiate()
	shot.position = player.global_position - Vector2(90, 0)
	shot.heading = Vector2.RIGHT
	shot.speed = 900.0
	shot.damage = 7
	lab.get_node("EnemyProjectiles").add_child(shot)
	for frame: int in range(12): await physics_frame
	assert(player.current_hp == 67 and player.hits_taken == 3)
	while player._hurt_remaining > 0.0: await physics_frame
	var reserve: WeaponModification = load("res://data/modifications/dash_charge.tres")
	player.shooter.apply_modifier(reserve)
	assert(player.try_dash())
	assert(player.receive_enemy_hit(100000))
	assert(player.current_hp == 0 and not player.is_alive and _actual_damage == 100 and _deaths == 1)
	assert(not player.is_dashing and player.velocity == Vector2.ZERO)
	assert(player.shooter.firing_blocked and player.shooter.fire_volley() == 0)
	assert(not player.try_dash() and not player.receive_enemy_hit(1))
	assert(player.get_node("DepletedSound").playing)
	assert(not lab.get_node("Pickups/CritChanceA").try_collect(player))
	assert(lab.get_node("CanvasLayer/PlayerHealthHint").text.begins_with("DEPLETED"))
	var frozen: Vector2 = player.global_position
	Input.action_press("move_right")
	for frame: int in range(5): await physics_frame
	Input.action_release("move_right")
	assert(player.global_position == frozen)
	var reset: InputEventKey = InputEventKey.new()
	reset.physical_keycode = KEY_R
	reset.pressed = true
	lab._unhandled_key_input(reset)
	await process_frame
	assert(player.current_hp == 100 and player.is_alive and not player.shooter.firing_blocked)
	assert(not player.shooter.auto_fire_enabled and player.max_dash_charges == 2)
	assert(bar.health_fraction == 1.0 and bar.damage_fraction == 1.0 and player.hits_taken == 0)
	assert(lab.get_node("EnemyProjectiles").get_child_count() == 0)
	print("PASS: shared HUD bar sizing/current-max/chip effect, actual contact/projectile damage, hit sound, grace, pause, lethal clamp, depletion/dash/fire/movement/collection guards, reset and preserved upgrades/fire preference")
	lab.queue_free()
	await create_timer(0.5).timeout
	quit()
