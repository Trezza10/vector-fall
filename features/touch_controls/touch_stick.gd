class_name TouchStick
extends Control

signal changed(value: Vector2)
@export_range(0.0, 0.5, 0.01) var deadzone: float = 0.12
var enabled: bool = true
var value: Vector2 = Vector2.ZERO
var _finger: int = -1

func _input(event: InputEvent) -> void:
	if not enabled or not is_visible_in_tree(): return
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		if touch.pressed and _finger < 0 and get_global_rect().has_point(touch.position):
			_finger = touch.index
			_update(touch.position)
			get_viewport().set_input_as_handled()
		elif not touch.pressed and touch.index == _finger:
			reset_stick()
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

func reset_stick() -> void:
	_finger = -1
	value = Vector2.ZERO
	$Thumb.position = size * 0.5 - $Thumb.size * 0.5
	changed.emit(value)
