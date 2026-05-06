# WeekDatabase.gd
# Add to Project Settings → Autoload as "WeekDatabase".
# Place AFTER GameState, AnomalyDatabase, and CallDatabase in the autoload list.
#
# ── WEEK FORMAT ───────────────────────────────────────────────────────────────
# {
#   "id":                  String,         # Unique week identifier.
#                                          # Matches "exclusive_to_week" in
#                                          # AnomalyDatabase and CallDatabase.
#                                          # Use "" for the training week.
#
#   "name":                String,         # Display name on the selection screen.
#
#   "flavour":             String,         # Short description shown on the
#                                          # selection screen card.
#
#   "theme_tags":          Array[String],  # Tags used to draw random calls from
#                                          # CallDatabase. A call is eligible if
#                                          # it shares at least one tag.
#                                          # (Tags will be added to CallDatabase
#                                          # in a later pass.)
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
# It always includes required_call_ids first, then fills remaining slots
# randomly from the eligible pool.
#
# NOTE: draw_calls_for_day() is stubbed until CallDatabase gains theme_tags.

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
	# Each needs a unique id and exactly 3 leads_to entries.
	# Pool size should be at least double (calls_per_day * 5) for good variation.

	# Template:
	# {
	# 	"id":                    "your_week_id",
	# 	"name":                  "Week Name",
	# 	"flavour":               "One or two sentences. Eerie is good.",
	# 	"theme_tags":            ["tag_a", "tag_b"],
	# 	"calls_per_day":         3,
	# 	"required_call_ids":     [],
	# 	"leads_to":              ["week_id_1", "week_id_2", "week_id_3"],
	# 	"has_exclusive_content": false,
	# },

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

	# Deeper / rarer weeks — only reachable from specific predecessors.
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
## Pushes a warning for any leads_to ID not found in the database.
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
## Required calls are always included. Remaining slots are filled randomly
## from the eligible pool.
##
## TODO: fully implement once CallDatabase gains "theme_tags" and
##       "exclusive_to_week" fields. The stub below returns only required
##       calls so existing behaviour is not broken in the meantime.
func draw_calls_for_day(week_id: String, day: int) -> Array[Dictionary]:
	var week := get_week(week_id)
	if week.is_empty():
		push_error("WeekDatabase: cannot draw calls — week '%s' not found." % week_id)
		return []

	var result: Array[Dictionary] = []

	# ── Required calls ────────────────────────────────────────────────────────
	for call_id: int in week.get("required_call_ids", []):
		var call := CallDatabase.get_call(call_id)
		if not call.has("status"):
			result.append(call)

	# ── TODO: random pool draw ────────────────────────────────────────────────
	# Once CallDatabase entries have "theme_tags" and "exclusive_to_week":
	#
	# 1. Build the eligible pool:
	#    - entry shares at least one tag with week["theme_tags"]  OR
	#      entry["exclusive_to_week"] == week_id
	#    - entry["exclusive_to_week"] is "" or matches week_id
	#    - entry["day"] == day
	#    - entry id is NOT already in result
	#
	# 2. Shuffle the pool.
	#
	# 3. Fill up to calls_per_day total slots from the shuffled pool.
	#
	# var calls_needed := week.get("calls_per_day", 3) - result.size()
	# var pool := _build_pool(week_id, week["theme_tags"], day, result)
	# pool.shuffle()
	# for i in range(mini(calls_needed, pool.size())):
	#     result.append(pool[i])

	return result


## Returns all week IDs currently registered.
func get_all_ids() -> Array[String]:
	var ids: Array[String] = []
	for week in weeks:
		ids.append(week["id"])
	return ids
