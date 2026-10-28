@tool
extends Node2D

@export var palette: PaletteDefinition:
	set(value):
		palette = value
		_apply_palette()

@onready var _grid: GridBackground = $Stage/GridBackground
@onready var _gallery: Node2D = $Stage/Gallery

func _ready() -> void:
	_apply_palette()

func _apply_palette() -> void:
	if not is_node_ready(): return
	_grid.palette = palette
	# Only direct, authored preview instances are coordinated here.
	for preview: Node in _gallery.get_children():
		var shape_preview: ShapePreview = preview as ShapePreview
		if shape_preview != null and not shape_preview.palette_override:
			shape_preview.apply_palette(palette)
