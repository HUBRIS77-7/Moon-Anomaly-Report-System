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
			"Welcome to the updated Call Resolution Application or CRA, and by extenstion your Terminal for Education or Recreation (TER for short)! "
			+ "This terminal is yours to use, customize, and decorate. We advise that you don't keep anything too personal on these computers though, as they are scanned weekly."
			+ "For most calls, you will listen to the call that you selected, diagnose the anomaly at hand, and submit the report back to the caller and required authorities. "
			+ "To make sure your install of CRA is working, please report this call as a complaint!",
		"additional_details":
			"This section will contain additional details about the caller's location, station, status, and such! ",
		"correct_anomaly_id": 16,
		"tasks": [
			"Occasionally, a call will require you to use a different application, but none of those are installed right now.",
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
			"Today, I'm going to treat you to some testing calls. Just to see where you stand on your memory."
			+ "You might've noticed that you do not have access to all the known anomalies right now. This is because another side-effect of being gone for so long is that your accrediation was paused,"
			+ "Don't worry, once your re-training is complete, your accredation will be restored. Mark this call as a Complaint,",
		"additional_details": "(ツ)",
		"correct_anomaly_id": 16,
		"tasks": [
			"Additionally, calls cannot be submitted until you mark tasks as complete",
		],
		"icon_direction":     Vector3(0.86, -0.49, -0.14),
		"theme_tags":         [],
		"exclusive_to_week":  "training",
	},
	{
		"id":                 3,
		"day":                1,
		"caller_name":        "LUNA?",
		"caller_photo":       "",
		"duration":           60.0,
		"audio":              "",
		"transcription":      "Hello, It is Me, Human-1. I am attempting to open the door to my workplace, but the keycard isn't working... *beep* It's not an issue with the keycard, it's perfectly flat. Is something wrong with the card? I really got to get to work.",
		"additional_details": "Human-1 has been fired from their place of employment, and their card terminated.",
		"correct_anomaly_id": 1,
		"tasks":              [],
		"icon_direction": Vector3(0.398, 0.012, 0.917),
		"theme_tags":         ["geological"],
		"exclusive_to_week":  "",
	},
{
		"id":                 4,
		"day":                1,
		"caller_name":        "LUNA?",
		"caller_photo":       "",
		"duration":           40.0,
		"audio":              "",
		"transcription": "*cough* Uh, hello? Is this the M.A.R.S *chuckle* Look, I had a bit of a *cough* mix-up earlier, and I think I may have breathed something in that I wasn’t supposed to. I was… uh… taking out some trash when I accidentally opened up the vacuum side door while I was still inside. I managed to get back inside and repressurize, but now my chest hurts and I haven’t been able to move much.",
		"additional_details": "Biological Disposal Station 13 reported 1.3 mg of regolith in their air filtration system 2 hours ago.",
		"correct_anomaly_id": 10,
		"tasks": [],
		"icon_direction":     Vector3(0.86, -0.49, -0.14),
		"theme_tags":         [],
		"exclusive_to_week":  "training",
	},
	{
		"id":                 5,
		"day":                1,
		"caller_name":        "LUNA?",
		"caller_photo":       "",
		"duration":           40.0,
		"audio":              "",
		"transcription":
			"Yeah, I know it’s a mistake. *unintelligeliable* Uh, hello? Yeah, I’m sitting here near… What is it? The… lander place. 11? Anyway, I was sent out here to take some annual readings for some festival, but the damn stabilizer is telling me that the ground is about to give way, which definitely isn’t right because we have a 5 ton Mobile Lunar Outpost sitting on top of it and nothing is happening. *away from phone* Did you tune this right? I swear if this shit is faulty.",
		"additional_details": "",
		"correct_anomaly_id": 5,
		"tasks": [],
		"icon_direction":     Vector3(0.86, -0.49, -0.14),
		"theme_tags":         [],
		"exclusive_to_week":  "training",
	},
	{
		"id":                 6,
		"day":                1,
		"caller_name":        "LUNA!!!",
		"caller_photo":       "",
		"duration":           40.0,
		"audio":              "",
		"transcription":
			"Congrats! You’ve successfully diagnosed all the training anomalies! Once you submit this report as a Complaint!, you’ll be presented with your funds for your efforts! I’ll be seeing you tomorrow.",
		"additional_details": "Remember, your room is just down the hall.",
		"correct_anomaly_id": 13,
		"tasks": [],
		"icon_direction":     Vector3(0.86, -0.49, -0.14),
		"theme_tags":         [],
		"exclusive_to_week":  "training",
	},
	
	#---------------DAY 2-----------------
{
		"id":                 8,
		"day":                2,
		"caller_name":        "Assistent General James",
		"caller_photo":       "",
		"duration":           40.0,
		"audio":              "",
		"transcription":
			"Hello… What is your name? Eh, doesn’t matter. You’re the new recruit for M.A.R.S I hear? Well, as you probably know from the training video I made, I’m James, the Assistant General. I run the Assistants' Union, and manage all non-specialized workers on the Lunar Surface. Because of this, we tend to run into a lot of problems, and due to the fact we aren’t specialized, we probably can’t solve them on our own. This is why the GENERAL category exists. You have access to some more anomalies now, and I’ve now patched you into the General Call Network. Have fun.",
		"additional_details": "",
		"correct_anomaly_id": 16,
		"tasks": ["Mark as #16/Complaint"],
		"icon_direction":     Vector3(0.86, -0.49, -0.14),
		"theme_tags":         [],
		"exclusive_to_week":  "training",
	},
	{
		"id":                 9,
		"day":                2,
		"caller_name":        "Assistent Carl",
		"caller_photo":       "",
		"duration":           40.0,
		"audio":              "",
		"transcription":
			"Hi! I have a bit of a problem here. I was called out to this pipeline a bit north of Central, and while I was driving, my wheel froze up and the rover came to a stop. I don’t know what the problem is, but all my wheel wells are filled with tons of Regolith that seems to be frozen in place. If I can’t get there in the next two hours, they are going to demote me! Please help.",
		"additional_details": "Access to Pipeline Icarus, a major fuel pipeline between Central Station and Aristoteles Station has been restricted to a Ice Meteor shower that was reported last night. ",
		"correct_anomaly_id": 34,
		"tasks": [],
		"icon_direction":     Vector3(0.86, -0.49, -0.14),
		"theme_tags":         [],
		"exclusive_to_week":  "training",
	},
	{
		"id":                 10,
		"day":                2,
		"caller_name":        "Assistent Mark",
		"caller_photo":       "",
		"duration":           40.0,
		"audio":              "",
		"transcription":
			"There’s this BUG! It’s EVERYWHERE. I can’t get rid of it, but I have to get rid of it. It’s in the walls, the floors, the ceiling, everywhere! And the ticking! It ticks. All it does is tick. Tick, Tick, Tick, Tick, Tick, Tick. That’s all it does!",
		"additional_details": "",
		"correct_anomaly_id": 18,
		"tasks": [],
		"icon_direction":     Vector3(0.86, -0.49, -0.14),
		"theme_tags":         [],
		"exclusive_to_week":  "training",
	},
	{
		"id":                 11,
		"day":                2,
		"caller_name":        "Marshal Fixxer",
		"caller_photo":       "",
		"duration":           40.0,
		"audio":              "",
		"transcription":
			"I wish I didn’t have to do this, but my neighbors just keep… Well, not literally, but, y’know, banging. Like, the noise! Not the action! I just want to make that clear. The noise just doesn’t stop though. It’s night over here and… Let me show you. *Footsteps* Listen *Bang* *Bang* *Bang* *Bang* *Bang* *Bang* *Bang* *Bang* It’s been like that for the last 4 days. I don’t know what the hell they are doing up there, but it’s enough.",
		"additional_details": "Yeah, that’s a real name - LUNA",
		"correct_anomaly_id": "42",
		"tasks": [],
		"icon_direction":     Vector3(0.86, -0.49, -0.14),
		"theme_tags":         [],
		"exclusive_to_week":  "training",
	},
	{
		"id":                 12,
		"day":                2,
		"caller_name":        "Freezer Technician Holloway",
		"caller_photo":       "",
		"duration":           60.0,
		"audio":              "",
		"transcription": "Hey, this is Holloway of Ice-O's Freezer Division. I'm calling to report a issue with... tch. Station... 22's freezer. Damn thing fried a fuze a couple of days ago and nobody noticed until the smell starting leaking from inside the unit. I'd go in, but I can't handle the stench even with a mask on. Send some sort of... disposal team? Just send somebody.",
		"additional_details": "",
		"correct_anomaly_id": 6,
		"tasks":              [],
		"icon_direction":     Vector3(-0.61, 0.141, 0.78),
		"theme_tags":         [],
		"exclusive_to_week":  "training",
	},
	{
		"id":                 13,
		"day":                2,
		"caller_name":        "Rig Assistant Michael",
		"caller_photo":       "",
		"duration":           60.0,
		"audio":              "",
		"transcription": "*Siren* Hello?! Is someone on the line? Do you guys even have mics at those stations? Doesn't matter. We just had a major incident happen, but I'm not sure what the hell it was. I was working at my station when I hear this loud, I don't know how to describe it, whirring noise, followed by the refinement tanks suddenly exploding. A propeller lodged itself into my window!",
		"additional_details": "Drone V-09 of Capitol Mining Corporation has reported itself offline.",
		"correct_anomaly_id": 20,
		"tasks":              [],
		"icon_direction":     Vector3(-0.61, 0.141, 0.78),
		"theme_tags":         [],
		"exclusive_to_week":  "training",
	},
	{
		"id":                 14,
		"day":                2,
		"caller_name":        "Electrical Maintenance Unit DOE-77",
		"caller_photo":       "",
		"duration":           60.0,
		"audio":              "",
		"transcription":
			"[CONNECTION ESTABLISHED]\n"
			+ "[UNSTABLE VOLTAGE DETECTED]\n"
			+ "[MINOR SYSTEM POWER DEDICATION: LOW]\n"
			+ "[POWER GENERATION AT DAWN: LOW]\n"
			+ "[EXPECTED GENERATION: HIGH]\n"
			+ "[CONNECTION SEVERED]",
		"additional_details": "",
		"correct_anomaly_id": 37,
		"tasks":              [],
		"icon_direction":     Vector3(0.463, -0.706, 0.536),
		"theme_tags":         [],
		"exclusive_to_week":  "training",
	},
	{
		"id":                 15,
		"day":                2,
		"caller_name":        "Assistent General James",
		"caller_photo":       "",
		"duration":           60.0,
		"audio":              "",
		"transcription": "Hello-. Oh. It's you. I was wondering if this would happen. Anyway, I'd like to lodge a complaint, but don't file it as one. This satelite station, the one they gave me as part of my contract to create the General Division is absolutely disgusting. I saw some rats the other day picking through a pile of garbage! Can you get someone down here to come clean all this, it's just... Ew.",
		"additional_details": "",
		"correct_anomaly_id": 7,
		"tasks":              [],
		"icon_direction":     Vector3(0.145, 0.628, 0.765),
		"theme_tags":         [],
		"exclusive_to_week":  "training",
	},
	
	
	# --------DAY 3; MEDICAL AND SECURITY-------
	
	
	
	
	
	
	
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
		var is_exclusive: bool = entry.get("exclusive_to_week", "") == week_id
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
