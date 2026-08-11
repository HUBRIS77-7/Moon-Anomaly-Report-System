# TaskDatabase.gd
# Add to Project Settings → Autoload as "TaskDatabase". Order relative to
# other autoloads doesn't matter — `tasks` is a plain array assigned at
# declaration, not built in _ready(), so it's valid the instant the node exists.
#
# ── TASK FORMAT ───────────────────────────────────────────────────────────────
# {
#   "id":          String,   # unique id. Whatever completes this task — an
#                            # Area3D trigger, an interact-prop, a dialog
#                            # choice, a terminal app button — calls
#                            # GameState.complete_task(id) with this string.
#   "week_id":     String,   # "" = matches ANY week. Otherwise must equal
#                            # GameState.current_week_id exactly.
#                            # Use "training" for the training week.
#   "day":         int,      # day within that week this task appears on
#   "title":       String,   # short label — objective viewer header line
#   "description": String,   # longer body text
# }
#
# Only ONE task fires per day (first match for week_id + day wins — keep it
# simple for now; a queue/array-of-tasks-per-day is a natural future
# extension if a day ever needs more than one).
# If a day has no matching entry, that day ends normally, ungated, exactly
# like before this system existed.

extends Node

var tasks: Array[Dictionary] = [
	# Example — delete/replace once you have real content:
	 {
	 	"id":          "TEST",
	 	"week_id":     "training",
	 	"day":         1,
	 	"title":       "Check the life support vent",
	 	"description": "LUNA wants you to inspect the vent in your quarters before logging off tonight.",
	 },
]

## Returns the first task matching week_id + day, or {} if none.
## An entry with week_id == "" matches any week.
func get_task_for_day(week_id: String, day: int) -> Dictionary:
	for task in tasks:
		if task.get("day", -1) != day:
			continue
		var task_week: String = task.get("week_id", "")
		if task_week == "" or task_week == week_id:
			return task
	return {}

## Fetch a task by id regardless of day/week — used by ObjectiveViewer to
## look up display text once GameState tells it a task_id is active.
func get_task(id: String) -> Dictionary:
	for task in tasks:
		if task.get("id", "") == id:
			return task
	return {}
