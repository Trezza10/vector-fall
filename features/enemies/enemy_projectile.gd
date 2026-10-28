class_name EnemyProjectile
extends Node2D
const HAZARD: PackedScene = preload("res://features/enemies/ground_hazard.tscn")
var heading: Vector2 = Vector2.RIGHT
var speed: float = 190.0
var damage: int = 1
var remaining_lifetime: float = 4.0
var effect: PlayerStatus.Kind = PlayerStatus.Kind.NONE
var effect_duration: float = 0.0
var knockback_strength: float = 0.0
var collision_radius: float = 0.0
var visual_size: float = 1.0
var shot_color: Color = Color(1, 0.46, 0.2)
var hazard_radius: float = 70.0
var hazard_lifetime: float = 4.0
var flight_duration: float = 0.0
var landing_position: Vector2
var _flight_elapsed: float = 0.0
var _launch_position: Vector2
var _shape: CircleShape2D
func _ready() -> void:
	heading = heading.normalized()
	rotation = heading.angle() + PI / 2.0
	$Core.scale = Vector2.ONE * visual_size
	$Center.scale = Vector2.ONE * visual_size
	$Core.color = shot_color
	$Tail.default_color = Color(shot_color, 0.5)
	if collision_radius > 0.0:
		_shape = CircleShape2D.new()
		_shape.radius = collision_radius
	if flight_duration > 0.0:
		rotation = 0.0
		_launch_position = global_position
		$Tail.hide()
		$Shadow.show()
		$LandingMark.show()
		$LandingMark.global_position = landing_position
func _physics_process(delta: float) -> void:
	if flight_duration > 0.0:
		_flight_elapsed += delta
		var progress: float = minf(1.0, _flight_elapsed / flight_duration)
		global_position = _launch_position.lerp(landing_position, progress)
		var height: float = -sin(progress * PI) * 120.0
		$Core.position.y = height
		$Center.position.y = height
		if progress >= 1.0:
			var pool: GroundHazard = HAZARD.instantiate() as GroundHazard
			pool.position = get_parent().to_local(landing_position)
			pool.effect = PlayerStatus.Kind.POISON
			pool.radius = hazard_radius
			pool.lifetime = hazard_lifetime
			get_parent().add_child(pool)
			queue_free()
		return
	remaining_lifetime -= delta
	if remaining_lifetime <= 0.0:
		queue_free()
		return
	var destination: Vector2 = global_position + heading * speed * delta
	var hit: Dictionary = _sweep_hit(destination)
	if not hit.is_empty():
		var player: PlaygroundPlayer = hit.collider as PlaygroundPlayer
		if player != null: player.receive_enemy_attack(damage, global_position - heading * 40.0, effect, effect_duration, knockback_strength)
		queue_free()
		return
	global_position = destination
func _sweep_hit(destination: Vector2) -> Dictionary:
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	if _shape == null:
		return space.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, destination, 1))
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = _shape
	query.transform = Transform2D(0.0, global_position)
	query.collision_mask = 1
	var initial: Array[Dictionary] = space.intersect_shape(query, 8)
	if not initial.is_empty(): return initial[0]
	query.motion = destination - global_position
	var fractions: PackedFloat32Array = space.cast_motion(query)
	if fractions[0] >= 1.0: return {}
	query.transform.origin = global_position.lerp(destination, minf(1.0, fractions[1] + 0.001))
	query.motion = Vector2.ZERO
	var hits: Array[Dictionary] = space.intersect_shape(query, 8)
	return hits[0] if not hits.is_empty() else {}
