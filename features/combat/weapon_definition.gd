class_name WeaponDefinition
extends Resource

@export var display_name: String = "Pulse"
@export_range(0.1, 30.0, 0.1) var attacks_per_second: float = 5.0
@export_range(1, 32, 1) var bullet_count: int = 1
@export_range(0.0, 180.0, 1.0) var spread_degrees: float = 0.0
@export_range(0.0, 60.0, 1.0) var muzzle_distance: float = 26.0
@export var projectile: ProjectileDefinition
@export var projectile_scene: PackedScene

func working_copy() -> WeaponDefinition:
	var copy: WeaponDefinition = duplicate(false) as WeaponDefinition
	if projectile != null: copy.projectile = projectile.working_copy()
	return copy

func spread_angles() -> PackedFloat32Array:
	var angles: PackedFloat32Array = []
	var count: int = clampi(bullet_count, 1, 32)
	for index: int in range(count):
		var fraction: float = 0.5 if count == 1 else float(index) / float(count - 1)
		angles.append(deg_to_rad(spread_degrees) * (fraction - 0.5))
	return angles
