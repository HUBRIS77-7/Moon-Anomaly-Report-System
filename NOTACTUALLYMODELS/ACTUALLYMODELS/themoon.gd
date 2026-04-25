# NOTACTUALLYMODELS/ACTUALLYMODELS/themoon.gd
extends Node3D

@export var spin_speed: float = 1.0
@export var surface_radius: float = 32.0
@export var icon_scale: float = 50.0
@export var icon_collision_radius: float = 6.0
@export var icon_hover: float = 0.0

## How "directly" the camera must face an icon to show the full version.
## 0.90 ≈ within ~26°.  Increase toward 1.0 for a tighter cone.
@export var look_dot_threshold: float = 0.90

## Assign in the Inspector, OR leave null to auto-find "../../Camera3D".
@export var camera: Camera3D

# body → call_id
var _body_to_call_id: Dictionary = {}
# body → { "full": Node3D, "mini": Node3D }
var _body_to_icons: Dictionary = {}

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	await get_tree().process_frame

	# Auto-find the camera if it wasn't assigned in the Inspector.
	if camera == null:
		camera = get_node_or_null("../../Camera3D")

	# Spawn icons from CallDatabase — only entries with an "icon_direction" field.
	for entry in CallDatabase.entries:
		var dir: Vector3 = entry.get("icon_direction", Vector3.ZERO)
		if dir != Vector3.ZERO:
			add_icon(entry["id"], dir)

	print("Moon icon bodies registered: ", _body_to_call_id.size())


func _process(delta: float) -> void:
	# ── Spin controls ─────────────────────────────────────────────────────────
	var yaw   := 0.0
	var pitch := 0.0
	if Input.is_action_pressed("moon_left"):  yaw   += spin_speed * delta
	if Input.is_action_pressed("moon_right"): yaw   -= spin_speed * delta
	if Input.is_action_pressed("moon_up"):    pitch += spin_speed * delta
	if Input.is_action_pressed("moon_down"):  pitch -= spin_speed * delta
	if yaw   != 0.0: rotate_y(yaw)
	if pitch != 0.0: rotate_object_local(Vector3.RIGHT, pitch)

	# ── Icon LOD: full ↔ mini based on camera look direction ──────────────────
	if camera == null:
		return

	var cam_forward := -camera.global_transform.basis.z

	for body in _body_to_icons.keys():
		if not is_instance_valid(body):
			continue
		var icons = _body_to_icons[body]
		var to_icon: Vector3 = body.global_position - camera.global_position
		if to_icon.length_squared() < 0.0001:
			continue
		var looking: bool = cam_forward.dot(to_icon.normalized()) >= look_dot_threshold
		icons["full"].visible = looking
		icons["mini"].visible = not looking


# ── Icon management ───────────────────────────────────────────────────────────

func add_icon(call_id: int, direction: Vector3) -> void:
	direction = direction.normalized()

	var icon: Node3D = preload("res://MoonIcon.tscn").instantiate()
	add_child(icon)

	var world_scale := global_transform.basis.get_scale().x
	var local_hover := icon_hover / world_scale if world_scale > 0.0 else icon_hover

	icon.position = direction * (surface_radius + local_hover)
	icon.scale = Vector3.ONE * icon_scale

	var up_hint := Vector3.UP if abs(direction.dot(Vector3.UP)) < 0.99 else Vector3.FORWARD
	icon.look_at(icon.global_position + direction, up_hint)
	icon.rotate_object_local(Vector3.RIGHT, PI / 2.0)

	_make_icon_transparent(icon)  # ← add this line here
	_set_cull_margin(icon)

	var body := AnimatableBody3D.new()
	body.collision_layer = 4
	body.collision_mask  = 0
	body.sync_to_physics = false
	icon.add_child(body)
	var col    := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = icon_collision_radius
	col.shape = sphere
	body.add_child(col)

	_body_to_call_id[body] = call_id


# Add this new function anywhere in the script
func _make_icon_transparent(node: Node) -> void:
	if node is MeshInstance3D and node.mesh:
		for i in range(node.mesh.get_surface_count()):
			var mat = node.get_active_material(i)
			if mat is BaseMaterial3D:
				var new_mat = mat.duplicate() as BaseMaterial3D
				new_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				new_mat.render_priority = 2
				node.set_surface_override_material(i, new_mat)
	for child in node.get_children():
		_make_icon_transparent(child)


func remove_icon(call_id: int) -> void:
	for body: AnimatableBody3D in _body_to_call_id.keys():
		if _body_to_call_id[body] != call_id:
			continue
		_body_to_call_id.erase(body)
		_body_to_icons.erase(body)
		# body.get_parent() is the root Node3D created in add_icon.
		# Freeing it removes full icon, mini icon, and collision body together.
		if is_instance_valid(body) and is_instance_valid(body.get_parent()):
			body.get_parent().queue_free()
		return


func get_call_id_for_body(body: Object) -> int:
	return _body_to_call_id.get(body, -1)


# ── Helpers ───────────────────────────────────────────────────────────────────

func _set_cull_margin(node: Node) -> void:
	if node is MeshInstance3D:
		node.extra_cull_margin = 16384.0
	for child in node.get_children():
		_set_cull_margin(child)
