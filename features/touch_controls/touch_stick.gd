class_name TouchStick
extends Control

signal changed(value: Vector2)
signal dash_requested
@export_range(0.1, 0.5, 0.01) var retouch_dash_window: float = 0.28
@export_range(0.1, 1.0, 0.05) var dash_direction_threshold: float = 0.35
var _released_at: float = -100.0
var _dash_armed: bool = false
@export_range(0.0, 0.5, 0.01) var deadzone: float = 0.12
var enabled: bool = true
var value: Vector2 = Vector2.ZERO
var _finger: int = -1

func _input(event: InputEvent) -> void:
	if not enabled or not is_visible_in_tree(): return
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		if touch.pressed and _finger < 0 and get_global_rect().has_point(touch.position):
			_dash_armed = Time.get_ticks_msec() / 1000.0 - _released_at <= retouch_dash_window
			_finger = touch.index
			_update(touch.position)
			get_viewport().set_input_as_handled()
		elif not touch.pressed and touch.index == _finger:
			reset_stick()
			if not touch.canceled: _released_at = Time.get_ticks_msec() / 1000.0
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and (event as InputEventScreenDrag).index == _finger:
		_update((event as InputEventScreenDrag).position)
		get_viewport().set_input_as_handled()

func _update(at: Vector2) -> void:
	var offset: Vector2 = (at - get_global_rect().get_center()) / (size.x * 0.35)
	value = offset.limit_length()
	if value.length() < deadzone: value = Vector2.ZERO
	$Thumb.position = size * 0.5 - $Thumb.size * 0.5 + value * size.x * 0.35
	changed.emit(value)
	if _dash_armed and value.length() >= dash_direction_threshold:
		_dash_armed = false
		dash_requested.emit()

func reset_stick() -> void:
	_released_at = -100.0
	_dash_armed = false
	_finger = -1
	value = Vector2.ZERO
	$Thumb.position = size * 0.5 - $Thumb.size * 0.5
	changed.emit(value)
