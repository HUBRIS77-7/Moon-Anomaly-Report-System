# PlayerController.gd
# First-person walking controller.
#
# SCENE SETUP (inside SubViewportContainer/SubViewport):
#   Add a CharacterBody3D node named "Player"
#     collision_layer = 1, collision_mask = 1
#     Attach this script to it.
#     Add a CollisionShape3D child:
#       Shape: CapsuleShape3D  radius=0.3  height=1.0
#
# ── SEAT ZONES ──────────────────────────────────────────────────────────────
# Pressing [Tab] to sit down no longer teleports you to a fixed
# `terminal_manager` from anywhere in the level. Instead, drop a SeatZone
# Area3D (see SeatZone.gd) around each desk, and assign that zone's
# `terminal_manager` to the TerminalManager that owns that desk's camera
# anchors. The player tracks which SeatZone(s) they're currently standing
# in; pressing Tab only sits down if you're inside at least one, and it
# seats you at whichever zone's TerminalManager (the most recently entered
# one, if more than one overlaps). Standing up with no zones nearby is
# always allowed as before.
#
# ── VEHICLE PILOTING ──────────────────────────────────────────────────────
# Pressing [E] ("interact") while standing inside a VehicleEntryZone
# (dropped around a vehicle's driver seat, pointing at a HoverVehicle)
# hands camera + input control over to that vehicle. Pressing [E] again
# while piloting exits: the player's body is hidden/disabled while piloted
# and restored at the vehicle's exit_offset on exit. This runs in parallel
# with the SeatZone/terminal system — they don't interact with each other,
# but both are blocked while the other is active.
#
# INSPECTOR EXPORTS (assign in the editor):
#   camera            → SubViewportContainer/SubViewport/Camera3D
#   terminal_manager  → optional fallback/default TerminalManager, used only
#                       if start_seated is true (spawning already seated).
#                       Ignored once the player is standing — from then on
#                       the active SeatZone decides which TerminalManager
#                       to use.
#
# INPUT MAP (Project Settings → Input Map):
#   toggle_seat  → Tab key
#   interact     → E key
#   (WASD/moon_* actions already exist and are reused for walking)
#
# ── STANDING UP ────────────────────────────────────────────────────────────
# Before actually standing, the player is first routed through the ACTIVE
# TerminalManager's designated "exit anchor" (see TerminalManager.gd,
# exit_anchor_index / get_exit_anchor_index()). This guarantees the stand-up
# spawn position is always computed relative to that one safe anchor
# no matter which terminal camera the player was browsing beforehand.

extends CharacterBody3D

# ── Exports ───────────────────────────────────────────────────────────────────
@export var camera: Camera3D
@export var terminal_manager: Node   # default/fallback only — see note above

@export var move_speed: float       = 2.2
@export var mouse_sensitivity: float = 0.0018   # radians per pixel
@export var gravity_strength: float  = 12.0
@export var eye_height: float        = 0.52     # camera Y offset from body centre

# ── Initial spawn ─────────────────────────────────────────────────────────────
@export var start_seated: bool = false
@export var spawn_position: Vector3 = Vector3(-19.35, 0.839, -73.80)
#Vector3(-36.55, 1.196, -46.92)
@export var spawn_yaw_degrees: float = 0.0

# ── Constants ─────────────────────────────────────────────────────────────────
const PITCH_MIN_DEG := -75.0
const PITCH_MAX_DEG :=  75.0
const STAND_OFFSET := 0.7

# ── State ─────────────────────────────────────────────────────────────────────
var _seated: bool = true
var _standing_up: bool = false

var _yaw:   float = 0.0
var _pitch: float = 0.0

var _sit_tween: Tween = null

# Stack of SeatZones the player is currently physically standing inside.
# Most-recently-entered zone wins if more than one overlaps (e.g. two desk
# clusters placed close together).
var _nearby_seat_zones: Array[SeatZone] = []

# Stack of VehicleEntryZones the player is currently physically standing
# inside. Same "most-recently-entered wins" rule as seat zones.
var _nearby_vehicle_zones: Array[VehicleEntryZone] = []

# Non-null while the player is piloting a HoverVehicle — movement/mouse-look
# and physics are handed off to the vehicle while this is set.
var _piloted_vehicle: HoverVehicle = null

# ── Ready ─────────────────────────────────────────────────────────────────────
func _ready() -> void:
	floor_snap_length = 0.1
	wall_min_slide_angle = deg_to_rad(15)
	FootstepManager.register_player(self)
	if start_seated:
		_seated = true
		GameState.is_seated = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		if camera:
			var cam := camera.global_position
			global_position = Vector3(cam.x, cam.y - eye_height, cam.z + STAND_OFFSET)
		return

	_seated = false
	GameState.is_seated = false
	global_position = spawn_position
	velocity = Vector3.ZERO

	await get_tree().process_frame

	if terminal_manager and terminal_manager.has_method("pause_control"):
		terminal_manager.pause_control()

	_yaw   = deg_to_rad(spawn_yaw_degrees)
	_pitch = 0.0

	if camera:
		camera.global_position = global_position + Vector3(0.0, eye_height, 0.0)
		_apply_camera_rotation()

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# ── Seat zone tracking (called by SeatZone.gd) ────────────────────────────────
func _on_seat_zone_entered(zone: SeatZone) -> void:
	if not _nearby_seat_zones.has(zone):
		_nearby_seat_zones.append(zone)

func _on_seat_zone_exited(zone: SeatZone) -> void:
	_nearby_seat_zones.erase(zone)

# ── Vehicle zone tracking (called by VehicleEntryZone.gd) ─────────────────────
func _on_vehicle_zone_entered(zone: VehicleEntryZone) -> void:
	if not _nearby_vehicle_zones.has(zone):
		_nearby_vehicle_zones.append(zone)

