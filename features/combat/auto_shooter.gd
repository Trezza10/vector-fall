class_name AutoShooter
extends Node2D

signal weapon_selected(display_name: String)
signal volley_fired(bullet_count: int)
signal modifiers_changed

class ModifierStack:
	extends RefCounted
	var definition: WeaponModification
	var remaining_seconds: float

	func _init(modification: WeaponModification) -> void:
		definition = modification.working_copy()
		remaining_seconds = definition.duration_seconds

@export var arsenal: Array[WeaponDefinition] = []
@export var auto_fire_enabled: bool = true

var firing_blocked: bool = false

var dash_charge_bonus: int = 0
var dash_cooldown_reduction: float = 0.0

var aim_direction: Vector2 = Vector2.UP
var _spawn_parent: Node2D
var _owner_body: PhysicsBody2D
var _working_weapon: WeaponDefinition
var _working_arsenal: Array[WeaponDefinition] = []
var _base_weapon: WeaponDefinition
var _modifiers: Array[ModifierStack] = []
var _weapon_index: int = 0
var _time_until_shot: float = 0.0

var active_weapon: WeaponDefinition:
	get: return _working_weapon

func configure(spawn_parent: Node2D, owner_body: PhysicsBody2D) -> void:
	_spawn_parent = spawn_parent
	_owner_body = owner_body
	_working_arsenal.clear()
	_modifiers.clear()
	for preset: WeaponDefinition in arsenal:
		assert(preset != null and preset.projectile != null and preset.projectile_scene != null,
			"Each arsenal entry requires a projectile definition and scene.")
		_working_arsenal.append(preset.working_copy())
	if not arsenal.is_empty(): select_weapon(0)
	modifiers_changed.emit()

func _physics_process(delta: float) -> void:
	_update_modifiers(delta)
	if firing_blocked or not auto_fire_enabled or _working_weapon == null or _spawn_parent == null: return
	_time_until_shot -= delta
	if _time_until_shot <= 0.0:
		fire_volley()
		# No paused-time catch-up or burst of queued shots after changing weapons.
		_time_until_shot = maxf(-delta, _time_until_shot) + 1.0 / maxf(0.1, _working_weapon.attacks_per_second)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo(): return
	if event.is_action_pressed("toggle_auto_fire"):
		auto_fire_enabled = not auto_fire_enabled
		$ShotSound.trigger()
		get_viewport().set_input_as_handled()

func select_weapon(index: int) -> void:
	if index < 0 or index >= _working_arsenal.size(): return
	_base_weapon = _working_arsenal[index]
	_weapon_index = index
	_time_until_shot = 0.0
	_rebuild_weapon()
	weapon_selected.emit(_working_weapon.display_name)

func apply_modifier(definition: WeaponModification) -> bool:
	if get_tree().paused or definition == null or definition.id == &"" or _base_weapon == null:
		return false
	_modifiers.append(ModifierStack.new(definition))
	_rebuild_weapon()
	modifiers_changed.emit()
	return true

func modifier_stack_count(id: StringName) -> int:
	var count: int = 0
	for stack: ModifierStack in _modifiers:
		if stack.definition.id == id: count += 1
	return count

func modifier_time_left(id: StringName) -> float:
	var earliest: float = INF
	for stack: ModifierStack in _modifiers:
		if stack.definition.id == id and stack.definition.duration_seconds > 0.0:
			earliest = minf(earliest, stack.remaining_seconds)
	return 0.0 if is_inf(earliest) else earliest

func modifier_summary() -> String:
	var lines: PackedStringArray = []
	var seen: Array[StringName] = []
	for stack: ModifierStack in _modifiers:
		var id: StringName = stack.definition.id
		if id in seen: continue
		seen.append(id)
		var seconds: float = modifier_time_left(id)
		var timer: String = "run" if seconds <= 0.0 else "%ds next" % ceili(seconds)
		lines.append("%s  x%d   /   %s" % [stack.definition.display_name, modifier_stack_count(id), timer])
	return "Walk over a glowing pickup.\nEvery stack has its own timer." if lines.is_empty() else "\n".join(lines)

