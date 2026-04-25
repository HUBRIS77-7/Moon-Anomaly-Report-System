# ScreenManager.gd
extends Node

@onready var desktop_ui: Control = $DesktopViewport/DesktopUI
@onready var screen_desktop_mesh: MeshInstance3D = get_node("../SubViewport/Props/BIGTERMINAL/ScreenPC")
@onready var panel_ui: Control       = $PanelViewport/ScreenPanelUI
@onready var info_ui: Control        = $InfoViewport/ScreenInfoUI
@onready var icon_ui: Control        = $IconViewport/ScreenIconUI
@onready var screen_panel_mesh: MeshInstance3D = get_node("../SubViewport/Props/NEWLSHAPE/ScreenPanel")
@onready var screen_info_mesh:  MeshInstance3D = get_node("../SubViewport/Props/NEWLSHAPE/ScreenInfo")
@onready var screen_icon_mesh:  MeshInstance3D = get_node("../SubViewport/Props/COMPUTER3D2/ScreenIcon")
@onready var camera: Camera3D        = get_node("../SubViewport/Camera3D")
@onready var moon: Node3D = get_node("../SubViewport/Props/THEMOON")
@onready var terminal_manager: Node = get_node("../SubViewport/TerminalStuff/TerminalManager")

var _screen_map: Array = []
var _focused_viewport: SubViewport = null
var _last_vp_pos: Vector2 = Vector2.ZERO
var _focused_col_shape: CollisionShape3D = null
var _focused_vp_size: Vector2 = Vector2.ZERO
var _focused_flip_x: bool = false

func _ready() -> void:
	$DesktopViewport.size = Vector2i(640, 640)
	$DesktopViewport.handle_input_locally = false
	_apply_viewport_texture(screen_desktop_mesh, $DesktopViewport, 0)
	_register_screen(screen_desktop_mesh, $DesktopViewport, Vector2(640, 640), true)

	$InfoViewport.size  = Vector2i(480, 308)
	$PanelViewport.size = Vector2i(240, 640)
	$IconViewport.size  = Vector2i(256, 256)

	$PanelViewport.handle_input_locally = false
	$InfoViewport.handle_input_locally  = false

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

# ── Registration ─────────────────────────────────────────────────────────────

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

func _register_screen(mesh: MeshInstance3D, viewport: SubViewport, size: Vector2, flip_x: bool = false) -> void:
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
		"flip_x":    flip_x,
	})

