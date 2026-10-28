@tool
class_name ShapeColors
extends Resource

@export var fill: Color = Color("163b40"):
	set(value):
		fill = value
		emit_changed()
@export var outline: Color = Color("68e0ce"):
	set(value):
		outline = value
		emit_changed()
@export var detail: Color = Color("307d79"):
	set(value):
		detail = value
		emit_changed()
@export var highlight: Color = Color("c3fff0"):
	set(value):
		highlight = value
		emit_changed()
