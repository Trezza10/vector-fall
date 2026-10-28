class_name TargetDummy
extends CharacterBody2D

signal damage_received(amount: int, remaining_hp: int)
signal died
signal respawned

@export_range(1, 1000000000, 1) var max_hp: int = 1000000
@export var die_at_zero: bool = false
@export var respawn_on_death: bool = false
@export_range(0.1, 30.0, 0.1) var respawn_delay: float = 5.0
@export var display_label: String = "TRAINING TARGET"

@onready var _visual: ShapeVisual = $ShapeVisual
@onready var _bar: DamageHealthBar = $HealthBar
@onready var _label: Label = $Label
@onready var _respawn_timer: Timer = $RespawnTimer
@onready var _death_particles: CPUParticles2D = $DeathParticles
@onready var statuses: TargetStatus = $TargetStatus
@onready var _damage_numbers: TargetDamageNumbers = $DamageNumbers

var _current_hp: int = 1000000
var _dead: bool = false
var _feedback_tween: Tween
var _push_velocity: Vector2 = Vector2.ZERO
var _spawn_position: Vector2

var is_alive: bool:
	get: return not _dead

var current_hp: int:
	get: return _current_hp

func _ready() -> void:
	_spawn_position = global_position
	statuses.damage_tick.connect(_on_status_damage)
	statuses.knockback_requested.connect(_on_knockback_requested)
	statuses.state_changed.connect(_on_status_changed)
	_respawn_timer.timeout.connect(_on_respawn_timeout)
	reset_health()
	set_process(false)

func _physics_process(delta: float) -> void:
	if _dead or _push_velocity.length_squared() < 1.0:
		_push_velocity = Vector2.ZERO
		velocity = Vector2.ZERO
		return
	var decay: float = exp(-12.0 * delta)
	velocity = _push_velocity * (1.0 - decay) / (12.0 * delta)
	_push_velocity *= decay
	if move_and_slide(): _push_velocity = Vector2.ZERO

func apply_status(effect: StatusEffectDefinition, direction: Vector2) -> void:
	if not _dead and not get_tree().paused:
		if effect != null and not statuses.has_effect(effect.kind): $StatusSound.trigger()
		statuses.apply_effect(effect, direction)

func _on_status_damage(burn_amount: int, poison_amount: int) -> void:
	if get_tree().paused or _dead: return
	var total: int = burn_amount + poison_amount
	if total <= 0: return
	# Preserve the existing combined-tick rounding and HP clamp while attributing sources.
	var applied: int = mini(ceili(total * statuses.damage_multiplier), _current_hp)
	var burn_share: int = clampi(roundi(float(applied) * burn_amount / total), 0, applied)
	_commit_damage(burn_share, DamageSource.Kind.BURN)
	_commit_damage(applied - burn_share, DamageSource.Kind.POISON)

func _on_knockback_requested(offset: Vector2) -> void:
	_push_velocity = (_push_velocity + offset * 12.0).limit_length(1200.0)

func _on_status_changed() -> void:
	var hit_material: ShaderMaterial = _visual.material as ShaderMaterial
	hit_material.set_shader_parameter("status_tint", statuses.tint)
	hit_material.set_shader_parameter("status_strength", 0.0 if statuses.tint == Color.WHITE else 0.32)

func _process(_delta: float) -> void:
	_label.text = "REBOOT / %.1fs" % _respawn_timer.time_left

func apply_damage(amount: int, source: DamageSource.Kind = DamageSource.Kind.BULLET) -> int:
	if get_tree().paused or _dead or amount <= 0: return 0
	var applied_damage: int = mini(ceili(amount * statuses.damage_multiplier), _current_hp)
	return _commit_damage(applied_damage, source)

func _commit_damage(applied_damage: int, source: DamageSource.Kind) -> int:
	if applied_damage == 0: return 0
	match source:
		DamageSource.Kind.BURN: $BurnSound.trigger()
		DamageSource.Kind.POISON: $PoisonSound.trigger()
		DamageSource.Kind.CRITICAL: $CritSound.trigger()
		_: $HitSound.trigger()
	_current_hp -= applied_damage
	_bar.set_health(_current_hp, max_hp)
	_play_hit_feedback()
	_damage_numbers.show_damage(applied_damage, global_position, source)
	damage_received.emit(applied_damage, _current_hp)
	if _current_hp == 0 and (die_at_zero or respawn_on_death): _die()
	return applied_damage

func reset_health() -> void:
	_damage_numbers.reset_numbers()
	statuses.clear_effects()
	_push_velocity = Vector2.ZERO
	velocity = Vector2.ZERO
	_dead = false
	_respawn_timer.stop()
	set_process(false)
	_current_hp = max_hp
	if _feedback_tween != null: _feedback_tween.kill()
	_set_flash(0.0)
	_visual.scale = Vector2.ONE
	_visual.show()
	_bar.show()
	_bar.set_health(_current_hp, max_hp, false)
	_label.text = display_label
	set_deferred("collision_layer", 2)

func _play_hit_feedback() -> void:
	if _feedback_tween != null: _feedback_tween.kill()
	_visual.scale = Vector2(1.07, 0.94)
	_set_flash(0.85)
	_feedback_tween = create_tween().set_parallel(true)
	_feedback_tween.tween_method(_set_flash, 0.85, 0.0, 0.16)
	_feedback_tween.tween_property(_visual, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _set_flash(value: float) -> void:
	var hit_material: ShaderMaterial = _visual.material as ShaderMaterial
	hit_material.set_shader_parameter("flash", value)

func _die() -> void:
	$KillSound.trigger()
	_dead = true
	statuses.clear_effects()
	_push_velocity = Vector2.ZERO
	set_deferred("collision_layer", 0)
	_visual.hide()
	_bar.hide()
	_death_particles.restart()
	_death_particles.emitting = true
	if respawn_on_death:
		_respawn_timer.start(respawn_delay)
		set_process(true)
	else:
		_label.text = "DESTROYED"
		set_process(false)
	died.emit()

func _on_respawn_timeout() -> void:
	$RespawnSound.trigger()
	global_position = _spawn_position
	reset_physics_interpolation()
	reset_health()
	_visual.scale = Vector2(0.7, 0.7)
	_feedback_tween = create_tween()
	_feedback_tween.tween_property(_visual, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	respawned.emit()
