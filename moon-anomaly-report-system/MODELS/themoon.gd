# MoonSpin.gd — attach to THEMOON node
extends Node3D

@export var spin_speed: float = 1.5

func _process(delta: float) -> void:
	# Only spin when player is seated at the console
	#if not GameState.is_seated:
		#return

	var input_dir := Vector2.ZERO

	if Input.is_action_pressed("moon_left"):   # A
		input_dir.x -= 1.0
	if Input.is_action_pressed("moon_right"):  # D
		input_dir.x += 1.0
	if Input.is_action_pressed("moon_up"):     # W
		input_dir.y -= 1.0
	if Input.is_action_pressed("moon_down"):   # S
		input_dir.y += 1.0

	rotate_y(input_dir.x * spin_speed * delta)
	rotate_x(input_dir.y * spin_speed * delta)
