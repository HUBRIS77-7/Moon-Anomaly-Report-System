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
# INSPECTOR EXPORTS (assign in the editor):
#   camera          → SubViewportContainer/SubViewport/Camera3D
#   terminal_manager→ SubViewportContainer/SubViewport/TerminalStuff/TerminalManager
#
# INPUT MAP (Project Settings → Input Map):
#   toggle_seat  → Tab key
#   (WASD/moon_* actions already exist and are reused for walking)
#
# ── STANDING UP ────────────────────────────────────────────────────────────
# Before actually standing, the player is first routed through
# TerminalManager's designated "exit anchor" (see TerminalManager.gd,
# exit_anchor_index / get_exit_anchor_index()). This guarantees the stand-up
# spawn position is always computed relative to that one safe anchor
# (e.g. CameraAnchor4 / ExitView) no matter which terminal camera the player
# was browsing beforehand — so they never stand up into desk geometry that
# only some of the anchors are safe to view from.

extends CharacterBody3D

# ── Exports ───────────────────────────────────────────────────────────────────
@export var camera: Camera3D
@export var terminal_manager: Node

@export var move_speed: float       = 2.2
@export var mouse_sensitivity: float = 0.0018   # radians per pixel
@export var gravity_strength: float  = 12.0
@export var eye_height: float        = 0.52     # camera Y offset from body centre

# ── Initial spawn ─────────────────────────────────────────────────────────────
## If true, the player starts seated at a terminal (old behaviour: position is
## derived from the camera). If false, the player spawns standing at
## spawn_position instead, and TerminalManager is told to stand down so it
## doesn't fight for control of the camera before the player ever sits.
@export var start_seated: bool = false
@export var spawn_position: Vector3 = Vector3(-36.55, 1.196, -46.92)
@export var spawn_yaw_degrees: float = 0.0

# ── Constants ─────────────────────────────────────────────────────────────────
const PITCH_MIN_DEG := -75.0
const PITCH_MAX_DEG :=  75.0

# How far in front of the terminal anchor the player spawns when standing up.
const STAND_OFFSET := 0.7

# ── State ─────────────────────────────────────────────────────────────────────
var _seated: bool = true

# Guards against a second Tab press re-triggering _stand_up() while the
# travel-to-exit-anchor tween from a previous press is still in flight.
var _standing_up: bool = false

# Camera orientation tracked independently so we can drive it directly.
var _yaw:   float = 0.0   # radians, horizontal
var _pitch: float = 0.0   # radians, vertical

# A tween used for the sit-down camera return journey.
var _sit_tween: Tween = null

# ── Ready ─────────────────────────────────────────────────────────────────────
func _ready() -> void:
	floor_snap_length = 0.1
	wall_min_slide_angle = deg_to_rad(15)  # helps slide past thin edges
	FootstepManager.register_player(self)
	if start_seated:
		_seated = true
		GameState.is_seated = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		if camera:
			var cam := camera.global_position
			global_position = Vector3(cam.x, cam.y - eye_height, cam.z + STAND_OFFSET)
		return

	# ── Spawn standing at spawn_position ──────────────────────────────────────
	_seated = false
	GameState.is_seated = false
	global_position = spawn_position
	velocity = Vector3.ZERO

	# Wait a frame so TerminalManager finishes its own _ready() first (it
	# snaps the camera to anchors[0] on ready) — otherwise it can stomp on
	# the camera placement we're about to do here.
	await get_tree().process_frame

	if terminal_manager and terminal_manager.has_method("pause_control"):
		terminal_manager.pause_control()

	_yaw   = deg_to_rad(spawn_yaw_degrees)
	_pitch = 0.0

	if camera:
		camera.global_position = global_position + Vector3(0.0, eye_height, 0.0)
		_apply_camera_rotation()

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
# ── Input ─────────────────────────────────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	# Toggle seat / standing.
	if event.is_action_pressed("toggle_seat"):
		if _seated:
			if not _standing_up:
				_stand_up()
		else:
			_sit_down()
		get_viewport().set_input_as_handled()
		return

	# Mouse look — only when standing.
	if not _seated and event is InputEventMouseMotion:
		_yaw   -= event.relative.x * mouse_sensitivity
		_pitch -= event.relative.y * mouse_sensitivity
		_pitch  = clamp(
			_pitch,
			deg_to_rad(PITCH_MIN_DEG),
			deg_to_rad(PITCH_MAX_DEG)
		)
		_apply_camera_rotation()
		get_viewport().set_input_as_handled()