# ── Input ─────────────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	# ── DEBUG: F1 opens the next queued call on the BIGTERMINAL desktop ─────
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			if CallDatabase.has_next_call():
				desktop_ui.spawn_call_window(CallDatabase.next_call())
			get_viewport().set_input_as_handled()
			return

	if event is InputEventKey:
		if _focused_viewport != null:
			_focused_viewport.push_input(event)
			get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseMotion:
		if _focused_viewport != null and _focused_col_shape != null:
			var mouse_pos := camera.get_viewport().get_mouse_position()
			var ray_origin := camera.project_ray_origin(mouse_pos)
			var ray_end := ray_origin + camera.project_ray_normal(mouse_pos) * 100.0
			var space := camera.get_world_3d().direct_space_state
			var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
			query.collision_mask = 2
			var result := space.intersect_ray(query)
			var pos: Vector2
			if result.is_empty():
				pos = _last_vp_pos
			else:
				pos = _world_to_viewport(result["position"], _focused_col_shape, _focused_vp_size, _focused_flip_x)
			_last_vp_pos = pos
			_forward_event(event, _focused_viewport, pos)
			get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton and _focused_viewport != null:
		if event.button_index in [
			MOUSE_BUTTON_WHEEL_UP,
			MOUSE_BUTTON_WHEEL_DOWN,
			MOUSE_BUTTON_WHEEL_LEFT,
			MOUSE_BUTTON_WHEEL_RIGHT,
		]:
			_forward_event(event, _focused_viewport, _last_vp_pos)
			get_viewport().set_input_as_handled()
			return

	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		return

	if not event.pressed:
		if _focused_viewport != null:
			_forward_event(event, _focused_viewport, _last_vp_pos)
			get_viewport().set_input_as_handled()
		return

	var mouse_pos := camera.get_viewport().get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_end    := ray_origin + camera.project_ray_normal(mouse_pos) * 100.0

	var space := camera.get_world_3d().direct_space_state
	var query  := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collision_mask = 2
	var result := space.intersect_ray(query)

	if result.is_empty():
		_focused_viewport = null

		# Nothing on layer 2 — check moon icons on layer 4
		var query4 := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
		query4.collision_mask = 4
		var moon_result := space.intersect_ray(query4)

		if not moon_result.is_empty():
			var call_id = moon.get_call_id_for_body(moon_result["collider"])
			if call_id != -1:
				var data := CallDatabase.get_call(call_id)
				if not data.has("status"):
					desktop_ui.receive_call(data)
					# Remove the icon from the moon — it has been claimed.
					moon.remove_icon(call_id)
					# anchors: Terminal3(0), Terminal2(1), Terminal1(2)
					# Terminal2 faces the BIGTERMINAL
					terminal_manager.go_to_index(1)
		return

	var hit_body = result["collider"]

	for screen in _screen_map:
		if screen["body"] == hit_body:
			_focused_viewport = screen["viewport"]
			_focused_col_shape = screen["col_shape"]
			_focused_vp_size = screen["size"]
			_focused_flip_x = screen["flip_x"]
			_last_vp_pos = _world_to_viewport(
				result["position"], screen["col_shape"], screen["size"], screen["flip_x"]
			)
			_forward_event(event, screen["viewport"], _last_vp_pos)
			get_viewport().set_input_as_handled()
			return

	_focused_viewport = null

# ── Viewport helpers ──────────────────────────────────────────────────────────

func _world_to_viewport(world_pos: Vector3,
		col_shape: CollisionShape3D, vp_size: Vector2, flip_x: bool = false) -> Vector2:
	var local: Vector3    = col_shape.global_transform.affine_inverse() * world_pos
	var box:   BoxShape3D = col_shape.shape as BoxShape3D

	var uv_x := (local.z + box.size.z * 0.5) / box.size.z
	if flip_x:
		uv_x = 1.0 - uv_x
	var uv_y := 1.0 - (local.y + box.size.y * 0.5) / box.size.y
	uv_x = clamp(uv_x, 0.0, 1.0)
	uv_y = clamp(uv_y, 0.0, 1.0)
	return Vector2(uv_x * vp_size.x, uv_y * vp_size.y)

func _forward_event(event: InputEvent, viewport: SubViewport, pos: Vector2) -> void:
	var e := event.duplicate()
	if e is InputEventMouseButton:
		e.position        = pos
		e.global_position = pos
		if e.pressed:
			var motion := InputEventMouseMotion.new()
			motion.position        = pos
			motion.global_position = pos
			viewport.push_input(motion)
		viewport.push_input(e)
	elif e is InputEventMouseMotion:
		e.position        = pos
		e.global_position = pos
		viewport.push_input(e)

func _apply_viewport_texture(mesh: MeshInstance3D,
		viewport: SubViewport, surface_index: int) -> void:
	if mesh == null:
		push_error("ScreenManager: mesh reference is null!")
		return
	var mat := StandardMaterial3D.new()
	mat.transparency               = BaseMaterial3D.TRANSPARENCY_ALPHA  # ← forces transparent pass
	mat.render_priority            = 1
	mat.texture_filter             = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.albedo_texture             = viewport.get_texture()
	mat.shading_mode               = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled           = true
	mat.emission_texture           = viewport.get_texture()
	mat.emission_energy_multiplier = 0.8
	mesh.set_surface_override_material(surface_index, mat)
