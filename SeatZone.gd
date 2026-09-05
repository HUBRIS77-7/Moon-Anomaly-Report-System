# SeatZone.gd
# Attach to an Area3D placed around a desk/terminal cluster the player
# should be able to sit down at with [Tab].
#
# collision_layer = 0, collision_mask = 1 (matches the player's
# CharacterBody3D layer) so it only reacts to the player.
#
# Assign `terminal_manager` to the TerminalManager node that owns this
# desk's camera anchors. Multiple zones can point at different
# TerminalManagers scattered around the level — PlayerController picks
# whichever zone you're currently standing in when you press Tab.

extends Area3D
class_name SeatZone

@export var terminal_manager: Node

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("_on_seat_zone_entered"):
		body._on_seat_zone_entered(self)

func _on_body_exited(body: Node3D) -> void:
	if body.has_method("_on_seat_zone_exited"):
		body._on_seat_zone_exited(self)
