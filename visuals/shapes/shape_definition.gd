@tool
class_name ShapeDefinition
extends Resource

enum Geometry { CIRCLE, TRIANGLE, SQUARE, HEXAGON, DIAMOND, PENTAGON, OCTAGON, STAR, CROSS }
enum DetailStyle { NONE, INSET, RING }

@export var display_name: String = "Shape":
	set(value):
		display_name = value
		emit_changed()
@export var geometry: Geometry = Geometry.CIRCLE:
	set(value):
		geometry = value
		emit_changed()
@export_range(1.0, 200.0, 0.5) var radius: float = 44.0:
	set(value):
		radius = maxf(value, 0.1)
		emit_changed()
@export_range(0.0, 12.0, 0.5) var outline_width: float = 2.0:
	set(value):
		outline_width = maxf(value, 0.0)
		emit_changed()
@export_range(0.0, 1.0, 0.01) var inner_scale: float = 0.65:
	set(value):
		inner_scale = clampf(value, 0.0, 1.0)
		emit_changed()
@export var detail_style: DetailStyle = DetailStyle.INSET:
	set(value):
		detail_style = value
		emit_changed()
