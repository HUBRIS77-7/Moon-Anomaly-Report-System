# Lamp.gd
# Attach to the root "Lamp" node.
# Player presses E (action "interact") while standing nearby to toggle the light.

extends Node3D

@export var light: OmniLight3D
@export var interact_area: Area3D

@export var on_energy: float = 1.5
@export var off_energy: float = 0.0

var _is_on: bool = true
var _player_in_range: bool = false

func _ready() -> void:
	if light == null:
		light = get_node_or_null("Light/OmniLight3D")
	if interact_area == null:
		interact_area = get_node_or_null("InteractArea")

	if interact_area:
		interact_area.body_entered.connect(_on_body_entered)
		interact_area.body_exited.connect(_on_body_exited)
	else:
		push_warning("Lamp.gd: no InteractArea found — lamp cannot be toggled.")

	_apply_state()

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		_player_in_range = true

func _on_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D:
		_player_in_range = false

func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range or GameState.is_seated:
		return
	if event.is_action_pressed("interact"):
		toggle()
		get_viewport().set_input_as_handled()

func toggle() -> void:
	_is_on = not _is_on
	_apply_state()

func _apply_state() -> void:
	if light:
		light.visible = _is_on
		light.light_energy = on_energy if _is_on else off_energy
