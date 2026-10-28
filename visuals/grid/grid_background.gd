@tool
class_name GridBackground
extends Node2D

@export var size: Vector2 = Vector2(1440, 900):
	set(value):
		size = value
		queue_redraw()
@export_range(8.0, 128.0, 1.0) var spacing: float = 32.0:
	set(value):
		spacing = maxf(value, 8.0)
		queue_redraw()
@export var palette: PaletteDefinition:
	set(value):
		if palette != null and palette.changed.is_connected(queue_redraw):
			palette.changed.disconnect(queue_redraw)
		palette = value
		if is_inside_tree(): _watch_palette()
		queue_redraw()

func _ready() -> void:
	_watch_palette()

func _exit_tree() -> void:
	if palette != null and palette.changed.is_connected(queue_redraw):
		palette.changed.disconnect(queue_redraw)

func _watch_palette() -> void:
	if palette != null and not palette.changed.is_connected(queue_redraw):
		palette.changed.connect(queue_redraw)
	update_configuration_warnings()

func _get_configuration_warnings() -> PackedStringArray:
	if palette == null: return ["Assign a PaletteDefinition for background and grid colors."]
	return []

func _draw() -> void:
	if palette == null: return
	draw_rect(Rect2(Vector2.ZERO, size), palette.background)
	for column: int in range(int(size.x / spacing) + 1):
		var x: float = column * spacing
		draw_line(Vector2(x, 0), Vector2(x, size.y), palette.grid, 1.0)
	for row: int in range(int(size.y / spacing) + 1):
		var y: float = row * spacing
		draw_line(Vector2(0, y), Vector2(size.x, y), palette.grid, 1.0)
