# LifeSupportUnit.gd
extends Node3D

@export var lights_root: Node3D
@export var max_reserve: float = 100.0
@export var reserve: float = 100.0:
	set(v):
		var was_critical: bool = reserve <= 0.0
		reserve = clampf(v, 0.0, max_reserve)
		var is_critical: bool = reserve <= 0.0
		if is_critical != was_critical:
			_update_state()

var _material: ShaderMaterial
var _depletion_timer: Timer

func _ready() -> void:
	if lights_root == null:
		push_warning("LifeSupportUnit: lights_root not assigned.")
		return

	_material = ShaderMaterial.new()
	_material.shader = preload("res://lifesupport_lights.gdshader")

	for mesh in _find_mesh_instances(lights_root):
		for surf in mesh.mesh.get_surface_count():
			mesh.set_surface_override_material(surf, _material)

	_update_state()

	_depletion_timer = Timer.new()
	_depletion_timer.wait_time = 60.0
	_depletion_timer.autostart = true
	_depletion_timer.timeout.connect(func(): deplete(1.0))
	add_child(_depletion_timer)

	GameState.day_ended.connect(_on_day_ended)

func _find_mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	for child in node.get_children():
		if child is MeshInstance3D:
			result.append(child)
		result.append_array(_find_mesh_instances(child))
	return result

func deplete(amount: float) -> void:
	reserve -= amount

func restore(amount: float) -> void:
	reserve += amount

func _on_day_ended(_day: int, _correct: int, _total: int, _credits: int) -> void:
	reserve = max_reserve

func _update_state() -> void:
	if _material == null:
		return
	_material.set_shader_parameter("state", 1.0 if reserve > 0.0 else 0.0)
