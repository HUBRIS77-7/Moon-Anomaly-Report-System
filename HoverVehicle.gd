# HoverVehicle.gd
extends RigidBody3D
class_name HoverVehicle

@export var hover_points: Array[Node3D] = []
@export var ride_height: float = 1.0
@export var spring_strength: float = 80.0
@export var spring_damping: float = 8.0
@export var hover_ray_length: float = 2.5
@export var hover_collision_mask: int = 1

@export var thrust_force: float = 18.0
@export var turn_torque: float = 6.0
@export var max_speed: float = 14.0
@export var lateral_damping: float = 4.0

## Drag a Marker3D positioned where the driver's head should be into this
## slot. The camera snaps to its transform every frame while piloted.
@export var camera_seat: Node3D

## Local-space offset from the vehicle origin where the player is dropped
## when they exit (so they don't spawn inside the hull).
@export var exit_offset: Vector3 = Vector3(1.8, 0.5, 0.0)

var is_piloted: bool = false
var _camera: Camera3D = null

func _ready() -> void:
	can_sleep = false
	print("hover_points count: ", hover_points.size())
	for p in hover_points:
		print("  point: ", p)
	print("mass=", mass, " gravity_scale=", gravity_scale, " freeze=", freeze)

func _physics_process(delta: float) -> void:
	_apply_hover_forces()
	if is_piloted:
		_apply_controls(delta)
		_update_camera()

## Called by PlayerController when the player interacts with this vehicle's
## DriverSeatZone.
func start_piloting(camera: Camera3D) -> void:
	is_piloted = true
	_camera = camera

func stop_piloting() -> void:
	is_piloted = false
	_camera = null

## World-space position to place the player at on exit.
func get_exit_position() -> Vector3:
	return global_transform * exit_offset

func _update_camera() -> void:
	if _camera == null:
		return
	if camera_seat != null:
		_camera.global_transform = camera_seat.global_transform
	else:
		_camera.global_transform = global_transform

func _apply_hover_forces() -> void:
	var space := get_world_3d().direct_space_state
	for point in hover_points:
		var origin: Vector3 = point.global_position
		var ray_end: Vector3 = origin + Vector3.DOWN * hover_ray_length
		var query := PhysicsRayQueryParameters3D.create(origin, ray_end)
		query.collision_mask = hover_collision_mask
		query.exclude = [self.get_rid()]
		var result := space.intersect_ray(query)
		print("hover check | origin=", origin, " hit=", not result.is_empty(), " result=", result)
		if result.is_empty():
			continue

		var hit_dist: float = origin.distance_to(result["position"])
		var compression: float = ride_height - hit_dist
		print("  hit_dist=", hit_dist, " compression=", compression)
		if compression <= 0.0:
			continue

		var normal: Vector3 = result["normal"]
		var point_velocity: Vector3 = linear_velocity + angular_velocity.cross(origin - global_position)
		var damping_force: float = point_velocity.dot(normal) * spring_damping
		var force_mag: float = (compression * spring_strength) - damping_force
		print("  applying force_mag=", force_mag)
		apply_force(normal * maxf(force_mag, 0.0), origin - global_position)

func _apply_controls(delta: float) -> void:
	var input_dir := Vector2.ZERO
	if Input.is_action_pressed("moon_up"):    input_dir.y -= 1.0
	if Input.is_action_pressed("moon_down"):  input_dir.y += 1.0
	if Input.is_action_pressed("moon_left"):  input_dir.x -= 1.0
	if Input.is_action_pressed("moon_right"): input_dir.x += 1.0

	print("piloting input: ", input_dir, " sleeping: ", sleeping, " lin_vel: ", linear_velocity)


	var forward: Vector3 = -global_transform.basis.z
	if linear_velocity.length() < max_speed:
		apply_central_force(forward * -input_dir.y * thrust_force)

	apply_torque(Vector3.UP * -input_dir.x * turn_torque)

	var right: Vector3 = global_transform.basis.x
	var lateral_speed: float = linear_velocity.dot(right)
	apply_central_force(-right * lateral_speed * lateral_damping)
