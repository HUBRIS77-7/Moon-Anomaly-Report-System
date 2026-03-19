# ScreenManager.gd
extends Node

@onready var panel_ui: Control = $PanelViewport/ScreenPanelUI
@onready var info_ui: Control = $InfoViewport/ScreenInfoUI
@onready var icon_ui: Control = $IconViewport/ScreenIconUI
@onready var screen_panel_mesh: MeshInstance3D = get_node("../SubViewport/Props/NEWLSHAPE/ScreenPanel")
@onready var screen_info_mesh: MeshInstance3D = get_node("../SubViewport/Props/NEWLSHAPE/ScreenInfo")
@onready var screen_icon_mesh: MeshInstance3D = get_node("../SubViewport/Props/COMPUTER3D2/ScreenIcon")


func _ready() -> void:
	info_ui.connect_to_panel(panel_ui)
	icon_ui.connect_to_panel(panel_ui)
	_apply_viewport_texture(screen_panel_mesh, $PanelViewport, 0)
	_apply_viewport_texture(screen_info_mesh, $InfoViewport, 0)
	_apply_viewport_texture(screen_icon_mesh, $IconViewport, 0)
	# Now safe to load — connections exist
	panel_ui._load_entry(1)


func _apply_viewport_texture(mesh: MeshInstance3D, viewport: SubViewport, surface_index: int) -> void:
	if mesh == null:
		push_error("ScreenManager: mesh reference is null — check node paths!")
		return
	var mat = StandardMaterial3D.new()
	mat.albedo_texture = viewport.get_texture()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission_texture = viewport.get_texture()
	mat.emission_energy_multiplier = 0.8
	mesh.set_surface_override_material(surface_index, mat)
