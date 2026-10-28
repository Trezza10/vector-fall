class_name PlaygroundTouchControls
extends CanvasLayer

signal reset_requested
@export var force_show: bool = false
@onready var _move: TouchStick = $MoveStick
var _player: PlaygroundPlayer
var _menu: PlaygroundPauseMenu
var _enabled: bool = false
var _was_paused: bool = false

func configure(player: PlaygroundPlayer, menu: PlaygroundPauseMenu) -> void:
	_player = player
	_menu = menu
	_move.changed.connect(_on_move)
	_move.dash_requested.connect(_on_dash)
	$Pause.pressed.connect(_on_pause)
	$Reset.pressed.connect(_on_reset)
	player.reset_performed.connect(_clear_sticks)
	_enabled = force_show or OS.get_cmdline_user_args().has("--touch-controls") or DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")
	_player.touch_input_enabled = _enabled
	visible = _enabled

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and not _enabled and _player != null:
		_enabled = true
		_player.touch_input_enabled = true
		show()

func _process(_delta: float) -> void:
	if _player == null: return
	var paused: bool = get_tree().paused
	if paused and not _was_paused: _clear_sticks()
	_was_paused = paused
	visible = _enabled and not paused
	_move.enabled = not paused
	var viewport: Vector2 = get_viewport().get_visible_rect().size
	$Pause.position = Vector2(viewport.x - 162, 24)
	$Reset.position = Vector2(viewport.x - 162, 130)

func _on_move(value: Vector2) -> void:
	if _player != null:
		_player.touch_move = value
		_player.touch_aim = value
		if not value.is_zero_approx(): _player.shooting_direction()

func _on_dash() -> void:
	if _player != null and not get_tree().paused: _player.try_dash()

func _on_pause() -> void:
	if _menu != null: _menu.set_paused(not get_tree().paused)

func _on_reset() -> void:
	if not get_tree().paused: reset_requested.emit()

func _clear_sticks() -> void:
	_move.reset_stick()
