class_name TargetStatus
extends Node2D

signal damage_tick(burn_amount: int, poison_amount: int)
signal knockback_requested(offset: Vector2)
signal state_changed

class ActiveEffect:
	extends RefCounted
	var definition: StatusEffectDefinition
	var remaining: float
	var tick_elapsed: float = 0.0

	func _init(effect: StatusEffectDefinition) -> void:
		definition = effect.duplicate(false) as StatusEffectDefinition
		remaining = effect.duration_seconds

@onready var _aura: Line2D = $Aura
@onready var _label: Label = $StatusLabel
@onready var _particles: CPUParticles2D = $Particles

var _effects: Array[ActiveEffect] = []
var movement_multiplier: float = 1.0
var damage_multiplier: float = 1.0
var is_stunned: bool = false
var tint: Color = Color.WHITE

func _ready() -> void:
	_refresh()

func apply_effect(effect: StatusEffectDefinition, direction: Vector2) -> void:
	if get_tree().paused or effect == null: return
	if effect.kind == StatusEffectDefinition.Kind.KNOCKBACK:
		knockback_requested.emit(direction.normalized() * effect.potency)
	for active: ActiveEffect in _effects:
		if active.definition.kind != effect.kind: continue
		active.remaining = maxf(active.remaining, effect.duration_seconds)
		active.definition.potency = maxf(active.definition.potency, effect.potency)
		active.definition.tick_interval = minf(active.definition.tick_interval, effect.tick_interval)
		_refresh()
		return
	_effects.append(ActiveEffect.new(effect))
	_refresh()

func has_effect(kind: StatusEffectDefinition.Kind) -> bool:
	for effect: ActiveEffect in _effects:
		if effect.definition.kind == kind: return true
	return false

func effect_strength(kind: StatusEffectDefinition.Kind) -> float:
	for effect: ActiveEffect in _effects:
		if effect.definition.kind == kind: return effect.definition.potency
	return 0.0

func effect_time_left(kind: StatusEffectDefinition.Kind) -> float:
	for effect: ActiveEffect in _effects:
		if effect.definition.kind == kind: return effect.remaining
	return 0.0

func clear_effects() -> void:
	_effects.clear()
	_refresh()
	_particles.restart()
	_particles.emitting = false

func _physics_process(delta: float) -> void:
	var burn_damage: int = 0
	var poison_damage: int = 0
	var expired: bool = false
	for index: int in range(_effects.size() - 1, -1, -1):
		var active: ActiveEffect = _effects[index]
		var elapsed: float = minf(delta, active.remaining)
		active.remaining -= elapsed
		var kind: StatusEffectDefinition.Kind = active.definition.kind
		if kind == StatusEffectDefinition.Kind.BURN or kind == StatusEffectDefinition.Kind.POISON:
			active.tick_elapsed += elapsed
			var interval: float = maxf(0.1, active.definition.tick_interval)
			while active.tick_elapsed + 0.00001 >= interval:
				active.tick_elapsed -= interval
				var damage: int = maxi(1, roundi(active.definition.potency))
				if kind == StatusEffectDefinition.Kind.BURN: burn_damage += damage
				else: poison_damage += damage
		if active.remaining <= 0.00001:
			_effects.remove_at(index)
			expired = true
	if expired: _refresh()
	_aura.rotation += delta * (2.0 if is_stunned else 0.5)
	# Emit after iteration: a lethal tick may synchronously clear all statuses.
	if burn_damage + poison_damage > 0: damage_tick.emit(burn_damage, poison_damage)

func _refresh() -> void:
	if not is_node_ready(): return
	movement_multiplier = 1.0
	damage_multiplier = 1.0
	is_stunned = false
	var names: PackedStringArray = []
	var sum: Color = Color(0, 0, 0, 0)
	for active: ActiveEffect in _effects:
		var effect: StatusEffectDefinition = active.definition
		names.append(effect.display_name.to_upper())
		sum += effect.color
		match effect.kind:
			StatusEffectDefinition.Kind.ICE: movement_multiplier = 1.0 - clampf(effect.potency, 0.0, 0.8)
			StatusEffectDefinition.Kind.STUN: is_stunned = true
			StatusEffectDefinition.Kind.MARK: damage_multiplier = 1.0 + clampf(effect.potency, 0.0, 1.0)
	if is_stunned: movement_multiplier = 0.0
	tint = Color.WHITE if _effects.is_empty() else sum / float(_effects.size())
	_aura.visible = not _effects.is_empty()
	_aura.modulate = tint
	_label.text = " / ".join(names)
	_label.modulate = tint
	_particles.modulate = tint
	_particles.emitting = not _effects.is_empty()
	set_physics_process(not _effects.is_empty())
	state_changed.emit()
