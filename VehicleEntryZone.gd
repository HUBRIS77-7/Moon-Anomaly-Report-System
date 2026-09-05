# VehicleEntryZone.gd
# Attach to an Area3D placed around a vehicle's driver seat.
# collision_layer = 0, collision_mask = 1 (matches the player's
# CharacterBody3D layer) so it only reacts to the player.
#
# Assign `vehicle` to the HoverVehicle (RigidBody3D) this seat belongs to.

extends Area3D
class_name VehicleEntryZone

@export var vehicle: HoverVehicle

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("_on_vehicle_zone_entered"):
		body._on_vehicle_zone_entered(self)

func _on_body_exited(body: Node3D) -> void:
	if body.has_method("_on_vehicle_zone_exited"):
		body._on_vehicle_zone_exited(self)
