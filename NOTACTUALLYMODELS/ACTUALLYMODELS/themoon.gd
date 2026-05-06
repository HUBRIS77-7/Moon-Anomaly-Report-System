# NOTACTUALLYMODELS/ACTUALLYMODELS/themoon.gd
# Moon icon management + spin controls.
# WASD spin is blocked while the player is walking (GameState.is_seated == false).
#
# Day-1 logo:
#   On day 1 the moon sphere is hidden and a flat billboard is shown instead.
#   Assign `day_one_logo` in the Inspector once you have the LUNA logo texture.
#   An amber placeholder is used until then so you can see it in-scene.

extends Node3D

@export var spin_speed:            float    = 1.0
@export var surface_radius:        float    = 32.0
@export var icon_scale:            float    = 50.0
@export var icon_collision_radius: float    = 6.0
@export var icon_hover:            float    = 0.0
@export var look_dot_threshold:    float    = 0.90
@export var icon_spawn_delay:      float    = 6.0

## Texture shown on day 1 in place of the moon sphere.
## Leave unset for a bright amber placeholder.
@export var day_one_logo: Texture2D = null

## Assign in the Inspector OR leave null to auto-find "../../Camera3D".
@export var camera: Camera3D

## Optional ding sound. Falls back to a programmatic beep if unset.
@export var ding_sound: AudioStream

# ── Internal ──────────────────────────────────────────────────────────────────
var _body_to_call_id: Dictionary = {}
var _body_to_icons:   Dictionary = {}
var _pending_calls:   Array[Dictionary] = []
var _spawn_timer:     Timer
var _ding_player:     AudioStreamPlayer
var _logo_billboard:  MeshInstance3D = null

# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	await get_tree().process_frame

	if camera == null:
		camera = get_node_or_null("../../Camera3D")

	_spawn_timer          = Timer.new()
	_spawn_timer.one_shot = true
	_spawn_timer.timeout.connect(_spawn_next_pending)
	add_child(_spawn_timer)

	_ding_player = AudioStreamPlayer.new()
	add_child(_ding_player)

	_setup_logo_billboard()
	_update_day_display(GameState.current_day)

	GameState.day_started.connect(_on_day_started)
	GameState.call_completed.connect(_schedule_next_spawn)

	_spawn_icons_for_day(GameState.current_day)

	print("Moon icon queue loaded for day %d: %d pending" % [
		GameState.current_day, _pending_calls.size()
	])

func _process(delta: float) -> void:
	if GameState.is_seated:
		var yaw   := 0.0
		var pitch := 0.0
		if Input.is_action_pressed("moon_left"):  yaw   += spin_speed * delta
		if Input.is_action_pressed("moon_right"): yaw   -= spin_speed * delta
		if Input.is_action_pressed("moon_up"):    pitch += spin_speed * delta
		if Input.is_action_pressed("moon_down"):  pitch -= spin_speed * delta
		if yaw   != 0.0: rotate_y(yaw)
		if pitch  != 0.0: rotate_object_local(Vector3.RIGHT, pitch)

	if camera == null:
		return

	var cam_forward := -camera.global_transform.basis.z
	for body in _body_to_icons.keys():
		if not is_instance_valid(body):
			continue
		var icons     = _body_to_icons[body]
		var to_icon   = body.global_position - camera.global_position
		if to_icon.length_squared() < 0.0001:
			continue
		var looking := cam_forward.dot(to_icon.normalized()) >= look_dot_threshold
		icons["full"].visible = looking
		icons["mini"].visible = not looking

# ── Day-1 logo billboard ──────────────────────────────────────────────────────

func _setup_logo_billboard() -> void:
	const LOGO_SIZE := 60.0

	var quad      := QuadMesh.new()
	quad.size      = Vector2(LOGO_SIZE, LOGO_SIZE)

	_logo_billboard                  = MeshInstance3D.new()
	_logo_billboard.name             = "LogoBillboard"
	_logo_billboard.mesh             = quad
	_logo_billboard.extra_cull_margin = 16384.0
	add_child(_logo_billboard)

	var mat                           := StandardMaterial3D.new()
	mat.transparency                   = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.render_priority                = 2
	mat.shading_mode                   = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode                 = BaseMaterial3D.BILLBOARD_ENABLED
	mat.billboard_keep_scale           = true

	if day_one_logo != null:
		mat.albedo_texture = day_one_logo
	else:
		mat.albedo_color = Color(0.95, 0.70, 0.10, 1.0)

	_logo_billboard.set_surface_override_material(0, mat)

func _update_day_display(day: int) -> void:
	var moon_mesh := get_node_or_null("Moon") as MeshInstance3D
	if moon_mesh:
		moon_mesh.visible = (day != 1)
	if _logo_billboard:
		_logo_billboard.visible = (day == 1)

# ── Day management ────────────────────────────────────────────────────────────

func _on_day_started(day_number: int) -> void:
	_update_day_display(day_number)
	_clear_all_icons()
	_pending_calls.clear()
	_spawn_timer.stop()
	await get_tree().process_frame
	_spawn_icons_for_day(day_number)
	print("Moon icons refreshed for day %d" % day_number)

