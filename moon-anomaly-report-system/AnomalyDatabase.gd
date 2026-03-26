# AnomalyDatabase.gd
extends Node

enum Category { ALL, MEDICAL, SECURITY, GEOLOGICAL, ATMOSPHERIC, UNKNOWN, GENERAL }

const NOT_FOUND = "NOT_FOUND"
const NOT_ACCESSIBLE = "NOT_ACCESSIBLE"

# This is where you'll add all your anomaly entries later
# Each entry: id, name, category, severity, danger, scale, type, description, icon_path
var entries: Array[Dictionary] = [
	{
		"id": 1,
		"name": "Incorrect Clearence Code",
		"category": Category.SECURITY,
		"severity": 2,
		"danger": 1,
		"scale": 3,
		"type": Category.GEOLOGICAL,
		"description": "All avenues of access into restricted or otherwise locked areas of the complexes that make up the Primary Lunar Construction (PLC) are controlled by Access Cards. Every individual upon the lunar surface possesses a clearence code. This individual is attempting to access a area that their code does not permit.        Upon use of a incorrect clearence code, a access terminal will beep loudly and display the words 'incorrect clearence'.",
		"icon_path": "res://wp12013121.jpg",
		"accessible": true
	},
	{
		"id": 2,
		"name": "Classified Entry",
		"category": Category.SECURITY,
		"severity": 5,
		"danger": 5,
		"scale": 5,
		"type": Category.SECURITY,
		"description": "",
		"icon_path": "",
		"accessible": true
	},
]

func get_entry(id: int) -> Dictionary:
	for entry in entries:
		if entry["id"] == id:
			if not entry["accessible"]:
				return {"status": NOT_ACCESSIBLE}
			return entry
	return {"status": NOT_FOUND}

func get_next_id(current_id: int, direction: int, category: Category) -> int:
	# Collect valid IDs matching the category filter
	var valid_ids: Array[int] = []
	for entry in entries:
		if category == Category.ALL or entry["category"] == category:
			valid_ids.append(entry["id"])
	valid_ids.sort()

	if valid_ids.is_empty():
		return current_id

	# Find the nearest valid ID in the given direction
	if direction > 0:
		for id in valid_ids:
			if id > current_id:
				return id
		return valid_ids.back()  # clamp at end
	else:
		var reversed = valid_ids.duplicate()
		reversed.reverse()
		for id in reversed:
			if id < current_id:
				return id
		return valid_ids.front()  # clamp at start

func get_category_name(category: Category) -> String:
	match category:
		Category.ALL: return "ALL"
		Category.MEDICAL: return "MEDICAL"
		Category.SECURITY: return "SECURITY"
		Category.GEOLOGICAL: return "GEOLOGICAL"
		Category.ATMOSPHERIC: return "ATMOSPHERIC"
		Category.UNKNOWN: return "UNKNOWN"
	return "ALL"
