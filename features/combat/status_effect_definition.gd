@tool
class_name StatusEffectDefinition
extends Resource

enum Kind { BURN, POISON, ICE, STUN, KNOCKBACK, MARK }

@export var kind: Kind = Kind.BURN
@export var display_name: String = "Burn"
@export_range(0.1, 20.0, 0.1) var duration_seconds: float = 3.0
## Damage per tick, slow fraction, push distance, or extra damage fraction, depending on kind.
@export_range(0.0, 200.0, 0.05) var potency: float = 2.0
@export_range(0.1, 3.0, 0.1) var tick_interval: float = 0.5
@export var color: Color = Color(1.0, 0.4, 0.15)

static func merge_into(effects: Array[StatusEffectDefinition], incoming: StatusEffectDefinition) -> void:
	for effect: StatusEffectDefinition in effects:
		if effect.kind != incoming.kind: continue
		effect.potency += incoming.potency
		if effect.kind == Kind.STUN:
			effect.duration_seconds = minf(2.0, effect.duration_seconds + incoming.duration_seconds)
		else:
			effect.duration_seconds = maxf(effect.duration_seconds, incoming.duration_seconds)
		effect.tick_interval = minf(effect.tick_interval, incoming.tick_interval)
		_limit(effect)
		return
	var copy: StatusEffectDefinition = incoming.duplicate(false) as StatusEffectDefinition
	_limit(copy)
	effects.append(copy)

static func _limit(effect: StatusEffectDefinition) -> void:
	match effect.kind:
		Kind.ICE: effect.potency = minf(effect.potency, 0.8)
		Kind.MARK: effect.potency = minf(effect.potency, 1.0)
		Kind.KNOCKBACK: effect.potency = minf(effect.potency, 100.0)
		Kind.STUN: effect.duration_seconds = minf(effect.duration_seconds, 2.0)
