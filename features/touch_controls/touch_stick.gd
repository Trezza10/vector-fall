class_name TouchStick
extends Control

signal changed(value: Vector2)
@export_range(0.0, 0.5, 0.01) var deadzone: float = 0.12
@export_range(60.0, 200.0, 5.0) var radius: float = 140.0
@export var excluded_buttons: Array[NodePath] = []
var enabled: bool = true
var value: Vector2 = Vector2.ZERO
var _finger: int = -1
var _origin: Vector2 = Vector2.ZERO

func _ready() -> void:
	reset_stick()

func _input(event: InputEvent) -> void:
	if not enabled or not is_visible_in_tree(): return
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		if touch.pressed and _finger < 0 and can_start_at(touch.position):
			_finger = touch.index
			_origin = touch.position
			$Base.position = _origin - Vector2.ONE * radius
			$Base.show()
			$Thumb.show()
			_update(touch.position)
			get_viewport().set_input_as_handled()
		elif not touch.pressed and touch.index == _finger:
			reset_stick()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and (event as InputEventScreenDrag).index == _finger:
		_update((event as InputEventScreenDrag).position)
		get_viewport().set_input_as_handled()

func can_start_at(at: Vector2) -> bool:
	if not get_global_rect().has_point(at): return false
	for path: NodePath in excluded_buttons:
		var button: TouchScreenButton = get_node(path) as TouchScreenButton
		if button.is_visible_in_tree() and Rect2(button.global_position, button.texture_normal.get_size()).has_point(at):
			return false
	return true

func _update(at: Vector2) -> void:
	value = ((at - _origin) / (radius * 0.7)).limit_length()
	if value.length() < deadzone: value = Vector2.ZERO
	$Thumb.position = _origin - $Thumb.size * 0.5 + value * radius * 0.7
	changed.emit(value)

func reset_stick() -> void:
	_finger = -1
	value = Vector2.ZERO
	$Base.hide()
	$Thumb.hide()
	changed.emit(value)
