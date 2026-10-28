@tool
class_name PaletteDefinition
extends Resource

enum ColorRole { PLAYER, ENEMY_COMMON, ENEMY_FAST, ENEMY_HEAVY }

@export var background: Color = Color("0b141b"):
	set(value):
		background = value
		emit_changed()
@export var grid: Color = Color("182b34"):
	set(value):
		grid = value
		emit_changed()
@export var player: ShapeColors:
	set(value):
		player = value
		emit_changed()
@export var enemy_common: ShapeColors:
	set(value):
		enemy_common = value
		emit_changed()
@export var enemy_fast: ShapeColors:
	set(value):
		enemy_fast = value
		emit_changed()
@export var enemy_heavy: ShapeColors:
	set(value):
		enemy_heavy = value
		emit_changed()

func colors_for(role: ColorRole) -> ShapeColors:
	match role:
		ColorRole.PLAYER: return player
		ColorRole.ENEMY_COMMON: return enemy_common
		ColorRole.ENEMY_FAST: return enemy_fast
		ColorRole.ENEMY_HEAVY: return enemy_heavy
	return null
