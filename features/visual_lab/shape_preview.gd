@tool
class_name ShapePreview
extends Node2D

@export var definition: ShapeDefinition:
	set(value):
		definition = value
		_apply()
@export var color_role: PaletteDefinition.ColorRole = PaletteDefinition.ColorRole.PLAYER:
	set(value):
		color_role = value
		_apply()
## Keep this preview's authored palette when the lab's main palette changes.
@export var palette_override: bool = false
@export var palette: PaletteDefinition:
	set(value):
		if palette != null and palette.changed.is_connected(_apply):
			palette.changed.disconnect(_apply)
		palette = value
		_apply()
@export var caption: String = "SHAPE":
	set(value):
		caption = value
		_apply()

@onready var _visual: ShapeVisual = $ShapeVisual
@onready var _label: Label = $NameLabel

func _ready() -> void:
	_apply()

func _exit_tree() -> void:
	if palette != null and palette.changed.is_connected(_apply):
		palette.changed.disconnect(_apply)

func apply_palette(new_palette: PaletteDefinition) -> void:
	palette = new_palette

func _get_configuration_warnings() -> PackedStringArray:
	if definition == null or palette == null:
		return ["Assign a shape definition and palette."]
	if palette.colors_for(color_role) == null:
		return ["The selected palette role needs a ShapeColors resource."]
	return []

func _apply() -> void:
	if not is_node_ready(): return
	if palette != null and not palette.changed.is_connected(_apply):
		palette.changed.connect(_apply)
	_label.text = caption
	var selected_colors: ShapeColors = null
	if palette != null: selected_colors = palette.colors_for(color_role)
	_visual.configure(definition, selected_colors)
	update_configuration_warnings()
