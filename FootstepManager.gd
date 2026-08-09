# FootstepManager.gd
# Autoload as "FootstepManager" — place anywhere in the autoload order,
# it has no dependency on GameState/other systems.
#
# ── SETUP ─────────────────────────────────────────────────────────────────────
# 1. Tag floor geometry with metadata: select a StaticBody3D (or its
#    CollisionShape3D) in the editor, open the Inspector's bottom "Metadata"
#    section (or Node > Metadata), and add a String entry:
#       key:   floor_material
#       value: "metal" / "carpet" / "concrete" / etc.
#    Untagged floors fall back to DEFAULT_MATERIAL.
#
# 2. Populate MATERIAL_SOUNDS below with res:// paths to your step .wav/.ogg
#    files. 3-6 variations per material is enough to avoid repetition.
#
# 3. From PlayerController.gd:
#       func _ready() -> void:
#           FootstepManager.register_player(self)
#       func _physics_process(delta: float) -> void:
#           ...existing movement code...
#           FootstepManager.update(delta, global_position, velocity, _seated)
#
#    That's it — FootstepManager tracks distance travelled internally and
#    fires a step whenever the accumulator crosses STEP_DISTANCE.

extends Node

# ── Config ────────────────────────────────────────────────────────────────────
const STEP_DISTANCE: float = 1.1        # metres between footstep sounds
const MIN_SPEED_TO_STEP: float = 0.3    # m/s — below this, don't accumulate
const POOL_SIZE: int = 4
const PITCH_JITTER: float = 0.08        # ± fraction
const VOLUME_JITTER_DB: float = 2.0     # ± dB
const BASE_VOLUME_DB: float = -6.0
const RAY_LENGTH: float = 1.5
const FLOOR_COLLISION_MASK: int = 1     # match whatever layer your room geometry is on

const DEFAULT_MATERIAL := "default"

const MATERIAL_SOUNDS: Dictionary = {
	"default": [
		"res://audio/footsteps/generic_01.wav",
		"res://audio/footsteps/generic_02.wav",
		"res://audio/footsteps/generic_03.wav",
	],
	"metal": [
		"res://Audio/Footsteps/834029__ienba__footsteps-on-metal.wav",
		"res://Audio/Footsteps/816413__atleastrelatively__metal-footstep.wav",
	],
	"concrete": [
		"res://audio/footsteps/concrete_01.wav",
		"res://audio/footsteps/concrete_02.wav",
		"res://audio/footsteps/concrete_03.wav",
	],
	"carpet": [
		"res://audio/footsteps/carpet_01.wav",
		"res://audio/footsteps/carpet_02.wav",
		"res://audio/footsteps/carpet_03.wav",
	],
}

# ── Internal state ───────────────────────────────────────────────────────────
var _player: Node3D = null
var _last_position: Vector3 = Vector3.ZERO
var _distance_accum: float = 0.0
var _pool: Array[AudioStreamPlayer3D] = []
var _pool_index: int = 0
var _last_clip_by_material: Dictionary = {}   # material -> last stream path (avoids back-to-back repeats)
var _cached_streams: Dictionary = {}          # path -> AudioStream (loaded once)

# ── Setup ─────────────────────────────────────────────────────────────────────
func _ready() -> void:
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer3D.new()
		p.max_distance = 12.0
		p.unit_size = 3.0
		add_child(p)
		_pool.append(p)

## Call once — typically from the player's _ready().
func register_player(player: Node3D) -> void:
	_player = player
	_last_position = player.global_position
	_distance_accum = 0.0

## Call every physics frame while the player might be walking.
## velocity: the player's current velocity (only horizontal component is used).
## is_seated: pass GameState.is_seated (or your own seated flag) — steps never
##            fire while seated, and the accumulator resets so sitting down
##            and standing back up doesn't cause a "free" step.
func update(delta: float, current_position: Vector3, velocity: Vector3, is_seated: bool) -> void:
	if _player == null:
		return

	if is_seated:
		_distance_accum = 0.0
		_last_position = current_position
		return

	var horizontal_velocity := Vector3(velocity.x, 0.0, velocity.z)
	var speed := horizontal_velocity.length()

	if speed < MIN_SPEED_TO_STEP:
		# Don't let idle jitter slowly accumulate a phantom step.
		_last_position = current_position
		return

	var moved := Vector3(current_position.x - _last_position.x, 0.0, current_position.z - _last_position.z)
	_distance_accum += moved.length()
	_last_position = current_position

	if _distance_accum >= STEP_DISTANCE:
		_distance_accum = fmod(_distance_accum, STEP_DISTANCE)
		_play_step(current_position)

# ── Step playback ─────────────────────────────────────────────────────────────

func _play_step(at_position: Vector3) -> void:
	var material := _detect_floor_material(at_position)
	var stream := _pick_stream(material)
	if stream == null:
		return

	var player := _pool[_pool_index]
	_pool_index = (_pool_index + 1) % _pool.size()

	player.global_position = at_position
	player.stream = stream
	player.pitch_scale = 1.0 + randf_range(-PITCH_JITTER, PITCH_JITTER)
	player.volume_db = BASE_VOLUME_DB + randf_range(-VOLUME_JITTER_DB, VOLUME_JITTER_DB)
	player.play()

func _pick_stream(material: String) -> AudioStream:
	var paths: Array = MATERIAL_SOUNDS.get(material, MATERIAL_SOUNDS.get(DEFAULT_MATERIAL, []))
	if paths.is_empty():
		return null

	var last_path: String = _last_clip_by_material.get(material, "")
	var choice: String = paths[randi() % paths.size()]

	# Re-roll once if we happened to pick the same clip as last time and
	# there's more than one option — cheap way to avoid audible repeats.
	if choice == last_path and paths.size() > 1:
		choice = paths[randi() % paths.size()]

	_last_clip_by_material[material] = choice
	return _load_cached(choice)

func _load_cached(path: String) -> AudioStream:
	if _cached_streams.has(path):
		return _cached_streams[path]
	if not ResourceLoader.exists(path):
		push_warning("FootstepManager: missing audio file '%s'" % path)
		return null
	var stream: AudioStream = load(path)
	_cached_streams[path] = stream
	return stream

# ── Floor detection ────────────────────────────────────────────────────────────

func _detect_floor_material(from_position: Vector3) -> String:
	if _player == null:
		return DEFAULT_MATERIAL

	var space := _player.get_world_3d().direct_space_state
	var ray_start := from_position + Vector3(0, 0.3, 0)
	var ray_end := from_position - Vector3(0, RAY_LENGTH, 0)

	var query := PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.collision_mask = FLOOR_COLLISION_MASK
	query.exclude = [_player.get_rid()] if _player.has_method("get_rid") else []

	var result := space.intersect_ray(query)
	if result.is_empty():
		return DEFAULT_MATERIAL

	return _find_material_tag(result["collider"])

## Walks up the tree from the hit collider looking for a "floor_material"
## metadata entry, so you can tag either the CollisionShape3D, its parent
## StaticBody3D, or further up (e.g. the room's root node) — whichever is
## most convenient per scene.
func _find_material_tag(node: Node) -> String:
	var current: Node = node
	var depth := 0
	while current != null and depth < 5:
		if current.has_meta("floor_material"):
			return str(current.get_meta("floor_material"))
		current = current.get_parent()
		depth += 1
	return DEFAULT_MATERIAL
