@tool
class_name WeaponModification
extends Resource

@export var id: StringName
@export var display_name: String = "Modification"
@export var description: String = "+1 bullet"
## Zero means the stack lasts for this run; positive values are seconds of gameplay.
@export_range(0.0, 300.0, 1.0) var duration_seconds: float = 0.0
@export var colors: ShapeColors
@export_range(0, 16, 1) var bullet_count_bonus: int = 0
@export_range(0.0, 90.0, 1.0) var spread_bonus_degrees: float = 0.0
## Additive fraction of base attack speed: two 0.2 stacks mean +40%, not +44%.
@export_range(0.0, 2.0, 0.05) var attack_speed_bonus: float = 0.0
@export_range(0, 1000, 1) var damage_bonus: int = 0
@export_range(0, 16, 1) var pierce_bonus: int = 0
@export_range(0.0, 1500.0, 10.0) var projectile_speed_bonus: float = 0.0
@export_range(0.0, 1.0, 0.01) var crit_chance_bonus: float = 0.0
@export_group("Dash Upgrades")
@export_range(0, 7, 1) var dash_charge_bonus: int = 0
## Additive fraction removed from base recharge time, capped by the player.
@export_range(0.0, 0.8, 0.05) var dash_cooldown_reduction: float = 0.0
@export_group("On-hit Effects")
@export var on_hit_effects: Array[StatusEffectDefinition] = []

func working_copy() -> WeaponModification:
	var copy: WeaponModification = duplicate(false) as WeaponModification
	if colors != null: copy.colors = colors.duplicate(false) as ShapeColors
	copy.on_hit_effects = []
	for effect: StatusEffectDefinition in on_hit_effects:
		copy.on_hit_effects.append(effect.duplicate(false) as StatusEffectDefinition)
	return copy
