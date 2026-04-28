# TerminalManager.gd
# Manages camera travel between terminal anchor points.
# Now supports pause_control / resume_control so PlayerController
# can borrow the camera while the player is walking around.

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
	_input_enabled = true

# ── Internal ──────────────────────────────────────────────────────────────────
func _cancel_tween() -> void:
	if _active_tween and _active_tween.is_running():
		_active_tween.kill()
	_active_tween = null
	is_traveling = false
