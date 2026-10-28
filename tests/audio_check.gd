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
	for bus: String in ["Master", "Combat", "Effects", "UI"]:
		assert(AudioServer.get_bus_index(bus) >= 0)
	var target: TargetDummy = lab.get_node("TargetDummies/DummyCenter")
	shooter.fire_volley()
	assert(shooter.get_node("ShotSound").playing)
	target.apply_damage(1)
	assert(target.get_node("HitSound").playing)
	target.apply_damage(10, DamageSource.Kind.CRITICAL)
	assert(target.get_node("CritSound").playing)
	target._on_status_damage(1, 1)
	assert(target.get_node("BurnSound").playing and target.get_node("PoisonSound").playing)
	var ice: StatusEffectDefinition = load("res://data/effects/ice.tres")
	target.apply_status(ice, Vector2.UP)
	assert(target.get_node("StatusSound").playing)
	var pickup: UpgradePickup = lab.get_node("Pickups/CritChanceA")
	assert(pickup.try_collect(player) and pickup.get_node("PickupSound").playing)
	pickup._on_respawn_timeout()
	assert(pickup.get_node("RechargeSound").playing)
	assert(player.try_dash() and player.get_node("DashSound").playing)
	var live: TargetDummy = lab.get_node("LiveTargets/LiveCenter")
	live.apply_damage(100)
	assert(live.get_node("KillSound").playing)
	live._on_respawn_timeout()
	assert(live.get_node("RespawnSound").playing)
	var cue: ActionSound = target.get_node("HitSound")
	var pitch: float = cue.pitch_scale
	cue.trigger()
	assert(cue.pitch_scale == pitch, "Retrigger cooldown must prevent rapid repeats")
	var menu: PlaygroundPauseMenu = lab.get_node("PauseMenu")
	menu.set_paused(true)
	assert(menu.get_node("PauseSound").playing)
	assert(not cue.can_process() and menu.get_node("ClickSound").can_process())
	var cooldown: float = cue._cooldown
	await create_timer(0.12).timeout
	assert(cue._cooldown == cooldown and cue.stream_paused)
	menu._on_settings_pressed()
	var base: String = "Overlay/Center/Panel/Margin/Settings/Tabs/"
	var tabs: TabContainer = menu.get_node(base.trim_suffix("/"))
	assert(not tabs.is_tab_disabled(1) and tabs.is_tab_disabled(2))
	tabs.current_tab = 1
	var content: VBoxContainer = menu.get_node(base + "Sound/Content")
	content.get_node("MasterRow/Volume").value = 65
	content.get_node("CombatRow/Volume").value = 30
	content.get_node("EffectsRow/Volume").value = 0
	content.get_node("UIRow/Volume").value = 55
	assert(is_equal_approx(AudioServer.get_bus_volume_linear(1), 0.3))
	assert(AudioServer.is_bus_mute(2))
	content.get_node("Mute").button_pressed = true
	assert(AudioServer.is_bus_mute(0))
	content.get_node("Mute").button_pressed = false
	content.get_node("Previews/Shot").pressed.emit()
	assert(menu.get_node("PreviewShot").playing)
	menu._on_apply_pressed()
	var saved: ControlPreferences = ControlPreferences.new()
	saved.load_preferences()
	assert(is_equal_approx(saved.sound_volumes["Master"], 0.65))
	assert(is_equal_approx(saved.sound_volumes["Combat"], 0.3))
	assert(saved.sound_volumes["Effects"] == 0.0 and not saved.sound_muted)
	assert(saved.save_mode(PlaygroundPlayer.ControlMode.CURSOR_STEERING) == OK)
	var reloaded: ControlPreferences = ControlPreferences.new()
	reloaded.load_preferences()
	assert(reloaded.sound_volumes == saved.sound_volumes)
	content.get_node("CombatRow/Volume").value = 99
	menu._on_back_pressed()
	assert(is_equal_approx(AudioServer.get_bus_volume_linear(1), 0.3), "Cancel restores saved mix")
	menu._on_settings_pressed()
	content.get_node("Mute").button_pressed = true
	menu._on_apply_pressed()
	reloaded.load_preferences()
	assert(reloaded.sound_muted)
	menu.set_paused(false)
	assert(not paused and AudioServer.is_bus_mute(0))
	print("PASS: authored action cues, cooldown/polyphony, paused gameplay audio and live menu audio, bus preview/mute, zero volume, atomic persistence, controls preservation and cancel rollback")
	lab.queue_free()
	await create_timer(0.5).timeout
	quit()
