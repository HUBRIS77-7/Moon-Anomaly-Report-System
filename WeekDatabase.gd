# WeekDatabase.gd
# Add to Project Settings → Autoload as "WeekDatabase".
# Place AFTER GameState, AnomalyDatabase, and CallDatabase in the autoload list.
#
# ── WEEK FORMAT ───────────────────────────────────────────────────────────────
# {
#   "id":                  String,         # Unique week identifier.
#                                          # Matches "exclusive_to_week" in
#                                          # AnomalyDatabase and CallDatabase.
#                                          # Use "training" for the training week.
#
#   "name":                String,         # Display name on the selection screen.
#
#   "flavour":             String,         # Short description shown on the
#                                          # selection screen card.
#
#   "theme_tags":          Array[String],  # Tags used to draw random calls from
#                                          # CallDatabase. A call is eligible if
#                                          # it shares at least one tag.
#
#   "calls_per_day":       int,            # How many calls to schedule per day.
#
#   "required_call_ids":   Array[int],     # Call IDs that ALWAYS appear,
#                                          # regardless of the random draw.
#                                          # Use for story beats.
#
#   "leads_to":            Array[String],  # Exactly 3 week IDs offered as
#                                          # options after this week ends.
#
#   "has_exclusive_content": bool,         # Whether to show the "unique incidents"
#                                          # hint on the selection screen card.
# }
#
# ── CALL DRAWING ──────────────────────────────────────────────────────────────
# draw_calls_for_day() builds each day's call list.
# Priority order:
#   1. Required calls (required_call_ids) that match the requested day.
#   2. Random draw from the eligible pool to fill remaining slots up to
#      calls_per_day. A call is eligible when:
#        - Its day field matches.
#        - It is not already in the required list.
#        - exclusive_to_week is "" or matches this week's id.
#        - It shares at least one tag with the week's theme_tags, OR
#          exclusive_to_week matches (exclusive calls skip the tag check).

extends Node

const TRAINING_WEEK_ID := "training"

var weeks: Array[Dictionary] = [

	# ── TRAINING WEEK ─────────────────────────────────────────────────────────
	# Hardcoded — never appears on the selection screen.
	{
		"id":                    "training",
		"name":                  "Retraining Week",
		"flavour":               "LUNA guides you back through the basics. Nothing too serious.",
		"theme_tags":            ["general", "complaint"],
		"calls_per_day":         3,
		"required_call_ids":     [1, 2, 3],
		"leads_to":              ["geological_unrest", "biological_bloom", "security_lockdown"],
		"has_exclusive_content": false,
	},

	# ── REAL WEEKS ────────────────────────────────────────────────────────────

	{
		"id":                    "geological_unrest",
		"name":                  "Geological Unrest",
		"flavour":               "Tremors are being reported across three sectors. The ground itself seems restless this week.",
		"theme_tags":            ["geological", "industrial", "general"],
		"calls_per_day":         3,
		"required_call_ids":     [],
		"leads_to":              ["biological_bloom", "security_lockdown", "deep_excavation"],
		"has_exclusive_content": false,
	},

	{
		"id":                    "biological_bloom",
		"name":                  "Biological Bloom",
		"flavour":               "Something is growing in the lower sectors. Maintenance says it started last Tuesday.",
		"theme_tags":            ["biological", "medical", "general"],
		"calls_per_day":         3,
		"required_call_ids":     [],
		"leads_to":              ["geological_unrest", "security_lockdown", "containment_protocol"],
		"has_exclusive_content": false,
	},

	{
		"id":                    "security_lockdown",
		"name":                  "Security Lockdown",
		"flavour":               "Access restrictions are tightening. Nobody seems to know who authorised it.",
		"theme_tags":            ["security", "general", "industrial"],
		"calls_per_day":         3,
		"required_call_ids":     [],
		"leads_to":              ["geological_unrest", "biological_bloom", "signal_interference"],
		"has_exclusive_content": false,
	},

	{
		"id":                    "deep_excavation",
		"name":                  "Deep Excavation",
		"flavour":               "Mining teams have breached a previously uncharted subsurface cavity. Reports are sparse.",
		"theme_tags":            ["geological", "industrial", "scientific", "anomalous"],
		"calls_per_day":         3,
		"required_call_ids":     [],
		"leads_to":              ["biological_bloom", "signal_interference", "containment_protocol"],
		"has_exclusive_content": true,
	},

	{
		"id":                    "containment_protocol",
		"name":                  "Containment Protocol",
		"flavour":               "A level-3 biological containment order has been issued. Half the database is redacted.",
		"theme_tags":            ["biological", "security", "medical", "anomalous"],
		"calls_per_day":         3,
		"required_call_ids":     [],
		"leads_to":              ["geological_unrest", "deep_excavation", "signal_interference"],
		"has_exclusive_content": true,
	},

	{
		"id":                    "signal_interference",
		"name":                  "Signal Interference",
		"flavour":               "Comms have been degraded across the board. Some callers sound like they are very far away.",
		"theme_tags":            ["scientific", "general", "anomalous"],
		"calls_per_day":         3,
		"required_call_ids":     [],
		"leads_to":              ["geological_unrest", "biological_bloom", "deep_excavation"],
		"has_exclusive_content": true,
	},
]


