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
{
		"id":      "DAY2CHAT",
		"trigger": "day_start",
		"day":     2,
		"steps": [
			{
				"speaker":  "LUNA!!!",
				"portrait": "",
				"text":     "Hello again! How was your sleep?",
				"choices":  [
					{ "text": "It was fine.", "id": "choice_1778658437994" },
				],
			},
			{
				"speaker":  "LUNA!!!",
				"portrait": "",
				"text":     "You say that alot y'know?",
				"choices":  [
					{ "text": "Yes.", "id": "choice_1778658457253" },
				],
			},
			{
				"speaker":  "LUNA!!!",
				"portrait": "",
				"text":     "Anyhow, Today, our lovely Assistent General has made time out of his very busy schedule to come and have a call with you while he splices you into the General Call Network. He's a bit... much.",
				"choices":  [
					{ "text": "You do remember that I know him, right?", "id": "choice_1778658529808" },
				],
			},
			{
				"speaker":  "LUNA.",
				"portrait": "",
				"text":     "Yeah! Yeah, of course. I was just... reminding you.",
				"choices":  [],
			},
			{
				"speaker":  "LUNA!!!",
				"portrait": "",
				"text":     "Oh! And also, since you passed your first day with flying colors, you now have access to the station's break room. Just [TAB] out of your computer, and walk on over to enjoy a nice relaxing break room.",
				"choices":  [],
			},
			{
				"speaker":  "LUNA!!!",
				"portrait": "",
				"text":     "Have a wonderful day.",
				"choices":  [],
			}
		]
	},
	
	#END DIALOG
	
	{
		"id":      "Day2End",
		"trigger": "day_end",
		"day":     2,
		"steps": [
			{
				"speaker":  "LUNA!!!",
				"portrait": "",
				"text":     "Congrats, you finished your first day! Your credits will be deposited into your account after you log out from your CRATER.",
				"choices":  [
					{ "text": "Cool.", "id": "1cool" },
				],
			},
			{
				"speaker":  "LUNA.",
				"portrait": "",
				"text":     "Are you okay?",
				"choices":  [
					{ "text": "What?", "id": "1what" },
				],
			},
			{
				"speaker":  "LUNA.",
				"portrait": "",
				"text":     "I swear you used to be more... joyous... Y'know. Is something wrong? Are your accommodations not pleasing to you? I know the bed isn't the greatest, but our budget hasn't exactly gotten bigger. ",
				"choices":  [
					{ "text": "It's fine, LUNA.", "id": "1its_fine" },
				],
			},
			{
				"speaker":  "LUNA.",
				"portrait": "",
				"text":     "Okay. Uh, once again, the credits will be deposited after you log out. \n \nGoodnight.",
				"choices":  [],
			},
		]
	},
	
	
	
	# --------------DAY 3 MEDICAL AND SECURITY--------------
		{
		"id":      "LUNA-MEDICAL-SECURITY INTRO",
		"trigger": "day_start",
		"day":     3,
		"steps": [
			{
				"speaker":  "LUNA!!!",
				"portrait": "",
				"text":     "Good morning! Today, as procedure states, you are to meet the head of both the Security and Medical Department. While you were gone, they consolidated the position into one person. They decided to meet you over our communication link instead of a call. I've put them on hold for you.",
				"choices":  [
					{ "text": "Thanks.", "id": "1thanks" },
				],
			},
			{
				"speaker":  "MEDSEC Head; Patrica Anderson",
				"portrait": "",
				"text":     "I see you've returned from your vacation, Mr No Name. You finally decide to get one while you were down on Venus?",
				"choices":  [
					{ "text": "Good morning, Patrica", "id": "1morningpatrica" },
				],
			},
			{
				"speaker":  "MEDSEC Head; Patrica Anderson",
				"portrait": "",
				"text":     "That was just cold. How was your vacation anyway? I've heard good things about that little resort, but I've never had the chance to go because I'm actually important to daily life on the Moon. You relax at the pools? Went on a slide? Whatever you do on that god-forsaken planet?",
				"choices":  [
					{ "text": "It was fine, Patrica", "id": "1_it_was_fine_pat" },
					{ "text": "Terrible, actually.", "id": "1_terrible" },
					{ "text": "They don't have pools.", "id": "no pools" },
				],
			},
			{
				"speaker":  "MEDSEC Head; Patrica Anderson",
				"portrait": "",
				"text":     "I don't care! *laughter* \n \n Anyhow, I've patched you into the security and medical network, and gave you permission to access our more important files. Toodles, little man.",
				"choices":  [],
			},
		]
	},
	
	{
		"id":      "day_3_end",
		"trigger": "day_end",
		"day":     3,
		"steps": [
			{
				"speaker":  "Patrica Anderson",
				"portrait": "",
				"text":     "Hey. Look, I don't do this often, but I'm sorry.",
				"choices":  [
					{ "text": "For what?", "id": "choice_1784438931907" },
				],
			},
			{
				"speaker":  "Patrica Anderson",
				"portrait": "",
				"text":     "For being an ass earlier. I know, after... well. I imagine you don't really want to talk about it. I... I'm sorry, okay?",
				"choices":  [
					{ "text": "It's fine.", "id": "choice_1784439101598" },
				],
			},
			{
				"speaker":  "Patrica Anderson",
				"portrait": "",
				"text":     "Good. Anyhow, I'm free this weekend, and that one bar downtown is still open. You want to go?",
				"choices":  [
					{ "text": "I'll see if I can make it.", "id": "choice_1784439161562" },
				],
			},
			{
				"speaker":  "Patrica Anderson",
				"portrait": "",
				"text":     "Wonderful! ... Be safe buddy.",
				"choices":  [],
			}
		]
	},
	
	# --------------DAY 4 SCIENCE--------------#
	{
		"id":      "DAY_4_SCI_INTRO",
		"trigger": "day_start",
		"day":     4,
		"steps": [
			{
				"speaker":  "LUNA!!!",
				"portrait": "",
				"text":     "Good morning! How was your sleep? We had some tremors last night, and I want to make sure they didn't impact you. We've been having an uptick in occurrences for the past couple of months.",
				"choices":  [
					{ "text": "It was fine.", "id": "choice_1786904206879" },
				],
			},
			{
				"speaker":  "LUNA!!!",
				"portrait": "",
				"text":     "Good! Anyhow, today you'll be meeting with the Head of Science, who runs the Geology, Biological and Scientific departments. ",
				"choices":  [
					{ "text": "Issac?", "id": "choice_1786907610117" },
				],
			},
			{
				"speaker":  "LUNA!!!",
				"portrait": "",
				"text":     "Uh, yes? Mr. Issac Alderman. ",
				"choices":  [
					{ "text": "Do I have to talk to him?", "id": "choice_1786907698035" },
				],
			},
			{
				"speaker":  "LUNA!!!",
				"portrait": "",
				"text":     "Yes. It's a mandatory part of your retraining",
				"choices":  [
					{ "text": "Fine. Patch him through.", "id": "choice_1786907765736" },
				],
			},
			{
				"speaker":  "LUNA!!!",
				"portrait": "",
				"text":     "Patching!",
				"choices":  [],
			},
			{
				"speaker":  "SCI Head: Issac Alderman",
				"portrait": "",
				"text":     "Hello. Are you doing good? I know you just got back and everything, and I want to make sure you're doing good.",
				"choices":  [
					{ "text": "Can we not?", "id": "choice_1786908167651" },
				],
			},
			{
				"speaker":  "SCI Head: Issac Alderman",
				"portrait": "",
				"text":     "Not what?",
				"choices":  [
					{ "text": "I just want to move on. ", "id": "choice_1786908268139" },
				],
			},
			{
				"speaker":  "SCI Head: Issac Alderman",
				"portrait": "",
				"text":     "We have to talk about it at some-",
				"choices":  [
					{ "text": "No. No we don't.", "id": "choice_1786908299431" },
				],
			},
			{
				"speaker":  "SCI Head: Issac Alderman",
				"portrait": "",
				"text":     "Fine. You have access to more science entries now. I'll patch in the Science line. Enjoy the calls, I guess.",
				"choices":  [],
			}
		]
	},

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
