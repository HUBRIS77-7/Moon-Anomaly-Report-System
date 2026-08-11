# AmbienceZone.gd
# Attach to an Area3D placed around a room's floor space.
# collision_layer = 0, collision_mask = 1 (matches PlayerController's CharacterBody3D)
# so it only reacts to the player, not props or other bodies.

extends Area3D
class_name AmbienceZone

## Unique-ish label, mostly for debugging — not required to be globally unique.
@export var zone_id: String = ""

## Looping bed for this room. Leave null to just silence the previous zone's
## bed while inside (e.g. a deliberately "dead" room like the Observatory).
@export var bed_stream: AudioStream

@export var bed_volume_db: float = -10.0

## One-shots specific to this room (fridge hum, wall creak, machinery clank).
## Leave empty to fall back to AmbienceManager's DEFAULT_ONE_SHOTS.
@export var one_shot_pool: Array[AudioStream] = []

@export var one_shot_interval_min: float = 8.0
@export var one_shot_interval_max: float = 22.0

## When zones overlap, the highest zone_priority currently-occupied zone wins.
## Ties fall back to whichever was entered last.
@export var zone_priority: int = 0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		AmbienceManager.notify_zone_entered(self, body)

func _on_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D:
		AmbienceManager.notify_zone_exited(self, body)
