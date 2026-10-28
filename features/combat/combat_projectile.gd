class_name CombatProjectile
extends Node2D

const IMPACT_SCENE: PackedScene = preload("res://visuals/effects/bullet_impact.tscn")

@onready var _visual: ShapeVisual = $ShapeVisual
@onready var _trail: Line2D = $Trail
@onready var _particles: CPUParticles2D = $Particles

var _definition: ProjectileDefinition
var _heading: Vector2
var _previous_position: Vector2
var _excluded: Array[RID] = []
var _remaining_life: float
var _pierces_left: int

func configure(definition: ProjectileDefinition, heading: Vector2, origin: Vector2, owner_rid: RID) -> void:
	_definition = definition
	_heading = heading.normalized()
	_previous_position = origin
	_excluded = [owner_rid]
	_remaining_life = definition.lifetime
	_pierces_left = definition.pierce_count

func _ready() -> void:
	assert(_definition != null and _definition.shape != null and _definition.colors != null)
	rotation = _heading.angle() + PI / 2.0
	_visual.configure(_definition.shape, _definition.colors)
	_visual.scale = _definition.visual_scale
	_trail.visible = _definition.trail_style == ProjectileDefinition.TrailStyle.LINE
	_trail.points = PackedVector2Array([Vector2(0, _definition.trail_length), Vector2.ZERO])
	_trail.modulate = _definition.colors.outline
	_particles.modulate = _definition.colors.outline
	_particles.emitting = _definition.trail_style == ProjectileDefinition.TrailStyle.PARTICLES

func _physics_process(delta: float) -> void:
	_remaining_life -= delta
	if _remaining_life <= 0.0:
		queue_free()
		return
	var destination: Vector2 = global_position + _heading * _definition.speed * delta
	var from: Vector2 = _previous_position
	# Sweep from the muzzle's owner on the first tick too, so a muzzle cannot skip a wall.
	for index: int in range(34):
		var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(from, destination, 3, _excluded)
		var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
		if hit.is_empty(): break
		var target: TargetDummy = hit["collider"] as TargetDummy
		var impact_position: Vector2 = hit["position"]
		if target != null:
			if target.is_alive:
				apply_hit(target)
				if target.is_alive:
					for effect: StatusEffectDefinition in _definition.on_hit_effects:
						target.apply_status(effect, _heading)
			_excluded.append(hit["rid"])
		_spawn_impact(impact_position, target == null)
		if target == null or _pierces_left <= 0:
			global_position = impact_position
			queue_free()
			return
		_pierces_left -= 1
		from = impact_position + _heading * 0.1
	global_position = destination
	_previous_position = destination

func _spawn_impact(at: Vector2, wall_hit: bool = false) -> void:
	if not _definition.impact_particles: return
	var impact: CPUParticles2D = IMPACT_SCENE.instantiate() as CPUParticles2D
	get_parent().add_child(impact)
	impact.global_position = at
	impact.rotation = (-_heading).angle()
	impact.modulate = _definition.colors.outline
	if wall_hit: impact.get_node("WallSound").play()
	impact.restart()
	impact.emitting = true

## Roll separately for each direct impact, including pierced targets. DoT never rolls.
func apply_hit(target: TargetDummy) -> int:
	if get_tree().paused or not target.is_alive: return 0
	var critical: bool = randf() < clampf(_definition.crit_chance, 0.0, 1.0)
	var amount: int = ceili(_definition.damage * maxf(1.0, _definition.crit_multiplier)) if critical else _definition.damage
	var source: DamageSource.Kind = DamageSource.Kind.CRITICAL if critical else _definition.damage_source
	return target.apply_damage(amount, source)
