# CallDatabase.gd
# Add to Project Settings → Autoload as "CallDatabase".
#
# ── ENTRY SHAPE ───────────────────────────────────────────────────────────────
# {
#   "id":                 int,
#   "day":                int,            # Which day of the week this call
#                                         # appears on (1–5).
#   "caller_name":        String,
#   "caller_photo":       String,         # res:// path or "" for placeholder.
#   "duration":           float,
#   "audio":              String,         # res:// path or "".
#   "transcription":      String,
#   "additional_details": String,
#   "tasks":              Array,
#   "correct_anomaly_id": int,
#   "icon_direction":     Vector3,
#
#   "theme_tags":         Array[String],  # Tags used by WeekDatabase to build
#                                         # the random call pool. A call is
#                                         # eligible for a week if it shares at
#                                         # least one tag with that week's
#                                         # theme_tags.
#                                         # Use [] for calls that should only
#                                         # appear via required_call_ids.
#
#   "exclusive_to_week":  String,         # If set, this call ONLY appears
#                                         # during that specific week.
#                                         # "" means eligible for any week
#                                         # whose theme_tags match.
#                                         # Note: training week ID is "training".
# }
#
# ── NOTE ON TRAINING WEEK ─────────────────────────────────────────────────────
# WeekDatabase.TRAINING_WEEK_ID should be "training" (not "").
# Update that constant in WeekDatabase.gd to match.

extends Node

const NOT_FOUND     := "NOT_FOUND"
const NO_MORE_CALLS := "NO_MORE_CALLS"

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
			+ "In the corner, you should be able to see your tasks. Most of the time, they will be empty. "
			+ "Please designate this report as any anomaly you want.",
		"additional_details":
			"P.S designate this as a Complaint for a reward!",
		"correct_anomaly_id": 16,
		"tasks": [
			"Read the transcript.",
		],
		"icon_direction":     Vector3(0.0, 1.0, 0.0),
		"theme_tags":         [],
		"exclusive_to_week":  "training",
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
			+ "Since you've been gone though, management has implemented new technology (like me!!!) and rules."
			+ "Sadly, one of those rules are the mandatory retraining of all personnel who have been gone over 4 months."
			+ "Luckily, that means this will be a very chill week for you! Isn't that great!",
		"additional_details": "How was the trip?",
		"correct_anomaly_id": 16,
		"tasks": [
			"Enjoy your time back.",
		],
		"icon_direction":     Vector3(0.86, -0.49, -0.14),
		"theme_tags":         [],
		"exclusive_to_week":  "training",
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
			+ " We'll start with someone simple. The Assistant General!",
		"additional_details": "He's a chill dude.",
		"correct_anomaly_id": 13,
		"tasks": [
			"Submit as Complaint.",
		],
		"icon_direction":     Vector3(0.86, -0.49, -0.14),
		"theme_tags":         [],
		"exclusive_to_week":  "training",
	},

	# ── Add new calls below ───────────────────────────────────────────────────
	# Training week calls: exclusive_to_week = "training", theme_tags = []
	#
	# General pool calls (eligible for any matching week):
	#   exclusive_to_week = ""
	#   theme_tags = ["geological", "medical", ...] etc.
	#
	# Week-exclusive calls:
	#   exclusive_to_week = "week_id"
	#   theme_tags = []   (pool draw is skipped; use required_call_ids instead,
	#                      OR let the pool draw pick them up via exclusive match)
	#
	# Template:
	# {
	#     "id":                 4,
	#     "day":                1,
	#     "caller_name":        "...",
	#     "caller_photo":       "",
	#     "duration":           60.0,
	#     "audio":              "",
	#     "transcription":      "...",
	#     "additional_details": "...",
	#     "correct_anomaly_id": -1,
	#     "tasks":              [],
	#     "icon_direction":     Vector3(0.0, 1.0, 0.0),
	#     "theme_tags":         ["geological"],
	#     "exclusive_to_week":  "",
	# },
]


# ── Filtering helpers ─────────────────────────────────────────────────────────

## Returns true if this call is eligible to appear during the given week.
## A call is eligible when:
##   - exclusive_to_week is "" (open pool) OR matches week_id exactly.
func _is_call_eligible(call: Dictionary, week_id: String) -> bool:
	var exclusive: String = call.get("exclusive_to_week", "")
	return exclusive == "" or exclusive == week_id


## Returns true if this call shares at least one tag with the given list.
## Calls with no theme_tags are only reachable via required_call_ids.
func _matches_tags(call: Dictionary, tags: Array) -> bool:
	for tag in call.get("theme_tags", []):
		if tags.has(tag):
			return true
	return false


# ── Public API ────────────────────────────────────────────────────────────────

## Returns all calls assigned to a specific day that are eligible for the
## current week. Used by GameState to know how many calls remain today.
func get_calls_for_day(day: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var week_id := GameState.current_week_id
	for entry in entries:
		if entry.get("day", 1) == day and _is_call_eligible(entry, week_id):
			result.append(entry)
	return result


## Builds the random-draw eligible pool for a given week, day, and tag list.
## Excludes call IDs already earmarked as required so they aren't double-added.
## Called by WeekDatabase.draw_calls_for_day() once that is fully implemented.
func get_pool_for_week_day(week_id: String, day: int,
		theme_tags: Array, exclude_ids: Array[int]) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for entry in entries:
		if entry.get("day", 1) != day:
			continue
		if exclude_ids.has(entry["id"]):
			continue
		if not _is_call_eligible(entry, week_id):
			continue
		# Eligible if tags overlap OR the call is exclusive to this week
		# (exclusive calls can have empty theme_tags and still be drawn).
		var is_exclusive := entry.get("exclusive_to_week", "") == week_id
		if is_exclusive or _matches_tags(entry, theme_tags):
			pool.append(entry)
	return pool


## Returns the next call in the global queue (used by the F5 / F1 debug keys).
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


## Fetch a specific call by id regardless of queue or week state.
func get_call(id: int) -> Dictionary:
	for entry in entries:
		if entry["id"] == id:
			return entry
	return {"status": NOT_FOUND}
