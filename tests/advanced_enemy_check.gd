extends SceneTree
var lab: Node2D
var player: PlaygroundPlayer
func _initialize() -> void:
	call_deferred("_check")
func _frames(count: int) -> void:
	for index: int in range(count): await physics_frame
func _clear_attacks() -> void:
	for child: Node in lab.get_node("EnemyProjectiles").get_children(): child.queue_free()
	await _frames(2)
func _check() -> void:
	lab = load("res://features/movement_playground/movement_playground.tscn").instantiate()
	root.add_child(lab)
	player = lab.get_node("Player")
	player.shooter.auto_fire_enabled = false
	player.set_physics_process(false)
	player.incoming_status.set_physics_process(false)
	for area: String in ["EnemyField", "AdvancedField"]:
		for child: Node in lab.get_node(area).get_children():
			if child is PlaygroundEnemy: child.set_physics_process(false)
	await _frames(2)
	for area: String in ["EnemyField", "AdvancedField", "TargetDummies"]:
		for enemy: Node in lab.get_node(area).get_children():
			if enemy is TargetDummy:
				var bar: DamageHealthBar = enemy.get_node("HealthBar")
				var center: float = bar.get_node("Health").get_global_rect().get_center().x
				assert(absf(center - enemy.global_position.x) < 0.1, "Every scaled world bar must be centered")
	var wing: Node2D = lab.get_node("AdvancedField")
	var stunner: AdvancedEnemy = wing.get_node("Stunner")
	player.global_position = stunner.global_position + Vector2(300, 0)
	await _frames(2)
	assert(stunner.fire_advanced_volley() == 1)
	await _frames(75)
	assert(player.current_hp == 97 and player.incoming_status.is_stunned, "Real stun projectile applies damage and status")
	assert(not player.try_dash())
	player._physics_process(0.01)
	assert(player.shooter.firing_blocked and player.velocity == Vector2.ZERO)
	player.incoming_status._physics_process(1.0)
	player._physics_process(0.01)
	assert(not player.incoming_status.is_stunned and not player.shooter.firing_blocked)
	await _clear_attacks()
	player.reset_to_spawn()
	var repulsor: AdvancedEnemy = wing.get_node("Repulsor")
	player.global_position = repulsor.global_position + Vector2(300, 0)
	await _frames(2)
	repulsor.fire_advanced_volley()
	await _frames(90)
	assert(player.incoming_status.push_velocity.x > 700.0)
	var before_push: float = player.global_position.x
	player._physics_process(0.1)
	assert(player.global_position.x > before_push + 5.0, "Knockback moves the actual body")
	await _clear_attacks()
	player.reset_to_spawn()
	var lobber: AdvancedEnemy = wing.get_node("PoisonLobber")
	player.global_position = lobber.global_position + Vector2(300, 0)
	await _frames(2)
	assert(lobber.fire_advanced_volley() == 5)
	await _frames(20)
	var lob: EnemyProjectile = lab.get_node("EnemyProjectiles").get_child(0) as EnemyProjectile
	assert(lob.get_node("Core").position.y < -20.0 and lob.get_node("LandingMark").visible)
	await _frames(65)
	var pools: int = 0
	var sample_pool: GroundHazard
	for child: Node in lab.get_node("EnemyProjectiles").get_children():
		if child is GroundHazard:
			pools += 1
			sample_pool = child as GroundHazard
	assert(pools == 5 and player.incoming_status.poison_remaining > 0.0)
	var hp: int = player.current_hp
	player._hurt_remaining = 0.0
	player.incoming_status._physics_process(0.5)
	assert(player.current_hp < hp, "Poison deals damage after contact")
	var pool_life: float = sample_pool.lifetime
	var poison_time: float = player.incoming_status.poison_remaining
	player.incoming_status.set_physics_process(true)
	paused = true
	await create_timer(0.1).timeout
	assert(sample_pool.lifetime == pool_life and player.incoming_status.poison_remaining == poison_time)
	paused = false
	player.incoming_status.set_physics_process(false)
	await _clear_attacks()
	player.reset_to_spawn()
	var cinder: AdvancedEnemy = wing.get_node("FireDash")
	player.global_position = cinder.global_position + Vector2(300, 0)
	await _frames(2)
	cinder._attack_remaining = 0.0
	cinder._physics_process(0.01)
	assert(cinder._phase == PlaygroundEnemy.Phase.WINDUP)
	cinder._physics_process(0.9)
	for index: int in range(35):
		cinder._physics_process(1.0 / 60.0)
		await physics_frame
	var fire_count: int = 0
	for child: Node in lab.get_node("EnemyProjectiles").get_children():
		if child is GroundHazard and child.effect == PlayerStatus.Kind.BURN: fire_count += 1
	assert(fire_count >= 2, "Dash leaves continuous authored fire patches")
	var flame: GroundHazard = lab.get_node("EnemyProjectiles").get_child(0) as GroundHazard
	player.global_position = flame.global_position
	player._hurt_remaining = 0.0
	await _frames(35)
	assert(player.incoming_status.burn_remaining > 0.0, "Fire trail actually applies burn")
	var fire_hp: int = player.current_hp
	player._hurt_remaining = 0.0
	player.incoming_status._physics_process(0.5)
	assert(player.current_hp < fire_hp, "Burn continues to damage the player")
	flame.lifetime = 0.01
	await _frames(3)
	assert(not is_instance_valid(flame), "Ground hazards expire")
	await _clear_attacks()
	player.reset_to_spawn()
	var laser: AdvancedEnemy = wing.get_node("Laser")
	player.global_position = laser.global_position + Vector2(400, 0)
	await _frames(2)
	laser._attack_remaining = 0.0
	laser._physics_process(0.01)
	assert(laser._phase == PlaygroundEnemy.Phase.WINDUP and player.current_hp == 100)
	assert(laser.get_node("Laser").width == 2.0)
	player.global_position.y += 100.0
	laser._physics_process(1.2)
	assert(player.current_hp == 100 and laser.get_node("Laser").width == 18.0, "Locked laser can be dodged")
	player.global_position.y -= 100.0
	laser._physics_process(0.01)
	assert(player.current_hp == 94, "Active laser damages only its beam")
	laser.apply_status(load("res://data/effects/stun.tres"), Vector2.RIGHT)
	laser._physics_process(0.01)
	assert(not laser.get_node("Laser").visible)
	laser.statuses.clear_effects()
	laser._physics_process(1.0)
	assert(laser._phase == PlaygroundEnemy.Phase.HUNT, "Interrupted laser recovers")
	laser._phase = PlaygroundEnemy.Phase.WINDUP
	laser._phase_remaining = 0.5
	laser._laser_direction = Vector2.DOWN
	laser._update_laser(0.01)
	assert(laser.get_node("Laser").points[1].y < laser.definition.attack_range, "World wall clips the laser")
	laser.reset_encounter()
	var boss: AdvancedEnemy = wing.get_node("LinkedArtillery")
	var link: TargetDummy = wing.get_node("LifeLink")
	assert(boss.linked_shield_active and link.max_hp == 40)
	assert(boss.apply_damage(9999) == 0 and boss._commit_damage(10, DamageSource.Kind.BURN) == 0)
	boss.apply_status(load("res://data/effects/poison.tres"), Vector2.RIGHT)
	assert(not boss.statuses.has_effect(StatusEffectDefinition.Kind.POISON))
	link.apply_damage(40)
	assert(not boss.linked_shield_active and boss.apply_damage(10) == 10)
	boss.reset_encounter()
	assert(link.is_alive and boss.linked_shield_active)
	link.apply_damage(40)
	boss.apply_damage(9999)
	assert(not boss.is_alive)
	boss._on_respawn_timeout()
	assert(boss.is_alive and link.is_alive and boss.linked_shield_active, "Artillery respawn restores its remote link")
	player.reset_to_spawn()
	player.global_position = boss.global_position + Vector2(350, 0)
	await _frames(2)
	assert(boss.fire_advanced_volley() == 1)
	var big: EnemyProjectile = lab.get_node("EnemyProjectiles").get_child(0) as EnemyProjectile
	assert(big.visual_size == 4.0 and big.collision_radius == 24.0 and big.speed == 110.0)
	big.global_position.y += 35.0 # Graze outside a center ray, inside the large projectile radius.
	big.speed = 2500.0
	await _frames(12)
	assert(player.current_hp == 88 and not is_instance_valid(big), "Large rounds use swept body-sized collision")
	lab.reset_playground()
	await _frames(2)
	assert(lab.get_node("EnemyProjectiles").get_child_count() == 0)
	assert(player.incoming_status.poison_remaining == 0.0 and player.incoming_status.push_velocity == Vector2.ZERO)
	assert(link.is_alive and boss.linked_shield_active and not laser.get_node("Laser").visible)
	print("PASS: centered scaled health bars; arc landing/pools/poison; real stun and knockback rounds; fire dash; locked laser dodge/hit/interrupt; linked invulnerability/remote death/reset; large swept projectile; pause/reset cleanup")
	lab.queue_free()
	await process_frame
	quit()
