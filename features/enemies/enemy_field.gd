extends Node2D

## Fixed encounters are authored in the scene; only their state is reset here.
func reset_encounter() -> void:
	for child: Node in get_children():
		if child is PlaygroundEnemy: (child as PlaygroundEnemy).reset_encounter()
	if has_node("SplitMinis"):
		for child: Node in $SplitMinis.get_children():
			(child as PlaygroundEnemy).deactivate()
