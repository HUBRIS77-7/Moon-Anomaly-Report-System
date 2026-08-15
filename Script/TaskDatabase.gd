# TaskDatabase.gd
# Add to Project Settings → Autoload as "TaskDatabase".
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
#   "timing":      String,   # "day_start" or "day_end". Defaults to "day_end"
#                            # if omitted, so pre-existing tasks are unaffected.
#                            #   "day_start" — assigned as soon as the day
#                            #     begins; call icons on the moon won't spawn
#                            #     until it's completed.
#                            #   "day_end"   — assigned once all of that day's
#                            #     calls are handled; day_ended (and the
#                            #     Day End screen) is held back until complete.
#   "title":       String,   # short label — objective viewer header line
#   "description": String,   # longer body text
# }
#
# Only ONE task fires per (week, day, timing) combo — first match wins.
# If a day has no matching entry for a given timing, that gate is a no-op,
# exactly like before this system existed.

extends Node

const TIMING_DAY_START := "day_start"
const TIMING_DAY_END   := "day_end"

var tasks: Array[Dictionary] = [
	# Example — delete/replace once you have real content:
	 {
	 	"id":          "MORNING_CHECKIN",
	 	"week_id":     "",
	 	"day":         1,
	 	"timing":      TaskDatabase.TIMING_DAY_START,
	 	"title":       "Log in at your terminal",
	 	"description": "Sit down and confirm you're ready before calls start coming in.",
	 },

	# Day-start example — call icons won't appear until this is completed:

]

## Returns the first task matching week_id + day + timing, or {} if none.
## An entry with week_id == "" matches any week. Entries without a "timing"
## key are treated as "day_end" for backwards compatibility.
func get_task_for_day(week_id: String, day: int, timing: String = TIMING_DAY_END) -> Dictionary:
	for task in tasks:
		if task.get("day", -1) != day:
			continue
		if task.get("timing", TIMING_DAY_END) != timing:
			continue
		var task_week: String = task.get("week_id", "")
		if task_week == "" or task_week == week_id:
			return task
	return {}

## Convenience wrapper for the common cases.
func get_start_task_for_day(week_id: String, day: int) -> Dictionary:
	return get_task_for_day(week_id, day, TIMING_DAY_START)

func get_end_task_for_day(week_id: String, day: int) -> Dictionary:
	return get_task_for_day(week_id, day, TIMING_DAY_END)

## Fetch a task by id regardless of day/week/timing — used by ObjectiveViewer
## to look up display text once GameState tells it a task_id is active.
func get_task(id: String) -> Dictionary:
	for task in tasks:
		if task.get("id", "") == id:
			return task
	return {}
