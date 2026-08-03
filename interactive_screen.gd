extends StaticBody3D
class_name InteractiveScreen

## A short tag like "desktop", "panel", "info" — set this in the Inspector.
## ScreenManager uses it to know which SubViewport belongs to this screen.
@export var screen_id: String = ""

@export var mesh_instance: MeshInstance3D
@export var flip_x: bool = false

var viewport: SubViewport = null

@onready var _col_shape: CollisionShape3D = _find_collision_shape()

func _ready() -> void:
	add_to_group("interactive_screens")
	# Don't apply texture yet — viewport isn't assigned until ScreenManager
	# wires it up after the whole scene tree is instanced.
	print("Mesh instance path: ", mesh_instance.get_path())
	print("Local AABB size: ", mesh_instance.get_aabb().size)
	print("Local scale: ", mesh_instance.scale)
	print("Global scale: ", mesh_instance.global_transform.basis.get_scale())
	print("Global AABB (world units): ",
		mesh_instance.global_transform.basis.get_scale() * mesh_instance.get_aabb().size)

## Called by ScreenManager once the SubViewport exists and is reachable.
func assign_viewport(vp: SubViewport) -> void:
	viewport = vp
	_apply_texture()

func _apply_texture() -> void:
	if viewport == null or mesh_instance == null:
		push_warning("InteractiveScreen (%s): missing viewport or mesh_instance." % name)
		return
	var mat := StandardMaterial3D.new()
	mat.transparency               = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.render_priority             = 1
	mat.texture_filter              = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.albedo_texture               = viewport.get_texture()
	mat.shading_mode                = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled             = true
	mat.emission_texture             = viewport.get_texture()
	mat.emission_energy_multiplier   = 1.5
	mesh_instance.set_surface_override_material(0, mat)

func world_to_viewport_pos(world_pos: Vector3) -> Vector2:
	var local: Vector3    = _col_shape.global_transform.affine_inverse() * world_pos
	var box:   BoxShape3D = _col_shape.shape as BoxShape3D
	if box == null:
		return Vector2.ZERO
	var uv_x := (local.z + box.size.z * 0.5) / box.size.z
	if flip_x:
		uv_x = 1.0 - uv_x
	var uv_y := 1.0 - (local.y + box.size.y * 0.5) / box.size.y
	uv_x = clamp(uv_x, 0.0, 1.0)
	uv_y = clamp(uv_y, 0.0, 1.0)
	return Vector2(uv_x, uv_y) * Vector2(viewport.size)

func world_to_viewport_pos_from_ray(ray_origin: Vector3, ray_dir: Vector3) -> Vector2:
	var normal: Vector3 = _col_shape.global_transform.basis.x.normalized()
	var plane := Plane(normal, _col_shape.global_transform.origin)
	var hit = plane.intersects_ray(ray_origin, ray_dir)
	if hit == null:
		return Vector2(-1, -1)
	return world_to_viewport_pos(hit)


func _find_collision_shape() -> CollisionShape3D:
	for child in get_children():
		if child is CollisionShape3D:
			return child
	return null
