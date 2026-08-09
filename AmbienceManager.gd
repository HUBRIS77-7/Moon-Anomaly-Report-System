# AmbienceManager.gd
# Autoload as "AmbienceManager". No dependency on other autoloads.
#
# ── SETUP ─────────────────────────────────────────────────────────────────────
# 1. Drop an Area3D with AmbienceZone.gd attached into each distinct room
#    (BreakRoom, Observatory, Bedroom, GarageWorkshop, hallway segments, etc).
#    Size it to roughly cover the walkable floor of that room.
#    collision_layer = 0, collision_mask = 1 (or whatever layer the player's
#    CharacterBody3D sits on).
#
# 2. Set bed_stream / one_shot_pool per zone in the Inspector.
#
# 3. From PlayerController.gd:
#       func _ready() -> void:
#           AmbienceManager.register_player(self)
#           AmbienceManager.start_base_hum()
#
#    That's it — zones report themselves in/out via signals, no polling needed.

extends Node

# ── Config ────────────────────────────────────────────────────────────────────
const BASE_HUM_STREAM: String = "res://audio/ambience/base_hum_loop.ogg"
const BASE_HUM_VOLUME_DB: float = -18.0

const DEFAULT_ONE_SHOTS: Array[String] = [
	"res://audio/ambience/creak_01.wav",
	"res://audio/ambience/creak_02.wav",
	"res://audio/ambience/distant_clank_01.wav",
]
const DEFAULT_ONE_SHOT_INTERVAL_MIN: float = 10.0
const DEFAULT_ONE_SHOT_INTERVAL_MAX: float = 25.0
const DEFAULT_ONE_SHOT_VOLUME_DB: float = -12.0

const BED_CROSSFADE_TIME: float = 1.4

# ── Internal state ───────────────────────────────────────────────────────────
var _player: Node3D = null

var _base_hum_player: AudioStreamPlayer
var _bed_player_a: AudioStreamPlayer
var _bed_player_b: AudioStreamPlayer
var _active_bed_player: AudioStreamPlayer   # whichever of a/b is currently "front"
var _bed_tween: Tween = null

var _one_shot_player: AudioStreamPlayer
var _one_shot_timer: Timer

var _occupied_zones: Array[AmbienceZone] = []   # stack of zones player is currently inside
var _current_zone: AmbienceZone = null          # winner of the priority stack, or null

# ── Setup ─────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_base_hum_player = AudioStreamPlayer.new()
	_base_hum_player.volume_db = BASE_HUM_VOLUME_DB
	add_child(_base_hum_player)

	_bed_player_a = AudioStreamPlayer.new()
	_bed_player_b = AudioStreamPlayer.new()
	add_child(_bed_player_a)
	add_child(_bed_player_b)
	_active_bed_player = _bed_player_a

	_one_shot_player = AudioStreamPlayer.new()
	_one_shot_player.volume_db = DEFAULT_ONE_SHOT_VOLUME_DB
	add_child(_one_shot_player)

	_one_shot_timer = Timer.new()
	_one_shot_timer.one_shot = true
	_one_shot_timer.timeout.connect(_on_one_shot_timer)
	add_child(_one_shot_timer)
	_schedule_next_one_shot()

func register_player(player: Node3D) -> void:
	_player = player

func start_base_hum() -> void:
	if not ResourceLoader.exists(BASE_HUM_STREAM):
		push_warning("AmbienceManager: base hum stream missing at '%s'" % BASE_HUM_STREAM)
		return
	var stream: AudioStream = load(BASE_HUM_STREAM)
	if stream is AudioStreamOggVorbis or stream is AudioStreamWAV:
		stream.loop = true
	_base_hum_player.stream = stream
	_base_hum_player.play()

# ── Zone tracking ──────────────────────────────────────────────────────────────

func notify_zone_entered(zone: AmbienceZone, body: Node3D) -> void:
	if _player != null and body != _player:
		return
	if not _occupied_zones.has(zone):
		_occupied_zones.append(zone)
	_recompute_active_zone()

func notify_zone_exited(zone: AmbienceZone, body: Node3D) -> void:
	if _player != null and body != _player:
		return
	_occupied_zones.erase(zone)
	_recompute_active_zone()

## Highest priority zone in the occupied stack wins. Among equal priorities,
## the most recently entered one (last in the array) wins, so stepping into
## a room "overrides" a hallway zone you're still technically standing in
## the edge of.
func _recompute_active_zone() -> void:
	var winner: AmbienceZone = null
	for zone in _occupied_zones:
		if winner == null or zone.priority >= winner.priority:
			winner = zone

	if winner == _current_zone:
		return

	_current_zone = winner
	_crossfade_to_zone(winner)

# ── Bed crossfading ────────────────────────────────────────────────────────────

func _crossfade_to_zone(zone: AmbienceZone) -> void:
	if _bed_tween and _bed_tween.is_running():
		_bed_tween.kill()

	var incoming: AudioStreamPlayer = _bed_player_b if _active_bed_player == _bed_player_a else _bed_player_a
	var outgoing: AudioStreamPlayer = _active_bed_player

	var target_stream: AudioStream = zone.bed_stream if zone != null else null
	var target_volume: float = zone.bed_volume_db if zone != null else BASE_HUM_VOLUME_DB

	if target_stream == null:
		# No bed for this zone (or no zone at all) — just fade the current
		# bed out and leave it silent; base hum keeps the room from feeling dead.
		_bed_tween = create_tween()
		_bed_tween.tween_property(outgoing, "volume_db", -60.0, BED_CROSSFADE_TIME)
		_bed_tween.finished.connect(func(): outgoing.stop(), CONNECT_ONE_SHOT)
		return

	if target_stream is AudioStreamOggVorbis or target_stream is AudioStreamWAV:
		target_stream.loop = true

	incoming.stream = target_stream
	incoming.volume_db = -60.0
	incoming.play()

	_bed_tween = create_tween()
	_bed_tween.set_parallel(true)
	_bed_tween.tween_property(incoming, "volume_db", target_volume, BED_CROSSFADE_TIME)
	_bed_tween.tween_property(outgoing, "volume_db", -60.0, BED_CROSSFADE_TIME)
	_bed_tween.finished.connect(func(): outgoing.stop(), CONNECT_ONE_SHOT)

	_active_bed_player = incoming

# ── Random one-shots ───────────────────────────────────────────────────────────

func _schedule_next_one_shot() -> void:
	var lo: float = DEFAULT_ONE_SHOT_INTERVAL_MIN
	var hi: float = DEFAULT_ONE_SHOT_INTERVAL_MAX
	if _current_zone != null:
		lo = _current_zone.one_shot_interval_min
		hi = _current_zone.one_shot_interval_max
	_one_shot_timer.start(randf_range(lo, hi))

func _on_one_shot_timer() -> void:
	_play_random_one_shot()
	_schedule_next_one_shot()

func _play_random_one_shot() -> void:
	var pool: Array = []
	if _current_zone != null and not _current_zone.one_shot_pool.is_empty():
		pool = _current_zone.one_shot_pool
	else:
		for path in DEFAULT_ONE_SHOTS:
			if ResourceLoader.exists(path):
				pool.append(load(path))

	if pool.is_empty():
		return

	var stream: AudioStream = pool[randi() % pool.size()]
	if stream == null:
		return

	_one_shot_player.stream = stream
	_one_shot_player.pitch_scale = 1.0 + randf_range(-0.05, 0.05)
	_one_shot_player.play()
