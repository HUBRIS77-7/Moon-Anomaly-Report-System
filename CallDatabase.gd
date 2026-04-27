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
		"caller_name":        "LUNA!!!!",
		"caller_photo":       "res://ICONS/Maxwell.jpg",
		"duration":           55.0,
		"audio":              "",
		"transcription":
			"Hello! This is LUNA. Thanks for showcasing your ability to navigate the Lunar Communications Model! "
			+ "This personal terminal is yours to customize and decorate, but we advise you not to store anything particularly personal on here. "
			+ "In the corner, you should be able to see your tasks. Most of the tie, they will be empty. "
			+ "Please designate this report as any anomaly you want.",
		"additional_details":
			"P.S designate this as a Complaint for a reward!",
		"correct_anomaly_id": 16,
		"tasks": [
			"Read the transcript.",
		],
		"icon_direction": Vector3(0.0, 1.0, 0.0),
	},
	{
		"id":                 2,
		"day":                1,
		"caller_name":        "LUNA!!!!",
		"caller_photo":       "",
		"duration":           40.0,
		"audio":              "",
		"transcription":
			"I see that you just returned from a vacation to the Venusian Paradise resort on... well, Venus."
			+ "Since you've been gone though, manageent has implemented new technology (like me!!!) and rules."
			+ "Sadly, one of those rules are the mandatory retraining of all personnel who have been gone over 4 months"
			+ "Luckily, that means this will be a very chill week for you! Isn't that great!",
		"additional_details": "How was the trip?",
		"correct_anomaly_id": 16,
		"tasks": [
			"Enjoy your time back.",
		],
		"icon_direction": Vector3(0.86, -0.49, -0.14),
	},
	{
		"id":                 3,
		"day":                2,
		"caller_name":        "LUNA!!!!",
		"caller_photo":       "",
		"duration":           40.0,
		"audio":              "",
		"transcription":
			"As a part of your retraining, I have to patch your terminal back into the Departmental call lines of the Central Lunar Station."
			+ " We'll start with someone simple. The Assistent General!",
		"additional_details": "He's a chill dude.",
		"correct_anomaly_id": 13,
		"tasks": [
			"Submit as Complaint.",
		],
		"icon_direction": Vector3(0.86, -0.49, -0.14),
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
