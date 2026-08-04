# ScreenManager.gd
# Generic input router. Knows nothing about specific screens — it just
# raycasts and asks whatever it hit ("InteractiveScreen" or the moon) to
# handle the event. Add/move/rename screens freely without touching this file.

extends Node

@onready var camera: Camera3D        = get_node("../SubViewport/Camera3D")
@onready var moon: Node3D            = get_node("../SubViewport/Props/THEMOON")
@onready var terminal_manager: Node  = get_node("../SubViewport/TerminalStuff/TerminalManager")
@onready var desktop_ui: Control     = $DesktopViewport/DesktopUI

# Non-interactive decorative screen (icon display) still gets its texture
# applied directly since it has no click behavior.
@onready var icon_ui: Control        = $IconViewport/ScreenIconUI
@onready var panel_ui: Control       = $PanelViewport/ScreenPanelUI
@onready var screen_icon_mesh: MeshInstance3D = get_node("../SubViewport/Props/COMPUTER3D2/ScreenIcon")

var _focused_viewport: SubViewport = null
var _focused_screen: InteractiveScreen = null
var _last_vp_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	$DesktopViewport.size = Vector2i(1940, 635)
	$DesktopViewport.handle_input_locally = false
	$InfoViewport.size  = Vector2i(1940, 1080)
	$PanelViewport.size = Vector2i(240, 640)
	$IconViewport.size  = Vector2i(256, 256)
	$PanelViewport.handle_input_locally = false
	$InfoViewport.handle_input_locally  = false

	_wire_interactive_screens()

	info_ui_connect()
	_apply_icon_texture()

	await get_tree().process_frame
	await get_tree().process_frame
	panel_ui._load_entry(1)

func _wire_interactive_screens() -> void:
	var viewport_map := {
		"desktop": $DesktopViewport,
		"panel":   $PanelViewport,
		"info":    $InfoViewport,
	}
	for screen in get_tree().get_nodes_in_group("interactive_screens"):
		if screen is InteractiveScreen and viewport_map.has(screen.screen_id):
			screen.assign_viewport(viewport_map[screen.screen_id])

func info_ui_connect() -> void:
	# ScreenInfoUI now owns entry navigation itself (see ScreenInfoUI.gd) and
	# emits its own entry_changed signal, so it no longer needs to be wired
	# to ScreenPanelUI via connect_to_panel(). Only the icon display still
	# needs to listen for entry changes, and it can listen directly to
	# ScreenInfoUI now.
	var info_ui: Control = $InfoViewport/ScreenInfoUI
	icon_ui.connect_to_panel(info_ui)

func _apply_icon_texture() -> void:
	if screen_icon_mesh == null:
		return
	var mat := StandardMaterial3D.new()
	mat.transparency               = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.render_priority             = 1
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	mat.albedo_texture               = $IconViewport.get_texture()
	mat.shading_mode                = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled             = true
	mat.emission_texture             = $IconViewport.get_texture()
	mat.emission_energy_multiplier   = 1.5
	screen_icon_mesh.set_surface_override_material(0, mat)

# ── Input ─────────────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if DayEndScreen.visible:
		return
	if DialogManager.is_active():
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			if CallDatabase.has_next_call():
				desktop_ui.receive_call(CallDatabase.next_call())
			get_viewport().set_input_as_handled()
			return

	if event is InputEventKey:
		if _focused_viewport != null:
			_focused_viewport.push_input(event)
			get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseMotion:
		if _focused_viewport != null and _focused_screen != null:
			var pos: Vector2 = _project_screen_pos()
			if pos != Vector2(-1, -1):
				_last_vp_pos = pos
				_forward_event(event, _focused_viewport, _last_vp_pos)
				get_viewport().set_input_as_handled()
			return
		return

	if event is InputEventMouseButton and _focused_viewport != null:
		if event.button_index in [
			MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN,
			MOUSE_BUTTON_WHEEL_LEFT, MOUSE_BUTTON_WHEEL_RIGHT,
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

	_handle_click(event)

func _project_screen_pos() -> Vector2:
	if _focused_screen == null:
		return Vector2(-1, -1)
	var mouse_pos := camera.get_viewport().get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_dir := camera.project_ray_normal(mouse_pos)
	return _focused_screen.world_to_viewport_pos_from_ray(ray_origin, ray_dir)


func _handle_click(event: InputEvent) -> void:
	var mouse_pos := camera.get_viewport().get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_end    := ray_origin + camera.project_ray_normal(mouse_pos) * 100.0
	var space := camera.get_world_3d().direct_space_state

	# Layer 2: interactive screens
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collision_mask = 2
	var result := space.intersect_ray(query)

	if not result.is_empty() and result["collider"] is InteractiveScreen:
		var screen: InteractiveScreen = result["collider"]
		_focused_viewport = screen.viewport
		_focused_screen   = screen
		_last_vp_pos = screen.world_to_viewport_pos(result["position"])

		# ── TEMP DEBUG — remove once database screen offset is fixed ──────────
		if screen.screen_id == "info":
			var col_shape: CollisionShape3D = screen.get_node("CollisionShape3D") if screen.has_node("CollisionShape3D") else null
			if col_shape:
				var box: BoxShape3D = col_shape.shape as BoxShape3D
				var local: Vector3 = col_shape.global_transform.affine_inverse() * result["position"]
				print("=== DB SCREEN CLICK DEBUG ===")
				print("world hit pos: ", result["position"])
				print("local hit pos: ", local)
				print("box size: ", box.size if box else "null")
				print("computed viewport pos (uv * viewport size): ", _last_vp_pos)
				print("viewport size: ", _focused_viewport.size if _focused_viewport else "null")
				if box and _focused_viewport:
					var uv := Vector2(_last_vp_pos) / Vector2(_focused_viewport.size)
					print("uv: ", uv)
				print("==============================")
		# ── END TEMP DEBUG ──────────────────────────────────────────────────────

		_forward_event(event, _focused_viewport, _last_vp_pos)
		get_viewport().set_input_as_handled()
		return

	# Nothing on layer 2 — try the moon (layer 4)
	_focused_viewport = null
	_focused_screen = null

	var query4 := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query4.collision_mask = 4
	var moon_result := space.intersect_ray(query4)

	if not moon_result.is_empty():
		var call_id = moon.get_call_id_for_body(moon_result["collider"])
		if call_id != -1:
			var data := CallDatabase.get_call(call_id)
			if not data.has("status"):
				desktop_ui.receive_call(data)
				moon.remove_icon(call_id)
				terminal_manager.go_to_index(1)

func _raycast_screen_pos() -> Variant:
	if _focused_screen == null:
		return null
	var mouse_pos := camera.get_viewport().get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_end := ray_origin + camera.project_ray_normal(mouse_pos) * 100.0
	var space := camera.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collision_mask = 2
	var result := space.intersect_ray(query)
	if result.is_empty():
		return null
	return _focused_screen.world_to_viewport_pos(result["position"])

func _forward_event(event: InputEvent, viewport: SubViewport, pos: Vector2) -> void:
	if event == null:
		return
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
