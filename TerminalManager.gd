extends Node

@export var travel_time: float = 0.8

# Drag your Camera3D directly into this slot in the Inspector
@export var camera: Camera3D

@export var anchors: Array[Marker3D] = []

var current_index: int = 0
var is_traveling: bool = false

func _ready() -> void:
	if camera == null:
		push_error("TerminalManager: No camera assigned!")
		return
	if anchors.size() == 0:
		push_error("TerminalManager: No anchors assigned!")
		return
	camera.global_position = anchors[0].global_position
	camera.global_rotation = anchors[0].global_rotation

func _unhandled_input(event: InputEvent) -> void:
	if is_traveling:
		return
	if event.is_action_pressed("terminal_left"):
		switch_terminal(-1)
	elif event.is_action_pressed("terminal_right"):
		switch_terminal(1)

func switch_terminal(direction: int) -> void:
	if anchors.size() == 0:
		return
	var next_index = clamp(current_index + direction, 0, anchors.size() - 1)
	if next_index == current_index:
		return
	current_index = next_index
	await travel_to(anchors[current_index])

func travel_to(anchor: Marker3D) -> void:
	is_traveling = true
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(camera, "global_position", anchor.global_position, travel_time)
	tween.tween_method(
		func(t: float): camera.quaternion = camera.quaternion.slerp(anchor.quaternion, t),
		0.0, 1.0, travel_time
	)
	await tween.finished
	is_traveling = false

func go_to_index(index: int) -> void:
	if is_traveling or index == current_index:
		return
	if index < 0 or index >= anchors.size():
		return
	current_index = index
	await travel_to(anchors[current_index])
