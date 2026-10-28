class_name PlayerStatus
extends Node

enum Kind { NONE, POISON, BURN, STUN, KNOCKBACK }
var poison_remaining: float = 0.0
var burn_remaining: float = 0.0
var stun_remaining: float = 0.0
var push_velocity: Vector2 = Vector2.ZERO
var _tick_remaining: float = 0.5
@onready var _player: PlaygroundPlayer = get_parent() as PlaygroundPlayer
var is_stunned: bool:
	get: return stun_remaining > 0.0
var tint: Color:
	get:
		if is_stunned: return Color(0.75, 0.4, 1.0)
		if burn_remaining > 0.0: return Color(1.0, 0.55, 0.2)
		if poison_remaining > 0.0: return Color(0.5, 1.0, 0.3)
		return Color.WHITE
func apply(kind: Kind, duration: float, strength: float, direction: Vector2) -> void:
	if get_tree().paused or not _player.is_alive: return
	match kind:
		Kind.POISON:
			if poison_remaining <= 0.0: $PoisonSound.trigger()
			poison_remaining = maxf(poison_remaining, duration)
		Kind.BURN:
			if burn_remaining <= 0.0: $BurnSound.trigger()
			burn_remaining = maxf(burn_remaining, duration)
		Kind.STUN:
			$StunSound.trigger()
			stun_remaining = maxf(stun_remaining, duration)
			_player.shooter.firing_blocked = true
		Kind.KNOCKBACK:
			push_velocity = (push_velocity + direction.normalized() * strength).limit_length(1200.0)
func _physics_process(delta: float) -> void:
	if not _player.is_alive:
		clear()
		return
	_tick_remaining -= delta
	if _tick_remaining <= 0.0:
		_tick_remaining = 0.5
		var damage: int = (2 if burn_remaining > 0.0 else 0) + (1 if poison_remaining > 0.0 else 0)
		if damage > 0: _player.receive_enemy_hit(damage, _player.global_position)
	poison_remaining = maxf(0.0, poison_remaining - delta)
	burn_remaining = maxf(0.0, burn_remaining - delta)
	stun_remaining = maxf(0.0, stun_remaining - delta)
func clear() -> void:
	poison_remaining = 0.0
	burn_remaining = 0.0
	stun_remaining = 0.0
	push_velocity = Vector2.ZERO
	_tick_remaining = 0.5
