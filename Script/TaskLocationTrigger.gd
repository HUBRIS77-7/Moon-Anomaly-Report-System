# TaskLocationTrigger.gd
# Attach to an Area3D anywhere the player walking in should complete a task.
# collision_layer = 0, collision_mask = whatever layer the player's
# CharacterBody3D sits on (1, per the rest of the project).

extends Area3D

@export var task_id: String = ""

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if task_id == "":
		push_warning("TaskLocationTrigger on '%s' has no task_id set." % name)
		return
	if body is CharacterBody3D:
		GameState.complete_task(task_id)
