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

extends CharacterBody3D

# ── Exports ───────────────────────────────────────────────────────────────────
@export var camera: Camera3D
@export var terminal_manager: Node

@export var move_speed: float       = 2.2
@export var mouse_sensitivity: float = 0.0018   # radians per pixel
@export var gravity_strength: float  = 12.0
@export var eye_height: float        = 0.52     # camera Y offset from body centre

# ── Constants ─────────────────────────────────────────────────────────────────
const PITCH_MIN_DEG := -75.0
const PITCH_MAX_DEG :=  75.0

# How far in front of the terminal anchor the player spawns when standing up.
const STAND_OFFSET := 0.7

# ── State ─────────────────────────────────────────────────────────────────────
var _seated: bool = true

# Camera orientation tracked independently so we can drive it directly.
var _yaw:   float = 0.0   # radians, horizontal
var _pitch: float = 0.0   # radians, vertical

# A tween used for the sit-down camera return journey.
var _sit_tween: Tween = null

# ── Ready ─────────────────────────────────────────────────────────────────────
func _ready() -> void:
	floor_snap_length = 0.1
	wall_min_slide_angle = deg_to_rad(15)  # helps slide past thin edges
	# Player starts seated; TerminalManager owns the camera.
	_seated = true
	GameState.is_seated = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Park the CharacterBody3D somewhere reasonable so it doesn't fall through.
	# We'll teleport it properly when the player actually stands up.
	if camera:
		var cam := camera.global_position
		global_position = Vector3(cam.x, cam.y - eye_height, cam.z + STAND_OFFSET)

# ── Input ─────────────────────────────────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	# Toggle seat / standing.
	if event.is_action_pressed("toggle_seat"):
		if _seated:
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
	# Cancel any in-progress sit-down tween.
	if _sit_tween and _sit_tween.is_running():
		_sit_tween.kill()
		_sit_tween = null

	# Stop TerminalManager from tweening the camera.
	if terminal_manager and terminal_manager.has_method("pause_control"):
		terminal_manager.pause_control()

	# Compute a safe spawn position: just in front of the current camera.
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

func _sit_down() -> void:
	_seated = true
	GameState.is_seated = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Ask TerminalManager to smoothly tween back to the current anchor.
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
