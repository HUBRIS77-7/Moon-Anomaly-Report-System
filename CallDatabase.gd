# CallDatabase.gd
# Add to Project Settings → Autoload as "CallDatabase".
#
# Each entry shape:
# {
#   "id":                 int,
#   "caller_name":        String,
#   "caller_photo":       String,   # res:// path or "" for no photo
#   "duration":           float,    # call length in seconds
#   "audio":              String,   # res:// path to AudioStream or ""
#   "transcription":      String,
#   "additional_details": String,
#   "tasks":              Array,    # Array[String]
# }

extends Node

const NOT_FOUND := "NOT_FOUND"
const NO_MORE_CALLS := "NO_MORE_CALLS"

# Tracks which index in `entries` to dispatch next.
var _queue_index: int = 0

var entries: Array[Dictionary] = [
	{
		"id":                 1,
		"caller_name":        "Station 7 — Cmdr. Reyes",
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
	},
	{
		"id":                 2,
		"caller_name":        "Medical Bay — Nurse Okoro",
		"caller_photo":       "",
		"duration":           40.0,
		"audio":              "",
		"transcription":
			"We have a crew member reporting chest pains after EVA. "
			+ "Suit logs show a micro-tear repaired mid-walk. Duration was 90 minutes.",
		"additional_details": "Possible regolith exposure. Check suit log ref #A-441.",
		 "correct_anomaly_id": 1, 
		"tasks": [
			"Confirm EVA suit was flagged in the equipment log",
			"Ask how long symptoms have been present",
		],
	},
	# ── Add new calls below. Give each a unique id. ───────────────────────────
]


## Returns the next call in sequence and advances the queue.
## Returns {"status": NO_MORE_CALLS} when all calls have been dispatched.
func next_call() -> Dictionary:
	if _queue_index >= entries.size():
		return {"status": NO_MORE_CALLS}
	var entry := entries[_queue_index]
	_queue_index += 1
	return entry


## Returns true if there are still calls waiting to be dispatched.
func has_next_call() -> bool:
	return _queue_index < entries.size()


## Resets the queue back to the first call.
## Useful for restarting a shift or debug resets.
func reset_queue() -> void:
	_queue_index = 0


## Fetch a specific call by id regardless of queue state.
## Useful for moon-icon triggered calls and debug lookups.
func get_call(id: int) -> Dictionary:
	for entry in entries:
		if entry["id"] == id:
			return entry
	return {"status": NOT_FOUND}
