class_name EnvironmentalObstacle
extends Area2D

enum Kind { STATIC_SPIKES, PRESSURE_SPIKES, SHOCK_TILE, LASER_GATE }
enum Phase { DORMANT, WARNING, ACTIVE, COOLDOWN }
@export var kind: Kind = Kind.STATIC_SPIKES
@export_range(1, 30, 1) var damage: int = 8
@export var effect: PlayerStatus.Kind = PlayerStatus.Kind.NONE
@export_range(0.1, 3.0, 0.05) var effect_duration: float = 0.35
@export_range(0.3, 3.0, 0.05) var warning_time: float = 0.8
@export_range(0.3, 5.0, 0.1) var active_time: float = 1.2
@export_range(0.5, 8.0, 0.1) var cooldown_time: float = 2.5
@export_range(0.0, 5.0, 0.1) var phase_delay: float = 0.0
@export var accent: Color = Color(1, 0.4, 0.25)
@export var player_path: NodePath = ^"../../Player"
var phase: Phase = Phase.DORMANT
var remaining: float = 0.0
var _hit_timer: float = 0.0
var _clock: float = 0.0
var _player: PlaygroundPlayer
func _ready() -> void:
	_player = get_node_or_null(player_path) as PlaygroundPlayer
	reset_obstacle()
func reset_obstacle() -> void:
	$WarningSound.stop()
	$ActivateSound.stop()
	_clock = 0.0
	_hit_timer = 0.0
	phase = Phase.ACTIVE if kind == Kind.STATIC_SPIKES else Phase.DORMANT
	remaining = phase_delay
	_update_visuals()
func _physics_process(delta: float) -> void:
	if get_tree().paused: return
	_clock += delta
	var occupants: Array[Node2D] = get_overlapping_bodies()
	var occupied: bool = false
	for body: Node2D in occupants:
		if body is PlaygroundPlayer and body.is_alive: occupied = true
	if kind != Kind.STATIC_SPIKES:
		if phase == Phase.DORMANT:
			remaining = maxf(0.0, remaining - delta)
			if remaining <= 0.0 and (kind != Kind.PRESSURE_SPIKES or occupied): _set_phase(Phase.WARNING, warning_time)
		else:
			remaining -= delta
			if remaining <= 0.0:
				match phase:
					Phase.WARNING: _set_phase(Phase.ACTIVE, active_time)
					Phase.ACTIVE: _set_phase(Phase.COOLDOWN, cooldown_time)
					Phase.COOLDOWN: _set_phase(Phase.DORMANT, 0.0)
	_hit_timer = maxf(0.0, _hit_timer - delta)
	if phase == Phase.ACTIVE and occupied and _hit_timer <= 0.0:
		_hit_timer = 0.5
		for body: Node2D in occupants:
			var player: PlaygroundPlayer = body as PlaygroundPlayer
			if player != null: player.receive_enemy_attack(damage, global_position, effect, effect_duration)
	_update_visuals()
func _set_phase(next: Phase, duration: float) -> void:
	phase = next
	remaining = duration
	if next == Phase.ACTIVE: _hit_timer = 0.0
	if _player != null and _player.global_position.distance_to(global_position) < 700.0:
		if next == Phase.WARNING: $WarningSound.trigger()
		elif next == Phase.ACTIVE: $ActivateSound.trigger()
func _update_visuals() -> void:
	$Danger.visible = phase == Phase.ACTIVE
	$Danger.modulate = accent
	var state_color: Color = accent if phase == Phase.ACTIVE else Color(0.4, 0.7, 0.7)
	$Border.default_color = Color(state_color, 0.9 if phase == Phase.ACTIVE else 0.35)
	var status: String = "LIVE / %d DAMAGE" % damage
	if kind != Kind.STATIC_SPIKES: status = "LIVE / %d DMG / %.1fs" % [damage, maxf(0.0, remaining)]
	match phase:
		Phase.DORMANT: status = "ARMED" if kind == Kind.PRESSURE_SPIKES else "SAFE"
		Phase.WARNING:
			status = "WARNING / %.1fs" % maxf(0.0, remaining)
			$Border.default_color = Color(1, 0.85, 0.35, 0.5 + 0.5 * absf(sin(_clock * 14.0)))
		Phase.COOLDOWN: status = "SAFE / %.1fs" % maxf(0.0, remaining)
	$Status.text = status
	$Status.modulate = Color(1, 0.85, 0.35) if phase == Phase.WARNING else state_color
