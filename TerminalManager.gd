# TerminalManager.gd
# Manages camera travel between terminal anchor points.
# Now supports pause_control / resume_control so PlayerController
# can borrow the camera while the player is walking around.
#
# Also drives a small "edge-look" effect: while seated at a terminal, moving
# the mouse toward the edges of the window gently pans the camera off the
# anchor's base rotation. Purely cosmetic — it never changes current_index or
# which anchor the game thinks you're looking at, and it stays disabled
# during travel tweens and while standing (gated by the same _input_enabled
# flag PlayerController's pause_control/resume_control already use).

extends Node

@export var travel_time: float = 0.8

@export var camera: Camera3D
@export var anchors: Array[Marker3D] = []

var current_index: int = 0
var is_traveling: bool = false

# Set to false by PlayerController when the player stands up.
var _input_enabled: bool = true

# Active tween — kept so we can cancel it.
var _active_tween: Tween = null

# ── Seated edge-look ──────────────────────────────────────────────────────────
@export var edge_look_enabled: bool = true
@export var edge_look_max_yaw_deg: float = 12.0
@export var edge_look_max_pitch_deg: float = 8.0
@export var edge_look_deadzone: float = 0.15   # fraction of half-screen before any pan starts
@export var edge_look_smoothing: float = 6.0   # higher = snappier response

var _edge_look_offset: Quaternion = Quaternion.IDENTITY

# ── Ready ─────────────────────────────────────────────────────────────────────
func _ready() -> void:
	if camera == null:
		push_error("TerminalManager: No camera assigned!")
		return
	if anchors.size() == 0:
		push_error("TerminalManager: No anchors assigned!")
		return
	camera.global_position = anchors[0].global_position
	camera.global_rotation = anchors[0].global_rotation

# ── Per-frame edge-look ────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if not edge_look_enabled or not _input_enabled or is_traveling or anchors.is_empty():
		return
	if not GameState.is_seated:
		return

	var target_offset: Quaternion = _compute_edge_look_offset()
	var t: float = clampf(edge_look_smoothing * delta, 0.0, 1.0)
	_edge_look_offset = _edge_look_offset.slerp(target_offset, t)

	var anchor: Marker3D = anchors[current_index]
	camera.quaternion = anchor.quaternion * _edge_look_offset

func _compute_edge_look_offset() -> Quaternion:
	# get_tree().root is the actual Window/root Viewport — using it (rather
	# than this node's get_viewport(), which is the nested SubViewport)
	# gives mouse coordinates that correctly account for the project's
	# viewport stretch/aspect settings.
	var root_vp: Viewport = get_tree().root
	var window_size: Vector2 = root_vp.get_visible_rect().size
	if window_size.x <= 0.0 or window_size.y <= 0.0:
		return Quaternion.IDENTITY

	var mouse_pos: Vector2 = root_vp.get_mouse_position()
	var centered: Vector2 = (mouse_pos / window_size) * 2.0 - Vector2.ONE  # -1..1 each axis

	var dx: float = _apply_deadzone(centered.x)
	var dy: float = _apply_deadzone(centered.y)

	var yaw: float   = -dx * deg_to_rad(edge_look_max_yaw_deg)
	var pitch: float = -dy * deg_to_rad(edge_look_max_pitch_deg)

	return Quaternion(Vector3.UP, yaw) * Quaternion(Vector3.RIGHT, pitch)

func _apply_deadzone(v: float) -> float:
	var sign_v: float = sign(v)
	var mag: float = clampf(abs(v), 0.0, 1.0)
	if mag < edge_look_deadzone:
		return 0.0
	return sign_v * (mag - edge_look_deadzone) / (1.0 - edge_look_deadzone)

# ── Input ─────────────────────────────────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if not _input_enabled or is_traveling:
		return
	if event.is_action_pressed("terminal_left"):
		switch_terminal(-1)
	elif event.is_action_pressed("terminal_right"):
		switch_terminal(1)

# ── Terminal switching ─────────────────────────────────────────────────────────
func switch_terminal(direction: int) -> void:
	if anchors.size() == 0:
		return
	var next_index: int = clampi(current_index + direction, 0, anchors.size() - 1)
	if next_index == current_index:
		return
	current_index = next_index
	await travel_to(anchors[current_index])

func travel_to(anchor: Marker3D) -> void:
	_cancel_tween()
	is_traveling = true
	_edge_look_offset = Quaternion.IDENTITY

	_active_tween = create_tween()
	_active_tween.set_parallel(true)
	_active_tween.set_ease(Tween.EASE_IN_OUT)
	_active_tween.set_trans(Tween.TRANS_CUBIC)
	_active_tween.tween_property(camera, "global_position", anchor.global_position, travel_time)
	_active_tween.tween_method(
		func(t: float) -> void:
			camera.quaternion = camera.quaternion.slerp(anchor.quaternion, t),
		0.0, 1.0, travel_time
	)
	await _active_tween.finished
	is_traveling = false
	_active_tween = null

func go_to_index(index: int) -> void:
	if is_traveling or index == current_index:
		return
	if index < 0 or index >= anchors.size():
		return
	current_index = index
	await travel_to(anchors[current_index])

# ── PlayerController integration ──────────────────────────────────────────────

## Called by PlayerController when the player stands up.
## Cancels any active camera tween so the camera is free to be driven manually.
func pause_control() -> void:
	_cancel_tween()
	_input_enabled = false
	_edge_look_offset = Quaternion.IDENTITY

## Called by PlayerController when the player sits back down.
## Smoothly returns the camera to the current anchor, then re-enables input.
func resume_control(cam: Camera3D) -> void:
	_input_enabled = false   # keep blocked while returning
	if anchors.is_empty():
		_input_enabled = true
		return

	var anchor := anchors[current_index]

	_cancel_tween()
	is_traveling = true

	_active_tween = create_tween()
	_active_tween.set_parallel(true)
	_active_tween.set_ease(Tween.EASE_IN_OUT)
	_active_tween.set_trans(Tween.TRANS_CUBIC)
	_active_tween.tween_property(cam, "global_position", anchor.global_position, 0.55)
	_active_tween.tween_method(
		func(t: float) -> void:
			cam.quaternion = cam.quaternion.slerp(anchor.quaternion, t),
		0.0, 1.0, 0.55
	)
	await _active_tween.finished
	is_traveling = false
	_active_tween = null
	_edge_look_offset = Quaternion.IDENTITY
	_input_enabled = true

# ── Internal ──────────────────────────────────────────────────────────────────
func _cancel_tween() -> void:
	if _active_tween and _active_tween.is_running():
		_active_tween.kill()
	_active_tween = null
	is_traveling = false
