class_name EnemyDefinition
extends Resource

enum Kind { TANK, RUNNER, DASHER, RADIAL, SPIRAL, CHARGER, SPLITTER, MINI, SILENCER }

@export var display_name: String = "Enemy"
@export var kind: Kind = Kind.TANK
@export_range(1, 10000, 1) var health: int = 100
@export_range(0.0, 500.0, 5.0) var move_speed: float = 60.0
@export_range(100.0, 4000.0, 50.0) var acceleration: float = 650.0
@export_range(100.0, 1500.0, 10.0) var activation_radius: float = 560.0
@export_range(100.0, 1500.0, 10.0) var leash_radius: float = 720.0
@export_range(10.0, 100.0, 1.0) var contact_radius: float = 50.0
@export_range(1, 100, 1) var contact_damage: int = 1
@export_group("Burst / Charge")
@export_range(0.1, 10.0, 0.1) var attack_interval: float = 2.0
@export_range(0.1, 2.0, 0.05) var windup_time: float = 0.55
@export_range(100.0, 1500.0, 10.0) var burst_speed: float = 650.0
@export_range(0.1, 1.5, 0.05) var burst_duration: float = 0.3
@export_range(0.1, 3.0, 0.1) var recovery_time: float = 0.55
@export_group("Projectiles")
@export_range(1, 32, 1) var bullet_count: int = 12
@export_range(50.0, 800.0, 10.0) var bullet_speed: float = 190.0
@export_range(0.5, 8.0, 0.1) var bullet_lifetime: float = 4.0
@export_range(1, 100, 1) var bullet_damage: int = 1
@export_range(1.0, 90.0, 1.0) var spiral_step_degrees: float = 19.0

@export_group("Silence pulse")
@export_range(60.0, 600.0, 10.0) var silence_radius: float = 240.0
@export_range(0.2, 6.0, 0.1) var silence_duration: float = 2.5
