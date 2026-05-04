# DialogDatabase.gd
# ── AUTOLOAD SETUP ────────────────────────────────────────────────────────────
# Project Settings → Autoload → add as "DialogDatabase"
# Place it BEFORE DialogManager in the autoload list.
#
# ── SEQUENCE FORMAT ───────────────────────────────────────────────────────────
# {
#   "id":      String,   # unique key used by DialogManager.play("id")
#   "trigger": String,   # when to auto-fire (see TRIGGERS below)
#   "day":     int,      # for "day_start" trigger: which day number
#   "steps":   Array,    # ordered list of dialog step dictionaries
# }
#
# TRIGGERS
#   "day_start"  — auto-fires when that day begins
#                  (day 1 fires on game launch since no day_started signal fires then)
#   "manual"     — only fires when you call DialogManager.play("id") yourself
#
# ── STEP FORMAT ───────────────────────────────────────────────────────────────
# {
#   "speaker":  String,   # name shown above the text box
#   "portrait": String,   # res:// path to portrait texture — "" hides the slot
#   "text":     String,   # body text (typewriter effect)
#   "choices":  Array,    # [] = click-to-advance
#                         # or: [{ "text": "Button label", "id": "choice_key" }, ...]
# }

extends Node

var sequences: Array[Dictionary] = [

	# ── DAY 1 ─────────────────────────────────────────────────────────────────

	{
		"id":      "day_1_intro",
		"trigger": "day_start",
		"day":     1,
		"steps": [
			{
				"speaker":  "LUNA",
				"portrait": "",   # TODO: assign once you have the asset
				"text":     "Hello! Welcome back to the Moon Anomaly Reporting Station (M.A.R.S for short). "
							+ "How was your vacation? I heard Venus is a pretty nice planet this time of year.",
				"choices":  [{"text": "It was fine",  "id": "itwasfine"}]
			},
			{
				"speaker":  "LUNA",
				"portrait": "",
				"text":     "Wonderful! However, since your vacation exceeded 4 weeks, the M.A.R.S by-laws dictate that you must be retrainedd"
							+ "Don't worry. It'll only take a week, and, looking at your record, think of it as a second vacation.",
				"choices":  []
			},
			{
				"speaker":  "LUNA",
				"portrait": "",
				"text":     "As you should remember, when I call icon appears on the holographic moon, simply click on it to answer. "
							+ "On your left is your Database terminal. There's been some additions since you've been gone. Simply match what the caller describes to an anomaly and submit the report.",
				"choices":  []
			},
			{
				"speaker":  "LUNA",
				"portrait": "",
				"text":     "Today, we're going to start you off with some simple calls and entries. Nothing to big. Don't sweat it",
				"choices":  []
			},
		]
	},

	# ── DAY 2 ─────────────────────────────────────────────────────────────────
	# {
	# 	"id":      "day_2_intro",
	# 	"trigger": "day_start",
	# 	"day":     2,
	# 	"steps": [
	# 		{
	# 			"speaker":  "LUNA",
	# 			"portrait": "",
	# 			"text":     "Day two. The calls today will be a little more varied.",
	# 			"choices":  []
	# 		},
	# 	]
	# },

	# ── MANUAL SEQUENCES ──────────────────────────────────────────────────────
	# Triggered by calling DialogManager.play("id") directly from any script.
	# Useful for NPC conversations, cutscenes, post-call debriefs, etc.

	# {
	# 	"id":      "first_anomalous_call",
	# 	"trigger": "manual",
	# 	"day":     0,
	# 	"steps": [
	# 		{
	# 			"speaker":  "LUNA",
	# 			"portrait": "",
	# 			"text":     "That was... unusual. I'm flagging that call for review.",
	# 			"choices":  []
	# 		},
	# 	]
	# },

	# ── CHOICE EXAMPLE ────────────────────────────────────────────────────────
	# Choices emit DialogManager.choice_selected("sequence_id", "choice_id").
	# Connect to that signal to branch your game logic externally.
	#
	# {
	# 	"id":      "briefing_choice",
	# 	"trigger": "manual",
	# 	"day":     0,
	# 	"steps": [
	# 		{
	# 			"speaker":  "LUNA",
	# 			"portrait": "",
	# 			"text":     "Would you like a briefing before we start?",
	# 			"choices":  [
	# 				{ "text": "Yes, please.", "id": "yes" },
	# 				{ "text": "Skip it.",     "id": "no"  },
	# 			]
	# 		},
	# 		{
	# 			"speaker":  "LUNA",
	# 			"portrait": "",
	# 			"text":     "Understood. Let's begin.",
	# 			"choices":  []
	# 		},
	# 	]
	# },

]

# ── API ───────────────────────────────────────────────────────────────────────

## Fetch a single sequence by id. Returns {} if not found.
func get_sequence(id: String) -> Dictionary:
	for seq in sequences:
		if seq.get("id", "") == id:
			return seq
	return {}

## Return all sequences matching a trigger type (and optionally a day).
func get_by_trigger(trigger: String, day: int = 0) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for seq in sequences:
		if seq.get("trigger", "manual") != trigger:
			continue
		if trigger == "day_start" and seq.get("day", 0) != day:
			continue
		result.append(seq)
	return result

## Register or replace a sequence at runtime.
func register(entry: Dictionary) -> void:
	for i in range(sequences.size()):
		if sequences[i].get("id", "") == entry.get("id", ""):
			sequences[i] = entry
			return
	sequences.append(entry)
