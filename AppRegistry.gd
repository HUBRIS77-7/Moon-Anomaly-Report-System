# AppRegistry.gd
# Add to Project Settings → Autoload as "AppRegistry".
#
# Defines every app that can appear on the BigTerminal desktop, plus the day
# (within the training week) it unlocks. Once the training week ends, every
# app is unlocked regardless of day — GameState handles that rule.

extends Node

# Each entry:
# {
#   "id":          String,  # unique key, stored in GameState.unlocked_apps
#   "name":        String,  # display name — window titlebar + tooltip
#   "abbr":        String,  # short label baked onto the placeholder icon
#   "icon_color":  Color,   # placeholder icon square color — swap for a real
#                           # icon texture later without touching this schema
#   "unlock_day":  int,     # day within the TRAINING week this unlocks on
# }

var apps: Array[Dictionary] = [
	{
		"id":         "crater_mail",
		"name":       "C.R.A.T.E.R Mail",
		"abbr":       "MAIL",
		"icon_color": Color(0.20, 0.35, 0.65),
		"unlock_day": 2,
	},
	{
		"id":         "caller_database",
		"name":       "Caller Database",
		"abbr":       "CALL",
		"icon_color": Color(0.55, 0.30, 0.15),
		"unlock_day": 2,
	},
	{
		"id":         "luna_pedia",
		"name":       "LUNA-pedia",
		"abbr":       "LUNA",
		"icon_color": Color(0.30, 0.30, 0.30),
		"unlock_day": 3,
	},
	{
		"id":         "sat_drone_registry",
		"name":       "Satellite & Drone Registry",
		"abbr":       "SAT",
		"icon_color": Color(0.15, 0.45, 0.20),
		"unlock_day": 4,
	},
	{
		"id":         "power_grid",
		"name":       "Lunar Power Grid",
		"abbr":       "PWR",
		"icon_color": Color(0.60, 0.55, 0.10),
		"unlock_day": 5,
	},
]

func get_app(id: String) -> Dictionary:
	for app in apps:
		if app["id"] == id:
			return app
	return {}

func get_all_ids() -> Array[String]:
	var ids: Array[String] = []
	for app in apps:
		ids.append(app["id"])
	return ids

func get_unlock_day(id: String) -> int:
	var app := get_app(id)
	return app.get("unlock_day", 1)