func _on_vehicle_zone_exited(zone: VehicleEntryZone) -> void:
	_nearby_vehicle_zones.erase(zone)

# ── Input ─────────────────────────────────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_seat"):
		if _piloted_vehicle != null:
			# Don't let Tab do anything weird while driving.
			get_viewport().set_input_as_handled()
			return
		if _seated:
			if not _standing_up:
				_stand_up()
		else:
			_try_sit_down()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("interact"):
		if _piloted_vehicle != null:
			_exit_vehicle()
			get_viewport().set_input_as_handled()
		elif not _seated and not _nearby_vehicle_zones.is_empty():
			_enter_vehicle(_nearby_vehicle_zones.back().vehicle)
			get_viewport().set_input_as_handled()
		return

	if not _seated and _piloted_vehicle == null and event is InputEventMouseMotion:
		_yaw   -= event.relative.x * mouse_sensitivity
		_pitch -= event.relative.y * mouse_sensitivity
		_pitch  = clamp(_pitch, deg_to_rad(PITCH_MIN_DEG), deg_to_rad(PITCH_MAX_DEG))
		_apply_camera_rotation()
		get_viewport().set_input_as_handled()

func _try_sit_down() -> void:
	if _nearby_seat_zones.is_empty():
		# Not standing near any desk — Tab does nothing.
		return
	var zone: SeatZone = _nearby_seat_zones.back()
	if zone.terminal_manager == null:
		push_warning("SeatZone '%s' has no terminal_manager assigned." % zone.name)
		return
	terminal_manager = zone.terminal_manager
	_sit_down()

# ── Physics ───────────────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	if _seated or _piloted_vehicle != null:
		return

	FootstepManager.update(delta, global_position, velocity, _seated)

	if not is_on_floor():
		velocity.y -= gravity_strength * delta
	else:
		velocity.y = 0.0

	var input_dir := Vector2.ZERO
	if Input.is_action_pressed("moon_up"):    input_dir.y -= 1.0
	if Input.is_action_pressed("moon_down"):  input_dir.y += 1.0
	if Input.is_action_pressed("moon_left"):  input_dir.x -= 1.0
	if Input.is_action_pressed("moon_right"): input_dir.x += 1.0

	if input_dir.length_squared() > 0.001:
		input_dir = input_dir.normalized()

	var cam_basis := camera.global_transform.basis
	var forward   := -cam_basis.z;  forward.y = 0.0
	var right     :=  cam_basis.x;  right.y   = 0.0

	if forward.length_squared() > 0.001: forward = forward.normalized()
	if right.length_squared()   > 0.001: right   = right.normalized()

	var move_dir: Vector3 = (forward * -input_dir.y) + (right * input_dir.x)
	velocity.x = move_dir.x * move_speed
	velocity.z = move_dir.z * move_speed

	move_and_slide()

	if camera:
		camera.global_position = global_position + Vector3(0.0, eye_height, 0.0)

# ── Stand / Sit ───────────────────────────────────────────────────────────────
func _stand_up() -> void:
	_standing_up = true

	if _sit_tween and _sit_tween.is_running():
		_sit_tween.kill()
		_sit_tween = null

	if terminal_manager and terminal_manager.has_method("go_to_index") \
			and terminal_manager.has_method("get_exit_anchor_index"):
		var exit_idx: int = terminal_manager.get_exit_anchor_index()
		await terminal_manager.go_to_index(exit_idx)

	if terminal_manager and terminal_manager.has_method("pause_control"):
		terminal_manager.pause_control()

	var cam_pos := camera.global_position
	var cam_fwd := -camera.global_transform.basis.z
	cam_fwd.y   = 0.0
	if cam_fwd.length_squared() > 0.001:
		cam_fwd = cam_fwd.normalized()
	else:
		cam_fwd = Vector3.FORWARD

	global_position = Vector3(
		cam_pos.x + cam_fwd.x * STAND_OFFSET,
		cam_pos.y - eye_height,
		cam_pos.z + cam_fwd.z * STAND_OFFSET
	)

	var euler := camera.global_transform.basis.get_euler(EULER_ORDER_YXZ)
	_yaw   = euler.y
	_pitch = clamp(euler.x, deg_to_rad(PITCH_MIN_DEG), deg_to_rad(PITCH_MAX_DEG))

	velocity = Vector3.ZERO
	_seated = false
	GameState.is_seated = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_standing_up = false

func _sit_down() -> void:
	_seated = true
	GameState.is_seated = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if terminal_manager and terminal_manager.has_method("resume_control"):
		terminal_manager.resume_control(camera)

# ── Vehicle enter / exit ───────────────────────────────────────────────────────
func _enter_vehicle(vehicle: HoverVehicle) -> void:
	if vehicle == null:
		return
	_piloted_vehicle = vehicle
	visible = false
	collision_layer = 0
	velocity = Vector3.ZERO
	vehicle.start_piloting(camera)

func _exit_vehicle() -> void:
	if _piloted_vehicle == null:
		return
	var exit_pos: Vector3 = _piloted_vehicle.get_exit_position()
	_piloted_vehicle.stop_piloting()
	_piloted_vehicle = null
	visible = true
	collision_layer = 1
	global_position = exit_pos
	velocity = Vector3.ZERO
	camera.global_position = global_position + Vector3(0.0, eye_height, 0.0)
	_apply_camera_rotation()

# ── Helpers ───────────────────────────────────────────────────────────────────
func _apply_camera_rotation() -> void:
	if camera == null:
		return
	var basis := Basis.IDENTITY
	basis = basis.rotated(Vector3.UP, _yaw)
	basis = basis.rotated(basis.x, _pitch)
	camera.global_transform.basis = basis
