@tool
class_name UpgradePickup
extends Area2D

@export var modification: WeaponModification:
	set(value):
		modification = value
		_refresh_preview()
@export_range(0, 10000, 1) var healing_amount: int = 0:
	set(value):
		healing_amount = value
		_refresh_preview()
@export var healing_colors: ShapeColors:
	set(value):
		healing_colors = value
		_refresh_preview()

@export_range(0.5, 60.0, 0.5) var respawn_seconds: float = 8.0

@onready var _core: ShapeVisual = $Visual/Core
@onready var _ring: ShapeVisual = $Visual/Ring
@onready var _visual: Node2D = $Visual
@onready var _label: Label = $NameLabel
@onready var _detail: Label = $DetailLabel
@onready var _timer: Timer = $RespawnTimer
@onready var _burst: CPUParticles2D = $CollectBurst

var _available: bool = true
var _time: float = 0.0

var available: bool:
	get: return _available

func _ready() -> void:
	_refresh_preview()
	if Engine.is_editor_hint():
		set_process(false)
		return
	body_entered.connect(_on_body_entered)
	_timer.timeout.connect(_on_respawn_timeout)

func _process(delta: float) -> void:
	_time += delta
	if _available:
		_visual.position.y = sin(_time * 2.5) * 3.0
		_ring.rotation += delta * 0.4
	else:
		_detail.text = "RECHARGE / %ds" % ceili(_timer.time_left)

func _refresh_preview() -> void:
	if not is_node_ready(): return
	update_configuration_warnings()
	if healing_amount > 0:
		if healing_colors == null: return
		_core.colors = healing_colors
		_ring.colors = healing_colors
		_label.text = "REPAIR"
		_label.modulate = healing_colors.outline
		_detail.text = "+%d HP" % healing_amount
		_burst.modulate = healing_colors.outline
		return
	if modification == null or modification.colors == null: return
	_core.colors = modification.colors
	_ring.colors = modification.colors
	_label.text = modification.display_name.to_upper()
	_label.modulate = modification.colors.outline
	var duration: String = "RUN" if modification.duration_seconds <= 0.0 else "%ds" % ceili(modification.duration_seconds)
	_detail.text = modification.description + " / " + duration
	_burst.modulate = modification.colors.outline

func _get_configuration_warnings() -> PackedStringArray:
	if healing_amount > 0:
		return [] if healing_colors != null else ["Assign healing colors for a repair pickup."]
	if modification == null or modification.colors == null:
		return ["Assign a WeaponModification with pickup colors."]
	return []

func try_collect(player: PlaygroundPlayer) -> bool:
	if Engine.is_editor_hint() or get_tree().paused or not _available: return false
	if player == null or not player.is_alive: return false
	if healing_amount > 0:
		if player.heal(healing_amount) <= 0: return false
	elif not player.shooter.apply_modifier(modification): return false
	$PickupSound.trigger()
	_available = false
	set_deferred("monitoring", false)
	_visual.hide()
	_burst.restart()
	_burst.emitting = true
	_timer.start(respawn_seconds)
	return true

func _on_body_entered(body: Node2D) -> void:
	var player: PlaygroundPlayer = body as PlaygroundPlayer
	if player != null: try_collect(player)

func _on_respawn_timeout() -> void:
	$RechargeSound.trigger()
	_available = true
	_refresh_preview()
	_visual.show()
	set_deferred("monitoring", true)