# ── Physics ───────────────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	if _seated:
		return

	FootstepManager.update(delta, global_position, velocity, _seated)

	# ── Gravity ───────────────────────────────────────────────────────────────
	if not is_on_floor():
		velocity.y -= gravity_strength * delta
	else:
		velocity.y = 0.0

	# ── Horizontal movement ───────────────────────────────────────────────────
	var input_dir := Vector2.ZERO
	if Input.is_action_pressed("moon_up"):    input_dir.y -= 1.0
	if Input.is_action_pressed("moon_down"):  input_dir.y += 1.0
	if Input.is_action_pressed("moon_left"):  input_dir.x -= 1.0
	if Input.is_action_pressed("moon_right"): input_dir.x += 1.0

	if input_dir.length_squared() > 0.001:
		input_dir = input_dir.normalized()

	# Walk in the direction the camera is facing (horizontal plane only).
	var cam_basis := camera.global_transform.basis
	var forward   := -cam_basis.z;  forward.y = 0.0
	var right     :=  cam_basis.x;  right.y   = 0.0

	if forward.length_squared() > 0.001: forward = forward.normalized()
	if right.length_squared()   > 0.001: right   = right.normalized()

	var move_dir: Vector3 = (forward * -input_dir.y) + (right * input_dir.x)
	velocity.x = move_dir.x * move_speed
	velocity.z = move_dir.z * move_speed

	move_and_slide()

	# Keep camera glued to the player's head position.
	if camera:
		camera.global_position = global_position + Vector3(0.0, eye_height, 0.0)

# ── Stand / Sit ───────────────────────────────────────────────────────────────
func _stand_up() -> void:
	_standing_up = true

	# Cancel any in-progress sit-down tween.
	if _sit_tween and _sit_tween.is_running():
		_sit_tween.kill()
		_sit_tween = null

	# Always travel to the designated exit anchor first, regardless of which
	# terminal camera the player was last browsing. If already there,
	# go_to_index() returns immediately with no travel performed.
	if terminal_manager and terminal_manager.has_method("go_to_index") \
			and terminal_manager.has_method("get_exit_anchor_index"):
		var exit_idx: int = terminal_manager.get_exit_anchor_index()
		await terminal_manager.go_to_index(exit_idx)

	# Stop TerminalManager from tweening the camera.
	if terminal_manager and terminal_manager.has_method("pause_control"):
		terminal_manager.pause_control()

	# Compute a safe spawn position: just in front of the current camera.
	# By this point the camera is guaranteed to be at the exit anchor.
	var cam_pos := camera.global_position
	var cam_fwd := -camera.global_transform.basis.z
	cam_fwd.y   = 0.0
	if cam_fwd.length_squared() > 0.001:
		cam_fwd = cam_fwd.normalized()
	else:
		cam_fwd = Vector3.FORWARD

	# Body centre sits eye_height below the camera.
	global_position = Vector3(
		cam_pos.x + cam_fwd.x * STAND_OFFSET,
		cam_pos.y - eye_height,
		cam_pos.z + cam_fwd.z * STAND_OFFSET
	)

	# Sync the look angles from wherever the camera currently points.
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

	# Ask TerminalManager to smoothly tween back to the current anchor.
	# Note: current_index was left pointing at the exit anchor by _stand_up(),
	# so sitting back down returns to that same exit anchor rather than
	# whichever anchor the player was on before standing.
	if terminal_manager and terminal_manager.has_method("resume_control"):
		terminal_manager.resume_control(camera)

# ── Helpers ───────────────────────────────────────────────────────────────────
func _apply_camera_rotation() -> void:
	if camera == null:
		return
	# Build the basis from yaw then pitch so there's no roll.
	var basis := Basis.IDENTITY
	basis = basis.rotated(Vector3.UP, _yaw)
	basis = basis.rotated(basis.x, _pitch)
	camera.global_transform.basis = basis
