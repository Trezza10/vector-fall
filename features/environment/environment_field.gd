extends Node2D
func reset_environment() -> void:
	for child: Node in get_children():
		if child is EnvironmentalObstacle: child.reset_obstacle()
