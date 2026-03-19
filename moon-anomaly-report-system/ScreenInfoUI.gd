# ScreenInfoUI.gd
extends Control

const SEG_ON_COLOR = Color(0.0, 0.9, 0.2)   # green lit segment
const SEG_OFF_COLOR = Color(0.1, 0.1, 0.1)  # dark unlit segment
const NOT_FOUND_COLOR = Color(0.9, 0.1, 0.1)

@onready var name_label: Label = $LeftColumn/NameLabel
@onready var number_label: Label = $LeftColumn/NumberLabel
@onready var description_label: RichTextLabel = $RightColumn/DescriptionLabel
@onready var type_label: Label = $LeftColumn/Ratings/TypeRow/TypeLabel

# Bar segment groups — order must match the scene tree
@onready var severity_segs: Array = [
	$LeftColumn/Ratings/SeverityRow/SeverityBar/Seg1,
	$LeftColumn/Ratings/SeverityRow/SeverityBar/Seg2,
	$LeftColumn/Ratings/SeverityRow/SeverityBar/Seg3,
	$LeftColumn/Ratings/SeverityRow/SeverityBar/Seg4,
	$LeftColumn/Ratings/SeverityRow/SeverityBar/Seg5,
]
@onready var danger_segs: Array = [
	$LeftColumn/Ratings/DangerRow/DangerBar/Seg1,
	$LeftColumn/Ratings/DangerRow/DangerBar/Seg2,
	$LeftColumn/Ratings/DangerRow/DangerBar/Seg3,
	$LeftColumn/Ratings/DangerRow/DangerBar/Seg4,
	$LeftColumn/Ratings/DangerRow/DangerBar/Seg5,
]
@onready var scale_segs: Array = [
	$LeftColumn/Ratings/ScaleRow/ScaleBar/Seg1,
	$LeftColumn/Ratings/ScaleRow/ScaleBar/Seg2,
	$LeftColumn/Ratings/ScaleRow/ScaleBar/Seg3,
	$LeftColumn/Ratings/ScaleRow/ScaleBar/Seg4,
	$LeftColumn/Ratings/ScaleRow/ScaleBar/Seg5,
]

# Reference to ScreenPanelUI to push overflow text
var panel_ui: Control = null

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	print("NameLabel: ", $LeftColumn/NameLabel)
	print("NumberLabel: ", $LeftColumn/NumberLabel)
	print("TypeLabel: ", $LeftColumn/Ratings/TypeRow/TypeLabel)
	print("DescriptionLabel: ", $RightColumn/DescriptionLabel)
	print("SeverityBar Seg1: ", $LeftColumn/Ratings/SeverityRow/SeverityBar/Seg1)
	clear_display()
	$LeftColumn.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	$RightColumn.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)

func connect_to_panel(panel: Control) -> void:
	panel_ui = panel
	panel.entry_changed.connect(_on_entry_changed)

func _on_entry_changed(entry: Dictionary) -> void:
	if entry.has("status"):
		_show_status(entry["status"])
		return
	_populate(entry)

func _populate(entry: Dictionary) -> void:
	name_label.text = entry["name"]
	number_label.text = "ENTRY #" + str(entry["id"])
	type_label.text = "TYPE: " + AnomalyDatabase.get_category_name(entry["type"])
	_set_bar(severity_segs, entry["severity"])
	_set_bar(danger_segs, entry["danger"])
	_set_bar(scale_segs, entry["scale"])
	_set_description(entry["description"])

func _set_bar(segs: Array, value: int) -> void:
	for i in range(segs.size()):
		segs[i].color = SEG_ON_COLOR if i < value else SEG_OFF_COLOR

func _set_description(full_text: String) -> void:
	# Fit as much text as possible in the right column
	# Push remainder to the panel screen
	description_label.text = full_text
	await get_tree().process_frame  # wait one frame for layout to settle
	if description_label.get_line_count() > description_label.get_visible_line_count():
		# Text overflows — calculate what fits
		var visible_lines = description_label.get_visible_line_count()
		var lines = full_text.split("\n")
		# Simple word-wrap split: send overflow to panel
		var approx_chars = visible_lines * 38  # tune this number to your font size
		var top_text = full_text.substr(0, approx_chars)
		var overflow_text = full_text.substr(approx_chars)
		description_label.text = top_text
		if panel_ui:
			panel_ui.set_overflow(overflow_text)
	else:
		if panel_ui:
			panel_ui.set_overflow("")

func _show_status(status: String) -> void:
	clear_display()
	match status:
		AnomalyDatabase.NOT_FOUND:
			name_label.text = "NOT FOUND"
			name_label.modulate = NOT_FOUND_COLOR
		AnomalyDatabase.NOT_ACCESSIBLE:
			name_label.text = "NOT ACCESSIBLE"
			name_label.modulate = NOT_FOUND_COLOR

func clear_display() -> void:
	name_label.text = "---"
	name_label.modulate = Color.WHITE
	number_label.text = ""
	type_label.text = ""
	description_label.text = ""
	_set_bar(severity_segs, 0)
	_set_bar(danger_segs, 0)
	_set_bar(scale_segs, 0)
	if panel_ui:
		panel_ui.set_overflow("")