func _clear_all_icons() -> void:
	for body: AnimatableBody3D in _body_to_call_id.keys():
		if is_instance_valid(body) and is_instance_valid(body.get_parent()):
			body.get_parent().queue_free()
	_body_to_call_id.clear()
	_body_to_icons.clear()

func _spawn_icons_for_day(day: int) -> void:
	_pending_calls.clear()

	# Route through WeekDatabase so the full required + random-draw list is used.
	var day_calls := WeekDatabase.draw_calls_for_day(GameState.current_week_id, day)
	for entry in day_calls:
		var dir: Vector3 = entry.get("icon_direction", Vector3.ZERO)
		if dir != Vector3.ZERO:
			_pending_calls.append(entry)

	# Day 1: hold icons until LUNA's intro dialog finishes.
	if day == 1:
		if not DialogManager.dialog_finished.is_connected(_on_day1_dialog_done):
			DialogManager.dialog_finished.connect(_on_day1_dialog_done, CONNECT_ONE_SHOT)
		return

	if _pending_calls.size() > 0:
		var first = _pending_calls.pop_front()
		add_icon(first["id"], first["icon_direction"])

func _on_day1_dialog_done(_sequence_id: String) -> void:
	_update_day_display(2)
	_logo_billboard.visible = false

	if _pending_calls.size() > 0:
		var first = _pending_calls.pop_front()
		add_icon(first["id"], first["icon_direction"])

# ── Delayed spawn ─────────────────────────────────────────────────────────────

func _spawn_next_pending() -> void:
	if _pending_calls.is_empty():
		return
	var entry = _pending_calls.pop_front()
	add_icon(entry["id"], entry["icon_direction"])
	_play_ding()
	print("New moon icon spawned for call #%d" % entry["id"])

func _schedule_next_spawn() -> void:
	if _pending_calls.is_empty():
		return
	if _spawn_timer.is_stopped():
		_spawn_timer.start(icon_spawn_delay)

func _play_ding() -> void:
	if ding_sound != null:
		_ding_player.stream = ding_sound
		_ding_player.play()
		return

	var sample_rate := 22050
	var duration    := 0.18
	var frequency   := 880.0
	var num_samples := int(sample_rate * duration)
	var wav         := AudioStreamWAV.new()
	wav.format      = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate    = sample_rate
	wav.stereo      = false
	var data        := PackedByteArray()
	data.resize(num_samples * 2)
	for i in range(num_samples):
		var t      := float(i) / float(sample_rate)
		var env    := 1.0 - smoothstep(0.7 * duration, duration, t)
		var sample := int(clamp(sin(TAU * frequency * t) * env * 28000.0, -32768.0, 32767.0))
		data[i * 2]     = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	wav.data            = data
	_ding_player.stream = wav
	_ding_player.play()

# ── Icon management ───────────────────────────────────────────────────────────

func add_icon(call_id: int, direction: Vector3) -> void:
	direction = direction.normalized()

	var world_scale := global_transform.basis.get_scale().x
	var local_hover := icon_hover / world_scale if world_scale > 0.0 else icon_hover

	var root     := Node3D.new()
	add_child(root)
	root.position = direction * (surface_radius + local_hover)

	var world_dir := (global_transform.basis * direction).normalized()
	var up_hint   := Vector3.UP if abs(world_dir.dot(Vector3.UP)) < 0.99 else Vector3.FORWARD
	root.look_at(root.global_position + world_dir, up_hint)
	root.rotate_object_local(Vector3.RIGHT, PI / 2.0)

	var full_icon: Node3D = preload("res://MoonIcon.tscn").instantiate()
	full_icon.scale = Vector3.ONE * icon_scale
	root.add_child(full_icon)
	_make_icon_transparent(full_icon)
	_set_cull_margin(full_icon)

	var mini_icon: Node3D = preload("res://MiniIcon.tscn").instantiate()
	mini_icon.scale   = Vector3.ONE * (icon_scale * 0.35)
	mini_icon.visible = false
	root.add_child(mini_icon)
	_set_cull_margin(mini_icon)

	var body              := AnimatableBody3D.new()
	body.collision_layer  =  4
	body.collision_mask   =  0
	body.sync_to_physics  = false
	root.add_child(body)

	var col    := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = icon_collision_radius
	col.shape     = sphere
	body.add_child(col)

	_body_to_call_id[body] = call_id
	_body_to_icons[body]   = {"full": full_icon, "mini": mini_icon}

func _make_icon_transparent(node: Node) -> void:
	if node is MeshInstance3D and node.mesh:
		for i in range(node.mesh.get_surface_count()):
			var mat = node.get_active_material(i)
			if mat is BaseMaterial3D:
				var new_mat             := mat.duplicate() as BaseMaterial3D
				new_mat.transparency    = BaseMaterial3D.TRANSPARENCY_ALPHA
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
		if is_instance_valid(body) and is_instance_valid(body.get_parent()):
			body.get_parent().queue_free()
		return

func get_call_id_for_body(body: Object) -> int:
	return _body_to_call_id.get(body, -1)

func _set_cull_margin(node: Node) -> void:
	if node is MeshInstance3D:
		node.extra_cull_margin = 16384.0
	for child in node.get_children():
		_set_cull_margin(child)