func _update_modifiers(delta: float) -> void:
	var expired: bool = false
	for index: int in range(_modifiers.size() - 1, -1, -1):
		var stack: ModifierStack = _modifiers[index]
		if stack.definition.duration_seconds <= 0.0: continue
		stack.remaining_seconds -= delta
		if stack.remaining_seconds <= 0.0:
			_modifiers.remove_at(index)
			expired = true
	if expired:
		_rebuild_weapon()
		modifiers_changed.emit()

func _rebuild_weapon() -> void:
	if _base_weapon == null: return
	var previous_rate: float = _base_weapon.attacks_per_second
	if _working_weapon != null: previous_rate = _working_weapon.attacks_per_second
	_working_weapon = _base_weapon.working_copy()
	dash_charge_bonus = 0
	dash_cooldown_reduction = 0.0
	var attack_bonus: float = 0.0
	for stack: ModifierStack in _modifiers:
		var modifier: WeaponModification = stack.definition
		dash_charge_bonus += modifier.dash_charge_bonus
		dash_cooldown_reduction += modifier.dash_cooldown_reduction
		_working_weapon.bullet_count += modifier.bullet_count_bonus
		_working_weapon.spread_degrees += modifier.spread_bonus_degrees
		attack_bonus += modifier.attack_speed_bonus
		_working_weapon.projectile.damage += modifier.damage_bonus
		_working_weapon.projectile.crit_chance += modifier.crit_chance_bonus
		_working_weapon.projectile.pierce_count += modifier.pierce_bonus
		_working_weapon.projectile.speed += modifier.projectile_speed_bonus
		for effect: StatusEffectDefinition in modifier.on_hit_effects:
			StatusEffectDefinition.merge_into(_working_weapon.projectile.on_hit_effects, effect)
	if not _working_weapon.projectile.on_hit_effects.is_empty():
		var tint: Color = Color(0, 0, 0, 0)
		for effect: StatusEffectDefinition in _working_weapon.projectile.on_hit_effects:
			tint += effect.color
		tint /= float(_working_weapon.projectile.on_hit_effects.size())
		_working_weapon.projectile.colors.outline = tint
		_working_weapon.projectile.colors.fill = tint.lerp(Color.WHITE, 0.55)
	_working_weapon.attacks_per_second = clampf(_base_weapon.attacks_per_second * (1.0 + attack_bonus), 0.1, 30.0)
	_working_weapon.bullet_count = clampi(_working_weapon.bullet_count, 1, 32)
	_working_weapon.spread_degrees = clampf(_working_weapon.spread_degrees, 0.0, 180.0)
	_working_weapon.projectile.damage = clampi(_working_weapon.projectile.damage, 1, 10000)
	_working_weapon.projectile.pierce_count = clampi(_working_weapon.projectile.pierce_count, 0, 32)
	_working_weapon.projectile.speed = clampf(_working_weapon.projectile.speed, 100.0, 3000.0)
	_working_weapon.projectile.crit_chance = clampf(_working_weapon.projectile.crit_chance, 0.0, 1.0)
	# Preserve progress through the firing interval when a stack is added or expires.
	_time_until_shot = clampf(_time_until_shot * previous_rate, 0.0, 1.0) / _working_weapon.attacks_per_second

func fire_volley() -> int:
	if get_tree().paused or firing_blocked or _working_weapon == null or _spawn_parent == null: return 0
	var direction: Vector2 = aim_direction.normalized()
	if direction.is_zero_approx(): return 0
	var angles: PackedFloat32Array = _working_weapon.spread_angles()
	# Each volley owns a snapshot, so later upgrades cannot change bullets already in flight.
	var shot_definition: ProjectileDefinition = _working_weapon.projectile.working_copy()
	for angle: float in angles:
		var heading: Vector2 = direction.rotated(angle)
		var bullet: CombatProjectile = _working_weapon.projectile_scene.instantiate() as CombatProjectile
		assert(bullet != null, "Projectile scenes must use CombatProjectile or a derived script.")
		bullet.configure(shot_definition, heading, global_position, _owner_body.get_rid())
		bullet.position = _spawn_parent.to_local(global_position + heading * _working_weapon.muzzle_distance)
		_spawn_parent.add_child(bullet)
		bullet.reset_physics_interpolation()
	$ShotSound.trigger()
	volley_fired.emit(angles.size())
	return angles.size()
