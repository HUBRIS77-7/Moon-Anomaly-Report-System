# HoverVehicle.gd
extends RigidBody3D

@export var hover_points: Array[Node3D] = []   # 4 empty Node3D markers at the corners
@export var ride_height: float = 1.0
@export var spring_strength: float = 80.0
@export var spring_damping: float = 8.0
@export var hover_ray_length: float = 2.5
@export var hover_collision_mask: int = 1      # match your floor/terrain layer

@export var thrust_force: float = 18.0
@export var turn_torque: float = 6.0
@export var max_speed: float = 14.0
@export var lateral_damping: float = 4.0       # kills sideways drift, tune down for "driftier" feel

var _is_piloted: bool = false

func _physics_process(delta: float) -> void:
	_apply_hover_forces()
	if _is_piloted:
		_apply_controls(delta)

func _apply_hover_forces() -> void:
	var space := get_world_3d().direct_space_state
	for point in hover_points:
		var origin: Vector3 = point.global_position
		var query := PhysicsRayQueryParameters3D.create(
			origin, origin + Vector3.DOWN * hover_ray_length
		)
		query.collision_mask = hover_collision_mask
		query.exclude = [self]
		var result := space.intersect_ray(query)
		if result.is_empty():
			continue

		var hit_dist: float = origin.distance_to(result["position"])
		var compression: float = ride_height - hit_dist
		if compression <= 0.0:
			continue

		var normal: Vector3 = result["normal"]
		var point_velocity: Vector3 = linear_velocity + angular_velocity.cross(origin - global_position)
		var damping_force: float = point_velocity.dot(normal) * spring_damping
		var force_mag: float = (compression * spring_strength) - damping_force
		apply_force(normal * maxf(force_mag, 0.0), origin - global_position)

func _apply_controls(delta: float) -> void:
	var input_dir := Vector2.ZERO
	if Input.is_action_pressed("moon_up"):    input_dir.y -= 1.0
	if Input.is_action_pressed("moon_down"):  input_dir.y += 1.0
	if Input.is_action_pressed("moon_left"):  input_dir.x -= 1.0
	if Input.is_action_pressed("moon_right"): input_dir.x += 1.0

	var forward: Vector3 = -global_transform.basis.z
	if linear_velocity.length() < max_speed:
		apply_central_force(forward * -input_dir.y * thrust_force)

	apply_torque(Vector3.UP * -input_dir.x * turn_torque)

	# Kill sideways slide so it feels like driving, not skating
	var right: Vector3 = global_transform.basis.x
	var lateral_speed: float = linear_velocity.dot(right)
	apply_central_force(-right * lateral_speed * lateral_damping)
