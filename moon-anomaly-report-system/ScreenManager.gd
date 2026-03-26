# ScreenManager.gd  —  DEBUG VERSION
# Run the game, click on the screen panel, and paste the Output log here.
extends Node

@onready var panel_ui: Control       = $PanelViewport/ScreenPanelUI
@onready var info_ui: Control        = $InfoViewport/ScreenInfoUI
@onready var icon_ui: Control        = $IconViewport/ScreenIconUI
@onready var screen_panel_mesh: MeshInstance3D = get_node("../SubViewport/Props/NEWLSHAPE/ScreenPanel")
@onready var screen_info_mesh:  MeshInstance3D = get_node("../SubViewport/Props/NEWLSHAPE/ScreenInfo")
@onready var screen_icon_mesh:  MeshInstance3D = get_node("../SubViewport/Props/COMPUTER3D2/ScreenIcon")
@onready var camera: Camera3D        = get_node("../SubViewport/Camera3D")

var _screen_map: Array = []

func _ready() -> void:
	print("--- ScreenManager _ready ---")
	print("  panel_ui:        ", panel_ui)
	print("  info_ui:         ", info_ui)
	print("  screen_panel_mesh: ", screen_panel_mesh)
	print("  screen_info_mesh:  ", screen_info_mesh)
	print("  camera:          ", camera)

	$InfoViewport.size  = Vector2i(480, 308)
	$PanelViewport.size = Vector2i(240, 640)
	$IconViewport.size  = Vector2i(256, 256)

	print("  PanelViewport handle_input_locally: ", $PanelViewport.handle_input_locally)
	print("  InfoViewport  handle_input_locally: ", $InfoViewport.handle_input_locally)

	info_ui.connect_to_panel(panel_ui)
	icon_ui.connect_to_panel(panel_ui)
	_apply_viewport_texture(screen_panel_mesh, $PanelViewport, 0)
	_apply_viewport_texture(screen_info_mesh,  $InfoViewport,  0)
	_apply_viewport_texture(screen_icon_mesh,  $IconViewport,  0)
	await get_tree().process_frame
	await get_tree().process_frame
	panel_ui._load_entry(1)
	_register_screen(screen_panel_mesh, $PanelViewport, Vector2(240, 640))
	_register_screen(screen_info_mesh,  $InfoViewport,  Vector2(480, 308))

	print("  _screen_map size after register: ", _screen_map.size())
	for s in _screen_map:
		print("    body=", s["body"], "  col_shape=", s["col_shape"],
			  "  shape=", s["col_shape"].shape if s["col_shape"] else "NULL")

# ── Registration ────────────────────────────────────────────────────────────

func _find_static_body(node: Node) -> StaticBody3D:
	for n in node.get_children():
		if n is StaticBody3D:
			return n
		var r := _find_static_body(n)
		if r:
			return r
	return null

func _find_collision_shape(body: StaticBody3D) -> CollisionShape3D:
	for n in body.get_children():
		if n is CollisionShape3D:
			return n
	return null

func _register_screen(mesh: MeshInstance3D, viewport: SubViewport, size: Vector2) -> void:
	if mesh == null:
		push_error("_register_screen: mesh is null for viewport " + str(viewport))
		return
	var body := _find_static_body(mesh)
	if body == null:
		push_warning("No StaticBody3D under " + mesh.name)
		return
	var col_shape := _find_collision_shape(body)
	if col_shape == null:
		push_warning("No CollisionShape3D under " + body.name)
		return
	_screen_map.append({
		"body":      body,
		"viewport":  viewport,
		"size":      size,
		"col_shape": col_shape,
	})

# ── Input ────────────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	# Only log on a real left-click press to avoid log spam
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return

	print("=== _input LEFT CLICK ===")
	print("  _screen_map.size(): ", _screen_map.size())

	var mouse_pos  := get_viewport().get_mouse_position()
	print("  get_viewport(): ", get_viewport())
	print("  mouse_pos: ", mouse_pos)

	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_end    := ray_origin + camera.project_ray_normal(mouse_pos) * 100.0

	# Try the camera's own world first
	var space := camera.get_world_3d().direct_space_state
	var query  := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collision_mask = 2
	var result := space.intersect_ray(query)
	print("  Raycast (mask=2, camera world): ", result)

	# Try with all layers in case collision_layer is wrong
	var query_all := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	var result_all := space.intersect_ray(query_all)
	print("  Raycast (all layers, camera world): ", result_all)

	if result.is_empty():
		print("  >> No hit with mask=2. Nothing forwarded.")
		return

	var hit_body = result["collider"]
	print("  Hit body: ", hit_body)
	print("  Hit pos:  ", result["position"])

	for screen in _screen_map:
		print("  Comparing hit ", hit_body, " vs registered ", screen["body"])
		if screen["body"] == hit_body:
			print("  >> MATCH FOUND")
			var vp_pos := _world_to_viewport(
				result["position"], screen["col_shape"], screen["size"]
			)
			print("  >> Forwarding to viewport ", screen["viewport"], " at pos ", vp_pos)
			_forward_event(event, screen["viewport"], vp_pos)
			get_viewport().set_input_as_handled()
			return

	print("  >> Hit something but it's not in _screen_map")

func _world_to_viewport(world_pos: Vector3,
		col_shape: CollisionShape3D, vp_size: Vector2) -> Vector2:
	var local: Vector3    = col_shape.global_transform.affine_inverse() * world_pos
	var box:   BoxShape3D = col_shape.shape as BoxShape3D
	print("    col_shape global_transform: ", col_shape.global_transform)
	print("    local hit pos: ", local, "  box size: ", box.size)

	var uv_x :=        (local.z + box.size.z * 0.5) / box.size.z
	var uv_y := 1.0 - (local.y + box.size.y * 0.5) / box.size.y
	print("    uv: (", uv_x, ", ", uv_y, ")")
	return Vector2(uv_x * vp_size.x, uv_y * vp_size.y)

func _forward_event(event: InputEvent, viewport: SubViewport, pos: Vector2) -> void:
	var e := event.duplicate()
	if e is InputEventMouseButton or e is InputEventMouseMotion:
		e.position        = pos
		e.global_position = pos
		viewport.push_input(e)

# ── Texture application ─────────────────────────────────────────────────────

func _apply_viewport_texture(mesh: MeshInstance3D,
		viewport: SubViewport, surface_index: int) -> void:
	if mesh == null:
		push_error("ScreenManager: mesh reference is null!")
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_texture             = viewport.get_texture()
	mat.shading_mode               = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled           = true
	mat.emission_texture           = viewport.get_texture()
	mat.emission_energy_multiplier = 0.8
	mesh.set_surface_override_material(surface_index, mat)
