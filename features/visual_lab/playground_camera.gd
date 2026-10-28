extends Camera2D

@export_range(50.0, 2000.0, 10.0) var travel_speed: float = 600.0
@export_range(1.0, 5.0, 0.1) var fast_multiplier: float = 2.0
@export var world_bounds: Rect2 = Rect2(0, 0, 2880, 1800)

var _home: Vector2

func _ready() -> void:
	_home = position

func _process(delta: float) -> void:
	var direction: Vector2 = Vector2(
		float(_pressed(KEY_D, KEY_RIGHT)) - float(_pressed(KEY_A, KEY_LEFT)),
		float(_pressed(KEY_S, KEY_DOWN)) - float(_pressed(KEY_W, KEY_UP)))
	var speed: float = travel_speed
	if Input.is_physical_key_pressed(KEY_SHIFT): speed *= fast_multiplier
	position += direction.normalized() * speed * delta
	# Clamp the camera center using the current viewport, including fullscreen aspect ratios.
	var half_view: Vector2 = get_viewport_rect().size * 0.5 / zoom
	var minimum: Vector2 = world_bounds.position + half_view
	var maximum: Vector2 = (world_bounds.end - half_view).max(minimum)
	position = position.clamp(minimum, maximum)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo(): return
	if event.is_action_pressed("ui_cancel"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	elif event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.physical_keycode == KEY_F11:
			var fullscreen: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fullscreen
				else DisplayServer.WINDOW_MODE_FULLSCREEN)
		elif key_event.physical_keycode == KEY_R:
			position = _home

func _pressed(first: Key, second: Key) -> bool:
	return Input.is_physical_key_pressed(first) or Input.is_physical_key_pressed(second)
