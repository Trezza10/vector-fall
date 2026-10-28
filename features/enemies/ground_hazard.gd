class_name GroundHazard
extends Area2D
@export var effect: PlayerStatus.Kind = PlayerStatus.Kind.POISON
@export var radius: float = 70.0
@export var lifetime: float = 4.0
@export var contact_damage: int = 1
@export var effect_duration: float = 2.0
@export var tick_interval: float = 0.5
var _tick: float = 0.0
func _ready() -> void:
	($CollisionShape2D.shape as CircleShape2D).radius = radius
	$Surface.scale = Vector2.ONE * radius / 60.0
	$Rim.scale = Vector2.ONE * radius / 60.0
	modulate = Color(0.55, 1.0, 0.25) if effect == PlayerStatus.Kind.POISON else Color(1.0, 0.4, 0.12)
func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	modulate.a = minf(1.0, lifetime)
	_tick -= delta
	if _tick > 0.0: return
	_tick = maxf(0.1, tick_interval)
	for body: Node2D in get_overlapping_bodies():
		var player: PlaygroundPlayer = body as PlaygroundPlayer
		if player != null: player.receive_enemy_attack(contact_damage, global_position, effect, effect_duration)
