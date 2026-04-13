# MODELS/themoon.gd
extends Node3D

@export var spin_speed: float = 1.0
@export var surface_radius: float = 32.0
@export var icon_scale: float = 50.0
@export var icon_collision_radius: float = 2.5

var _body_to_call_id: Dictionary = {}

func _ready() -> void:
	add_icon(1, Vector3( 0.0,  1.0,  0.0))
	add_icon(2, Vector3( 1.0,  0.2,  0.0))
	add_icon(3, Vector3(-0.6,  0.5,  0.6))
	add_icon(4, Vector3( 0.3, -0.3, -0.9))

func _process(delta: float) -> void:
	var yaw   := 0.0
	var pitch := 0.0
	if Input.is_action_pressed("moon_left"):
		yaw += spin_speed * delta
	if Input.is_action_pressed("moon_right"):
		yaw -= spin_speed * delta
	if Input.is_action_pressed("moon_up"):
		pitch += spin_speed * delta
	if Input.is_action_pressed("moon_down"):
		pitch -= spin_speed * delta
	if yaw != 0.0:
		rotate_y(yaw)
	if pitch != 0.0:
		rotate_object_local(Vector3.RIGHT, pitch)

# ── Public API ───────────────────────────────────────────────────────────────

func add_icon(call_id: int, direction: Vector3) -> void:
	direction = direction.normalized()

	var icon: Node3D = preload("res://MoonIcon.tscn").instantiate()
	add_child(icon)
	icon.position = direction * surface_radius

	# In Godot, a node's forward face is its -Z axis.
	# We want the front face pointing outward (away from moon centre),
	# so the local +Z axis must point INWARD (toward moon centre = -direction).
	var z_axis := -direction

	# Project world UP onto the tangent plane of the sphere at this point,
	# so the icon stands as upright as possible. Fall back to FORWARD if at a pole.
	var y_axis := Vector3.UP - Vector3.UP.dot(direction) * direction
	if y_axis.length_squared() < 0.0001:
		y_axis = Vector3.FORWARD - Vector3.FORWARD.dot(direction) * direction
	y_axis = y_axis.normalized()

	var x_axis := y_axis.cross(z_axis).normalized()

	# Apply scale directly into the basis so it isn't overwritten later
	icon.transform.basis = Basis(
		x_axis * icon_scale,
		y_axis * icon_scale,
		z_axis * icon_scale
	)

	# Collision body on layer 4
	var body := StaticBody3D.new()
	body.collision_layer = 4
	body.collision_mask  = 0
	icon.add_child(body)
	var col    := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = icon_collision_radius
	col.shape = sphere
	body.add_child(col)

	_body_to_call_id[body] = call_id

func remove_icon(call_id: int) -> void:
	for body: StaticBody3D in _body_to_call_id.keys():
		if _body_to_call_id[body] == call_id:
			_body_to_call_id.erase(body)
			if is_instance_valid(body) and is_instance_valid(body.get_parent()):
				body.get_parent().queue_free()
			return

func get_call_id_for_body(body: Object) -> int:
	return _body_to_call_id.get(body, -1)
