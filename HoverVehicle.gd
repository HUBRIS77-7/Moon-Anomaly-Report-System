# HoverVehicle.gd
extends CharacterBody3D
class_name HoverVehicle

# ── Hover ─────────────────────────────────────────────────────────────────
@export var ride_height: float = 1.0
@export var hover_ray_length: float = 4.0
@export var hover_response: float = 10.0   # higher = snaps to height faster
@export var hover_collision_mask: int = 1
@export var fall_gravity: float = 12.0     # used only when no ground is found

# ── Driving ───────────────────────────────────────────────────────────────
@export var thrust_accel: float = 14.0
@export var brake_decel: float = 20.0
@export var max_speed: float = 14.0
@export var turn_speed_deg: float = 70.0   # degrees/sec, scales down at low speed

# ── Camera / seating ────────────────────────────────────────────────────────
@export var camera_seat: Node3D
@export var exit_offset: Vector3 = Vector3(1.8, 0.5, 0.0)

var is_piloted: bool = false
var _camera: Camera3D = null
var _forward_speed: float = 0.0   # signed speed along -Z (facing dir)

func _physics_process(delta: float) -> void:
	_apply_hover(delta)
	if is_piloted:
		_apply_controls(delta)
		_update_camera()
	else:
		_forward_speed = move_toward(_forward_speed, 0.0, brake_decel * delta)
		var fwd := -global_transform.basis.z
		velocity.x = fwd.x * _forward_speed
		velocity.z = fwd.z * _forward_speed
	move_and_slide()

func start_piloting(camera: Camera3D) -> void:
	is_piloted = true
	_camera = camera

func stop_piloting() -> void:
	is_piloted = false
	_camera = null

func get_exit_position() -> Vector3:
	return global_transform * exit_offset

func _update_camera() -> void:
	if _camera == null:
		return
	_camera.global_transform = camera_seat.global_transform if camera_seat else global_transform

## Single downward ray under the vehicle's center. Sets velocity.y so the
## vehicle eases toward ride_height above whatever's below it — no springs,
## no per-corner forces, just a height-correction velocity each frame.
func _apply_hover(delta: float) -> void:
	var space := get_world_3d().direct_space_state
	var origin := global_position
	var query := PhysicsRayQueryParameters3D.create(origin, origin + Vector3.DOWN * hover_ray_length)
	query.exclude = [get_rid()]
	query.collision_mask = hover_collision_mask
	var result := space.intersect_ray(query)

	if result.is_empty():
		velocity.y -= fall_gravity * delta
		return

	var target_y: float = result["position"].y + ride_height
	var diff: float = target_y - global_position.y
	velocity.y = diff * hover_response

func _apply_controls(delta: float) -> void:
	var input_dir := Vector2.ZERO
	if Input.is_action_pressed("moon_up"):    input_dir.y -= 1.0
	if Input.is_action_pressed("moon_down"):  input_dir.y += 1.0
	if Input.is_action_pressed("moon_left"):  input_dir.x -= 1.0
	if Input.is_action_pressed("moon_right"): input_dir.x += 1.0

	# Turning — scale by how fast you're going so it doesn't spin in place
	# at full rate when stopped (feels more like a vehicle, less like a top).
	var turn_scale: float = clampf(absf(_forward_speed) / max_speed, 0.25, 1.0)
	rotate_y(-input_dir.x * deg_to_rad(turn_speed_deg) * turn_scale * delta)

	var target_speed: float = -input_dir.y * max_speed
	var accel: float = thrust_accel if absf(target_speed) > 0.01 else brake_decel
	_forward_speed = move_toward(_forward_speed, target_speed, accel * delta)

	var fwd := -global_transform.basis.z
	velocity.x = fwd.x * _forward_speed
	velocity.z = fwd.z * _forward_speed
