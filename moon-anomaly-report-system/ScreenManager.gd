# ScreenManager.gd
extends Node

@onready var panel_ui: Control = $PanelViewport/ScreenPanelUI
@onready var info_ui: Control = $InfoViewport/ScreenInfoUI
@onready var icon_ui: Control = $IconViewport/ScreenIconUI
@onready var screen_panel_mesh: MeshInstance3D = get_node("../SubViewport/Props/NEWLSHAPE/ScreenPanel")
@onready var screen_info_mesh: MeshInstance3D = get_node("../SubViewport/Props/NEWLSHAPE/ScreenInfo")
@onready var screen_icon_mesh: MeshInstance3D = get_node("../SubViewport/Props/COMPUTER3D2/ScreenIcon")
@onready var camera: Camera3D = get_node("../SubViewport/Camera3D")

#var _screen_map: Dictionary = {}

func _ready() -> void:
	$InfoViewport.size = Vector2i(480, 308)
	$PanelViewport.size = Vector2i(240, 640)
	$IconViewport.size = Vector2i(256, 256)
	info_ui.connect_to_panel(panel_ui)
	icon_ui.connect_to_panel(panel_ui)
	_apply_viewport_texture(screen_panel_mesh, $PanelViewport, 0)
	_apply_viewport_texture(screen_info_mesh, $InfoViewport, 0)
	_apply_viewport_texture(screen_icon_mesh, $IconViewport, 0)
	await get_tree().process_frame
	await get_tree().process_frame
	panel_ui._load_entry(1)
	_register_screen(screen_panel_mesh, $PanelViewport, Vector2(240, 640))
	_register_screen(screen_info_mesh, $InfoViewport, Vector2(480, 308))

#func _register_screen(mesh: MeshInstance3D, viewport: SubViewport, size: Vector2) -> void:
	#if mesh == null:
		#push_error("_register_screen: mesh is null!")
		#return
	#var body = _find_static_body(mesh)
	#if body:
		#_screen_map[body.get_rid()] = {"viewport": viewport, "size": size}
	#else:
		#push_warning("No StaticBody3D found under " + mesh.name)
#
func _find_static_body(node: Node) -> StaticBody3D:
	for n in node.get_children():
		if n is StaticBody3D:
			return n
		var result = _find_static_body(n)
		if result:
			return result
	return null

#func _unhandled_input(event: InputEvent) -> void:
	#if not GameState.is_seated:
		#return
	#if not (event is InputEventMouseButton or event is InputEventMouseMotion):
		#return
	#var mouse_pos = get_viewport().get_mouse_position()
	#var ray_origin = camera.project_ray_origin(mouse_pos)
	#var ray_end = ray_origin + camera.project_ray_normal(mouse_pos) * 100.0
	#var space = camera.get_world_3d().direct_space_state
	#var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	#query.collide_with_areas = false
	#query.collide_with_bodies = true
	#var result = space.intersect_ray(query)
	#if result.is_empty():
		#return
	#var body_rid = result["collider"].get_rid()
	#if not _screen_map.has(body_rid):
		#return
	#var screen = _screen_map[body_rid]
	#var uv: Vector2 = result.get("uv", Vector2.ZERO)
	#var viewport_pos = uv * screen["size"]
	#_forward_event(event, screen["viewport"], viewport_pos)
	#get_viewport().set_input_as_handled()

func _forward_event(event: InputEvent, viewport: SubViewport, pos: Vector2) -> void:
	var new_event = event.duplicate()
	if new_event is InputEventMouseButton or new_event is InputEventMouseMotion:
		new_event.position = pos
		new_event.global_position = pos
		viewport.push_input(new_event)

func _apply_viewport_texture(mesh: MeshInstance3D, viewport: SubViewport, surface_index: int) -> void:
	if mesh == null:
		push_error("ScreenManager: mesh reference is null!")
		return
	var mat = StandardMaterial3D.new()
	mat.albedo_texture = viewport.get_texture()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission_texture = viewport.get_texture()
	mat.emission_energy_multiplier = 0.8
	mesh.set_surface_override_material(surface_index, mat)
	
	
	


# Change the map to store node references
var _screen_map: Array = []  # Array of {body, viewport, size}

func _register_screen(mesh: MeshInstance3D, viewport: SubViewport, size: Vector2) -> void:
	if mesh == null:
		push_error("_register_screen: mesh is null!")
		return
	var body = _find_static_body(mesh)
	if body:
		_screen_map.append({"body": body, "viewport": viewport, "size": size})
		print("Registered: ", body, " RID: ", body.get_rid())
	else:
		push_warning("No StaticBody3D found under " + mesh.name)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return

	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_end = ray_origin + camera.project_ray_normal(mouse_pos) * 100.0
	var space = camera.get_world_3d().direct_space_state

	# First try with layer 2 only
	var query2 = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query2.collision_mask = 2
	var result2 = space.intersect_ray(query2)
	print("Layer 2 hit: ", result2)

	# Then try with no mask (hit everything)
	var queryAll = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	var resultAll = space.intersect_ray(queryAll)
	print("All layers hit: ", resultAll)