# ── Public API ────────────────────────────────────────────────────────────────

## Returns a week dictionary by ID. Returns {} if not found.
func get_week(id: String) -> Dictionary:
	for week in weeks:
		if week["id"] == id:
			return week
	return {}


## Returns the three week dictionaries offered after the given week ends.
func get_options_after(week_id: String) -> Array[Dictionary]:
	var current := get_week(week_id)
	if current.is_empty():
		push_error("WeekDatabase: week '%s' not found." % week_id)
		return []

	var result: Array[Dictionary] = []
	for next_id: String in current.get("leads_to", []):
		var next := get_week(next_id)
		if next.is_empty():
			push_warning("WeekDatabase: leads_to contains unknown id '%s'." % next_id)
			continue
		result.append(next)

	return result


## Builds the call list for a given week and day.
##
## Priority:
##   1. required_call_ids entries whose "day" field matches this day.
##   2. Random pool draw to fill remaining slots up to calls_per_day.
##      A call is pool-eligible when:
##        - Its day field matches.
##        - It is not already included via required_call_ids.
##        - exclusive_to_week is "" or matches week_id.
##        - It shares at least one tag with the week's theme_tags, OR
##          it is exclusive to this week (tag check is skipped for exclusives).
func draw_calls_for_day(week_id: String, day: int) -> Array[Dictionary]:
	var week := get_week(week_id)
	if week.is_empty():
		push_error("WeekDatabase: cannot draw calls — week '%s' not found." % week_id)
		return []

	var result:     Array[Dictionary] = []
	var result_ids: Array[int]        = []

	# ── 1. Required calls ─────────────────────────────────────────────────────
	for call_id: int in week.get("required_call_ids", []):
		var call := CallDatabase.get_call(call_id)
		if call.has("status"):
			push_warning("WeekDatabase: required call #%d not found in CallDatabase." % call_id)
			continue
		if call.get("day", 1) != day:
			continue  # This required call belongs to a different day.
		result.append(call)
		result_ids.append(call_id)

	# ── 2. Random pool draw ───────────────────────────────────────────────────
	var calls_needed: int = week.get("calls_per_day", 3) - result.size()
	if calls_needed > 0:
		var theme_tags: Array = week.get("theme_tags", [])
		var pool := CallDatabase.get_pool_for_week_day(week_id, day, theme_tags, result_ids)
		pool.shuffle()
		for i in range(mini(calls_needed, pool.size())):
			result.append(pool[i])

	return result


## Returns all week IDs currently registered.
func get_all_ids() -> Array[String]:
	var ids: Array[String] = []
	for week in weeks:
		ids.append(week["id"])
	return ids
