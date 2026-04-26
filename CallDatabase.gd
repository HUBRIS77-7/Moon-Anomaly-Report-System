# CallDatabase.gd
# Add to Project Settings → Autoload as "CallDatabase".
#
# Each entry shape:
# {
#   "id":                 int,
#   "day":                int,          # Which day this call appears on (1–5)
#   "caller_name":        String,
#   "caller_photo":       String,
#   "duration":           float,
#   "audio":              String,
#   "transcription":      String,
#   "additional_details": String,
#   "tasks":              Array,
#   "correct_anomaly_id": int,
#   "icon_direction":     Vector3,
# }

extends Node

const NOT_FOUND     := "NOT_FOUND"
const NO_MORE_CALLS := "NO_MORE_CALLS"

# Tracks which index in `entries` to dispatch next (used by the F5 debug key).
var _queue_index: int = 0

var entries: Array[Dictionary] = [
	{
		"id":                 1,
		"day":                1,
		"caller_name":        "Polar Station 07 — Cmdr. Reyes",
		"caller_photo":       "res://ICONS/Maxwell.jpg",
		"duration":           55.0,
		"audio":              "",
		"transcription":
			"Yes, hello, this is Commander Reyes from Station Seven. "
			+ "We've had repeating seismic readings since 04:00 Lunar Hours. "
			+ "Small tremors, every three minutes. Two fuel lines are vibrating. "
			+ "Our geologist says it feels different from a normal Luna Shake.",
		"additional_details":
			"Station 7 sits 2 km from the Kepler Ridge fault zone. "
			+ "Fixed-interval seismic activity may indicate an artificial source.",
		"correct_anomaly_id": 13,
		"tasks": [
			"Ask if Volatile Regolith warnings are active nearby",
			"Check Satellite Database for recent orbital changes",
			"Confirm drill shutdown has been logged with Industrial",
		],
		"icon_direction": Vector3(0.0, 1.0, 0.0),
	},
	{
		"id":                 2,
		"day":                1,
		"caller_name":        "Medical Bay, Central Lunar Station — Nurse Okoro",
		"caller_photo":       "",
		"duration":           40.0,
		"audio":              "",
		"transcription":
			"We have a crew member reporting chest pains after EVA. "
			+ "Suit logs show a micro-tear repaired mid-walk. Duration was 90 minutes.",
		"additional_details": "Possible regolith exposure. Check suit log ref #A-441.",
		"correct_anomaly_id": 10,
		"tasks": [
			"Confirm EVA suit was flagged in the equipment log",
			"Ask how long symptoms have been present",
		],
		"icon_direction": Vector3(1.0, 0.2, 0.0),
	},
{
	"id":                 3,
	"day":                2,
	"caller_name":        "Mining Sector B — Foreman Vasquez",
	"caller_photo":       "",
	"duration":           50.0,
	"audio":              "",
	"transcription":      "...",
	"additional_details": "...",
	"correct_anomaly_id": 3,
	"tasks":              ["Check sector evacuation log"],
	"icon_direction":     Vector3(-0.6, 0.5, 0.4),
},
	# ── Add new calls below. Give each a unique id and assign a day (1–5). ───
	# Template:
	# {
	#     "id":                 3,
	#     "day":                2,
	#     "caller_name":        "...",
	#     "caller_photo":       "",
	#     "duration":           60.0,
	#     "audio":              "",
	#     "transcription":      "...",
	#     "additional_details": "...",
	#     "correct_anomaly_id": -1,
	#     "tasks":              [],
	#     "icon_direction":     Vector3(-0.6, 0.5, 0.6),
	# },
]


## Returns all calls assigned to a specific day number.
func get_calls_for_day(day: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in entries:
		if entry.get("day", 1) == day:
			result.append(entry)
	return result


## Returns the next call in the global queue (used by the F5 debug key).
## Returns {"status": NO_MORE_CALLS} when exhausted.
func next_call() -> Dictionary:
	if _queue_index >= entries.size():
		return {"status": NO_MORE_CALLS}
	var entry := entries[_queue_index]
	_queue_index += 1
	return entry


## True if there are still calls waiting in the global queue.
func has_next_call() -> bool:
	return _queue_index < entries.size()


## Resets the global queue back to the first call.
func reset_queue() -> void:
	_queue_index = 0


## Fetch a specific call by id regardless of queue state.
func get_call(id: int) -> Dictionary:
	for entry in entries:
		if entry["id"] == id:
			return entry
	return {"status": NOT_FOUND}
