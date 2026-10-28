class_name EnemyProjectile
extends Node2D

var heading: Vector2 = Vector2.RIGHT
var speed: float = 190.0
var damage: int = 1
var remaining_lifetime: float = 4.0

func _ready() -> void:
	rotation = heading.angle() + PI / 2.0

func _physics_process(delta: float) -> void:
	remaining_lifetime -= delta
	if remaining_lifetime <= 0.0:
		queue_free()
		return
	var destination: Vector2 = global_position + heading * speed * delta
	# Layer 1 already contains walls and the player; enemies are on layer 2.
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position, destination, 1)
	var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var player: PlaygroundPlayer = hit.collider as PlaygroundPlayer
		if player != null: player.receive_enemy_hit(damage, global_position)
		queue_free()
		return
	global_position = destination
