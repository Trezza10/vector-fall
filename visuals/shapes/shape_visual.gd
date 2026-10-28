@tool
class_name ShapeVisual
extends Node2D

@export var definition: ShapeDefinition:
	set(value):
		_unwatch(definition)
		definition = value
		_refresh()
@export var colors: ShapeColors:
	set(value):
		_unwatch(colors)
		colors = value
		_refresh()

func _ready() -> void:
	_refresh()

func _exit_tree() -> void:
	_unwatch(definition)
	_unwatch(colors)

func configure(new_definition: ShapeDefinition, new_colors: ShapeColors) -> void:
	definition = new_definition
	colors = new_colors

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if definition == null: warnings.append("Assign a ShapeDefinition to render geometry.")
	if colors == null: warnings.append("Assign ShapeColors to render this shape.")
	return warnings

func _refresh() -> void:
	if not is_inside_tree(): return
	_watch(definition)
	_watch(colors)
	update_configuration_warnings()
	queue_redraw()

func _watch(resource: Resource) -> void:
	if resource != null and not resource.changed.is_connected(_refresh):
		resource.changed.connect(_refresh)

func _unwatch(resource: Resource) -> void:
	if resource != null and resource.changed.is_connected(_refresh):
		resource.changed.disconnect(_refresh)

func _draw() -> void:
	if definition == null or colors == null: return
	match definition.geometry:
		ShapeDefinition.Geometry.CIRCLE: _draw_circle_shape()
		ShapeDefinition.Geometry.TRIANGLE: _draw_triangle_shape()
		ShapeDefinition.Geometry.SQUARE: _draw_square_shape()
		ShapeDefinition.Geometry.HEXAGON: _draw_hexagon_shape()
		ShapeDefinition.Geometry.DIAMOND: _draw_polygon_shape(_regular_vertices(4, -PI / 2.0))
		ShapeDefinition.Geometry.PENTAGON: _draw_polygon_shape(_regular_vertices(5, -PI / 2.0))
		ShapeDefinition.Geometry.OCTAGON: _draw_polygon_shape(_regular_vertices(8, -PI / 8.0))
		ShapeDefinition.Geometry.STAR: _draw_star_shape()
		ShapeDefinition.Geometry.CROSS: _draw_cross_shape()

func _draw_circle_shape() -> void:
	var radius: float = definition.radius
	draw_circle(Vector2.ZERO, radius, colors.fill)
	if definition.outline_width > 0.0:
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 96, colors.outline,
			definition.outline_width, true)
	if definition.detail_style == ShapeDefinition.DetailStyle.NONE: return
	var inner: float = radius * definition.inner_scale
	if inner <= 0.0: return
	draw_arc(Vector2.ZERO, inner, 0.0, TAU, 96, colors.detail, 1.0, true)
	if definition.detail_style == ShapeDefinition.DetailStyle.RING:
		draw_arc(Vector2.ZERO, inner * 0.78, 0.0, TAU, 96, colors.detail, 1.0, true)
	draw_arc(Vector2.ZERO, inner, -PI * 0.75, -PI * 0.25, 24,
		colors.highlight, 1.5, true)

func _draw_triangle_shape() -> void:
	_draw_polygon_shape(_regular_vertices(3, -PI / 2.0))

func _draw_square_shape() -> void:
	_draw_polygon_shape(_regular_vertices(4, -PI / 4.0))

func _draw_hexagon_shape() -> void:
	_draw_polygon_shape(_regular_vertices(6, -PI / 2.0))

func _regular_vertices(count: int, start_angle: float) -> PackedVector2Array:
	var vertices: PackedVector2Array = []
	for index: int in range(count):
		var angle: float = start_angle + TAU * float(index) / float(count)
		vertices.append(Vector2.from_angle(angle) * definition.radius)
	return vertices

func _draw_star_shape() -> void:
	var vertices: PackedVector2Array = []
	for index: int in range(10):
		var radius: float = definition.radius * (1.0 if index % 2 == 0 else 0.48)
		vertices.append(Vector2.from_angle(-PI / 2.0 + TAU * index / 10.0) * radius)
	_draw_polygon_shape(vertices)

func _draw_cross_shape() -> void:
	var vertices: PackedVector2Array = []
	var corners: PackedVector2Array = PackedVector2Array([
		Vector2(-0.32, -1), Vector2(0.32, -1), Vector2(0.32, -0.32),
		Vector2(1, -0.32), Vector2(1, 0.32), Vector2(0.32, 0.32),
		Vector2(0.32, 1), Vector2(-0.32, 1), Vector2(-0.32, 0.32),
		Vector2(-1, 0.32), Vector2(-1, -0.32), Vector2(-0.32, -0.32)])
	for corner: Vector2 in corners: vertices.append(corner * definition.radius)
	_draw_polygon_shape(vertices)

func _draw_polygon_shape(vertices: PackedVector2Array) -> void:
	draw_colored_polygon(vertices, colors.fill)
	var closed: PackedVector2Array = vertices.duplicate()
	closed.append(vertices[0])
	if definition.outline_width > 0.0:
		draw_polyline(closed, colors.outline, definition.outline_width, true)
	if definition.detail_style == ShapeDefinition.DetailStyle.NONE: return
	if definition.inner_scale <= 0.0: return
	var inset: PackedVector2Array = []
	for vertex: Vector2 in closed:
		inset.append(vertex * definition.inner_scale)
	draw_polyline(inset, colors.detail, 1.0, true)
	if definition.detail_style == ShapeDefinition.DetailStyle.RING:
		var inner: PackedVector2Array = []
		for vertex: Vector2 in inset: inner.append(vertex * 0.78)
		draw_polyline(inner, colors.detail, 1.0, true)
	draw_line(inset[0], inset[1], colors.highlight, 1.5, true)
