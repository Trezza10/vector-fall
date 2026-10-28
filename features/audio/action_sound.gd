class_name ActionSound
extends AudioStreamPlayer

## Limits repeated cues without timers or runtime player construction.
@export_range(0.0, 1.0, 0.01) var minimum_interval: float = 0.08
@export_range(0.0, 0.3, 0.01) var pitch_variation: float = 0.06
var _cooldown: float = 0.0

func _process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)

func trigger() -> void:
	if not can_process() or _cooldown > 0.0: return
	_cooldown = minimum_interval
	pitch_scale = randf_range(1.0 - pitch_variation, 1.0 + pitch_variation)
	play()
