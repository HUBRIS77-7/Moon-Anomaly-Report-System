# PrimaryRoomEntryTrigger.gd
# Attach to an Area3D placed across the PrimaryRoom doorway/threshold.
# Fires LUNA's day-1 intro dialog the moment the player physically walks in.

extends Area3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		DialogManager.trigger_day1_intro()
