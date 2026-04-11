# themoon.gd
extends Node3D

@export var spin_speed: float = 1.5
@export var moon_radius: float = 3.7
@export var icon_scale: float = 0.05

const MoonIconScene = preload("res://MoonIcon.tscn")

# Each entry: { "normal": Vector3, "call_id": int }
# Normal is a point on the unit sphere indicating where on the moon the icon sits
var icon_positions: Array[Dictionary] = [
	{ "normal": Vector3(0, 1, 0),       "call_id": 1 },
	{ "normal": Vector3(1, 0, 0),       "call_id": 2 },
	{ "normal": Vector3(0, 0, 1),       "call_id": 3 },
	{ "normal": Vector3(-1, 0.5, 0.5).normalized(), "call_id": 4 },
]

# Maps StaticBody3D -> call_id for click detection
var _icon_body_map: Dictionary = {}

func _ready() -> void:
	_spawn_icons()

func _process(delta: float) -> void:
	var input_dir := Vector2.ZERO
	if Input.is_action_pressed("moon_left"):
		input_dir.x -= 1.0
	if Input.is_action_pressed("moon_right"):
		input_dir.x += 1.0
	if Input.is_action_pressed("moon_up"):
		input_dir.y -= 1.0
	if Input.is_action_pressed("moon_down"):
		input_dir.y += 1.0
	rotate_y(input_dir.x * spin_speed * delta)
	rotate_x(input_dir.y * spin_speed * delta)

func _spawn_icons() -> void:
	for entry in icon_positions:
		var normal: Vector3 = entry["normal"].normalized()
		var call_id: int = entry["call_id"]

		# Spawn the icon mesh
		var icon = MoonIconScene.instantiate()
		add_child(icon)

		# Position on moon surface
		icon.position = normal * moon_radius
		icon.scale = Vector3.ONE * icon_scale

		# Rotate so icon faces outward from moon center
		icon.look_at(icon.position + normal, Vector3.UP)

		# Add collision for clicking
		var body := StaticBody3D.new()
		body.collision_layer = 4
		body.collision_mask = 0
		icon.add_child(body)

		var col := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = 20.0  # In local units before icon_scale is applied
		col.shape = shape
		body.add_child(col)

		_icon_body_map[body] = call_id

func get_call_id_for_body(body: StaticBody3D) -> int:
	return _icon_body_map.get(body, -1)
