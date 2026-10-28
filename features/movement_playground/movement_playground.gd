extends Node2D

@onready var _player_health: DamageHealthBar = $CanvasLayer/PlayerHealth

@onready var _player: PlaygroundPlayer = $Player
@onready var _camera: Camera2D = $Player/Camera2D
@onready var _pause_menu: PlaygroundPauseMenu = $PauseMenu
@onready var _dash_hint: Label = $CanvasLayer/DashHint
@onready var _dash_meter: ProgressBar = $CanvasLayer/DashMeter
@onready var _projectiles: Node2D = $Projectiles
@onready var _arsenal_label: Label = $CanvasLayer/ArsenalLabel
@onready var _modifier_label: Label = $CanvasLayer/ModifierPanel/Content/Stacks
@onready var _modifier_panel: PanelContainer = $CanvasLayer/ModifierPanel

var _preferences: ControlPreferences = ControlPreferences.new()
var _hud_elapsed: float = 0.0

func _ready() -> void:
	_player.health_changed.connect(_on_player_health_changed)
	_player.reset_performed.connect(_on_player_reset)
	$PlayerDamageFeedback.configure(_player, _camera, _player_health)
	_player_health.set_health(_player.current_hp, _player.max_hp, false)
	$TouchControls.configure(_player, _pause_menu)
	$TouchControls.reset_requested.connect(reset_playground)
	_preferences.load_preferences()
	_preferences.apply_audio()
	_player.control_mode = _preferences.control_mode
	_pause_menu.configure(_preferences)
	_pause_menu.control_mode_applied.connect(_on_control_mode_applied)
	_player.shooter.weapon_selected.connect(_on_weapon_selected)
	_player.shooter.modifiers_changed.connect(_update_combat_hud)
	_player.shooter.configure(_projectiles, _player)

func _on_weapon_selected(_display_name: String) -> void:
	_update_combat_hud()

func _update_combat_hud() -> void:
	var weapon: WeaponDefinition = _player.shooter.active_weapon
	if weapon == null: return
	_arsenal_label.text = "%d DMG / %.1f shots per sec / %d bullets / %d pierce / %.0f%% crit\nWalk over pickups to stack upgrades. F: auto fire on/off" % [weapon.projectile.damage,
		weapon.attacks_per_second, weapon.bullet_count, weapon.projectile.pierce_count, weapon.projectile.crit_chance * 100.0]
	$CanvasLayer/EnemyHint.text = "< HOSTILE FIELD   /   Hits: %d   /   R resets" % _player.hits_taken
	_modifier_label.text = _player.shooter.modifier_summary()
	_modifier_panel.reset_size()
	_modifier_panel.visible = not _player.touch_input_enabled
	$CanvasLayer/Header.visible = not _player.touch_input_enabled
	$CanvasLayer/ArsenalLabel.visible = not _player.touch_input_enabled
	$CanvasLayer/Help.visible = not _player.touch_input_enabled
	$CanvasLayer/EnemyHint.visible = not _player.touch_input_enabled

func _process(delta: float) -> void:
	_dash_meter.value = 1.0 - _player.dash_cooldown_remaining / _player.effective_dash_cooldown
	_dash_hint.text = "SPACE / RB  Dash %d/%d  |  %.2fs recharge" % [
		_player.dash_charges, _player.max_dash_charges, _player.effective_dash_cooldown]
	_hud_elapsed += delta
	if _hud_elapsed >= 0.2:
		_hud_elapsed = 0.0
		_update_combat_hud()

func _on_control_mode_applied(mode: PlaygroundPlayer.ControlMode) -> void:
	_player.control_mode = mode
	_player.velocity = Vector2.ZERO

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.is_pressed() or event.is_echo(): return
	var key_event: InputEventKey = event as InputEventKey
	match key_event.physical_keycode:
		KEY_R:
			reset_playground()
		KEY_F11:
			var fullscreen: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fullscreen
				else DisplayServer.WINDOW_MODE_FULLSCREEN)

func _on_player_health_changed(current: int, maximum: int) -> void:
	_player_health.set_health(current, maximum)
	var hint: Label = $CanvasLayer/PlayerHealthHint
	if current == 0: hint.text = "DEPLETED / Press R to reset"
	elif current <= maximum / 4: hint.text = "LOW HULL / Find a green REPAIR pickup"
	elif current < maximum: hint.text = "Green REPAIR pickups restore health / R resets"
	else: hint.text = "R restores health and resets the encounter"
	hint.modulate = Color(1, 0.4, 0.3) if current <= maximum / 4 else Color.WHITE

func _on_player_reset() -> void:
	_player_health.set_health(_player.current_hp, _player.max_hp, false)

func reset_playground() -> void:
	_player.reset_to_spawn()
	$EnemyField.reset_encounter()
	for shot: Node in $EnemyProjectiles.get_children(): shot.queue_free()
	_camera.reset_smoothing()
