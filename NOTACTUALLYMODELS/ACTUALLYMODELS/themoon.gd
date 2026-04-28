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

## Seconds to wait before spawning the next icon after a call is finished.
@export var icon_spawn_delay: float = 6.0

## Optional: assign a sound (AudioStream) to play when a new icon appears.
## If left empty, a short programmatic beep is used automatically.
@export var ding_sound: AudioStream

# body → call_id
var _body_to_call_id: Dictionary = {}
# body → { "full": Node3D, "mini": Node3D }
var _body_to_icons: Dictionary = {}

# Queue of calls waiting to have their icon spawned
var _pending_calls: Array[Dictionary] = []

var _spawn_timer: Timer
var _ding_player: AudioStreamPlayer

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	await get_tree().process_frame

	if camera == null:
		camera = get_node_or_null("../../Camera3D")

	# Timer for delayed icon spawning
	_spawn_timer = Timer.new()
	_spawn_timer.one_shot = true
	_spawn_timer.timeout.connect(_spawn_next_pending)
	add_child(_spawn_timer)

	# Audio player for the ding
	_ding_player = AudioStreamPlayer.new()
	add_child(_ding_player)

	# Connect to GameState signals.
	GameState.day_started.connect(_on_day_started)
	# Start the next-icon countdown only after the player actually submits/declines.
	GameState.call_completed.connect(_schedule_next_spawn)

	_spawn_icons_for_day(GameState.current_day)

	print("Moon icon queue loaded for day %d: %d pending" % [
		GameState.current_day, _pending_calls.size()
	])


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


# ── Day management ────────────────────────────────────────────────────────────

func _on_day_started(day_number: int) -> void:
	_clear_all_icons()
	_pending_calls.clear()
	_spawn_timer.stop()
	await get_tree().process_frame  # let queue_free() flush before spawning new icons
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
	for entry in CallDatabase.get_calls_for_day(day):
		var dir: Vector3 = entry.get("icon_direction", Vector3.ZERO)
		if dir != Vector3.ZERO:
			_pending_calls.append(entry)

	# Spawn the very first icon immediately (no ding — it's just the day starting).
	# Everything else waits until the player finishes a call.
	if _pending_calls.size() > 0:
		var first = _pending_calls.pop_front()
		add_icon(first["id"], first["icon_direction"])


# ── Delayed spawn ─────────────────────────────────────────────────────────────

## Called by the Timer after icon_spawn_delay seconds.
func _spawn_next_pending() -> void:
	if _pending_calls.is_empty():
		return
	var entry = _pending_calls.pop_front()
	add_icon(entry["id"], entry["icon_direction"])
	_play_ding()
	print("New moon icon spawned for call #%d" % entry["id"])


## Schedule the next icon spawn. Called internally after a call is removed.
func _schedule_next_spawn() -> void:
	if _pending_calls.is_empty():
		return
	if _spawn_timer.is_stopped():
		_spawn_timer.start(icon_spawn_delay)


## Play ding_sound if assigned, otherwise generate a short programmatic beep.
func _play_ding() -> void:
	if ding_sound != null:
		_ding_player.stream = ding_sound
		_ding_player.play()
		return

	# Programmatic fallback: a short 880 Hz sine-wave blip (~0.18 s)
	var sample_rate := 22050
	var duration    := 0.18
	var frequency   := 880.0
	var num_samples := int(sample_rate * duration)

	var wav := AudioStreamWAV.new()
	wav.format       = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate     = sample_rate
	wav.stereo       = false

	var data := PackedByteArray()
	data.resize(num_samples * 2)
	for i in range(num_samples):
		var t       := float(i) / float(sample_rate)
		# Gentle fade-out over last 30 % to avoid click
		var env     := 1.0 - smoothstep(0.7 * duration, duration, t)
		var sample  := int(clamp(sin(TAU * frequency * t) * env * 28000.0, -32768.0, 32767.0))
		data[i * 2]     = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF

	wav.data = data
	_ding_player.stream = wav
	_ding_player.play()


# ── Icon management ───────────────────────────────────────────────────────────

func add_icon(call_id: int, direction: Vector3) -> void:
	direction = direction.normalized()

	var world_scale := global_transform.basis.get_scale().x
	var local_hover := icon_hover / world_scale if world_scale > 0.0 else icon_hover

	var root := Node3D.new()
	add_child(root)
	root.position = direction * (surface_radius + local_hover)

	var world_dir := (global_transform.basis * direction).normalized()
	var up_hint := Vector3.UP if abs(world_dir.dot(Vector3.UP)) < 0.99 else Vector3.FORWARD
	root.look_at(root.global_position + world_dir, up_hint)
	root.rotate_object_local(Vector3.RIGHT, PI / 2.0)

	var full_icon: Node3D = preload("res://MoonIcon.tscn").instantiate()
	full_icon.scale = Vector3.ONE * icon_scale
	root.add_child(full_icon)
	_make_icon_transparent(full_icon)
	_set_cull_margin(full_icon)

	var mini_icon: Node3D = preload("res://MiniIcon.tscn").instantiate()
	mini_icon.scale = Vector3.ONE * (icon_scale * 0.35)
	mini_icon.visible = false
	root.add_child(mini_icon)
	_set_cull_margin(mini_icon)

	var body := AnimatableBody3D.new()
	body.collision_layer = 4
	body.collision_mask  = 0
	body.sync_to_physics = false
	root.add_child(body)
	var col    := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = icon_collision_radius
	col.shape = sphere
	body.add_child(col)

	_body_to_call_id[body] = call_id
	_body_to_icons[body]   = {"full": full_icon, "mini": mini_icon}


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
