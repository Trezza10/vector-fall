class_name ProjectileDefinition
extends Resource

enum TrailStyle { NONE, LINE, PARTICLES }

@export_range(1, 10000, 1) var damage: int = 5
@export_range(0.0, 1.0, 0.01) var crit_chance: float = 0.0
@export_range(1.0, 10.0, 0.1) var crit_multiplier: float = 2.0
@export var damage_source: DamageSource.Kind = DamageSource.Kind.BULLET
@export_range(100.0, 3000.0, 10.0) var speed: float = 900.0
@export_range(0.1, 10.0, 0.1) var lifetime: float = 1.6
@export_range(0, 32, 1) var pierce_count: int = 0
@export var shape: ShapeDefinition
@export var colors: ShapeColors
@export var visual_scale: Vector2 = Vector2(0.65, 1.6)
@export var trail_style: TrailStyle = TrailStyle.LINE
@export_range(0.0, 120.0, 1.0) var trail_length: float = 24.0
@export var impact_particles: bool = true
@export var on_hit_effects: Array[StatusEffectDefinition] = []

func working_copy() -> ProjectileDefinition:
	var copy: ProjectileDefinition = duplicate(false) as ProjectileDefinition
	# External .tres references need explicit copies, including their nested visual data.
	if shape != null: copy.shape = shape.duplicate(false) as ShapeDefinition
	if colors != null: copy.colors = colors.duplicate(false) as ShapeColors
	copy.on_hit_effects = []
	for effect: StatusEffectDefinition in on_hit_effects:
		copy.on_hit_effects.append(effect.duplicate(false) as StatusEffectDefinition)
	return copy
