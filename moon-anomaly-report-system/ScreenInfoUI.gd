# ScreenInfoUI.gd
extends Control

const SEG_ON_COLOR = Color(0.0, 0.9, 0.2)   # green lit segment
const SEG_OFF_COLOR = Color(0.1, 0.1, 0.1)  # dark unlit segment
const NOT_FOUND_COLOR = Color(0.9, 0.1, 0.1)

@onready var name_label: Label = $HBoxContainer/LeftColumn/NameLabel
@onready var number_label: Label = $HBoxContainer/LeftColumn/NumberLabel
@onready var description_label: RichTextLabel = $HBoxContainer/RightColumn/DescriptionLabel
@onready var type_label: Label = $HBoxContainer/LeftColumn/Ratings/TypeRow/TypeLabel

@onready var severity_segs: Array = [
	$HBoxContainer/LeftColumn/Ratings/SeverityRow/SeverityBar/Seg1,
	$HBoxContainer/LeftColumn/Ratings/SeverityRow/SeverityBar/Seg2,
	$HBoxContainer/LeftColumn/Ratings/SeverityRow/SeverityBar/Seg3,
	$HBoxContainer/LeftColumn/Ratings/SeverityRow/SeverityBar/Seg4,
	$HBoxContainer/LeftColumn/Ratings/SeverityRow/SeverityBar/Seg5,
]
@onready var danger_segs: Array = [
	$HBoxContainer/LeftColumn/Ratings/DangerRow/DangerBar/Seg1,
	$HBoxContainer/LeftColumn/Ratings/DangerRow/DangerBar/Seg2,
	$HBoxContainer/LeftColumn/Ratings/DangerRow/DangerBar/Seg3,
	$HBoxContainer/LeftColumn/Ratings/DangerRow/DangerBar/Seg4,
	$HBoxContainer/LeftColumn/Ratings/DangerRow/DangerBar/Seg5,
]
@onready var scale_segs: Array = [
	$HBoxContainer/LeftColumn/Ratings/ScaleRow/ScaleBar/Seg1,
	$HBoxContainer/LeftColumn/Ratings/ScaleRow/ScaleBar/Seg2,
	$HBoxContainer/LeftColumn/Ratings/ScaleRow/ScaleBar/Seg3,
	$HBoxContainer/LeftColumn/Ratings/ScaleRow/ScaleBar/Seg4,
	$HBoxContainer/LeftColumn/Ratings/ScaleRow/ScaleBar/Seg5,
]

# Reference to ScreenPanelUI to push overflow text
var panel_ui: Control = null

func _ready() -> void:
	clear_display()
	await get_tree().process_frame

	$HBoxContainer.position = Vector2.ZERO
	$HBoxContainer.size = Vector2(480, 308)

	$HBoxContainer/LeftColumn.position = Vector2.ZERO
	$HBoxContainer/LeftColumn.size = Vector2(240, 308)
	$HBoxContainer/LeftColumn/NameLabel.autowrap_mode = TextServer.AUTOWRAP_WORD
	$HBoxContainer/LeftColumn/NameLabel.custom_minimum_size = Vector2(240, 0)

	$HBoxContainer/LeftColumn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	$HBoxContainer/LeftColumn.size_flags_stretch_ratio = 1.0
	$HBoxContainer/RightColumn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	$HBoxContainer/RightColumn.size_flags_stretch_ratio = 1.0



	# Right column as plain Control — no automatic layout
	$HBoxContainer/RightColumn.position = Vector2(240, 0)
	$HBoxContainer/RightColumn.size = Vector2(240, 308)
	$HBoxContainer/RightColumn.clip_contents = true

	# Description fills right column exactly — hard capped
	$HBoxContainer/RightColumn/DescriptionLabel.position = Vector2(4, 32)
	$HBoxContainer/RightColumn/DescriptionLabel.size = Vector2(236, 270)
	$HBoxContainer/RightColumn/DescriptionLabel.scroll_active = false
	$HBoxContainer/RightColumn/DescriptionLabel.clip_contents = false
	$HBoxContainer/RightColumn/DescriptionLabel.autowrap_mode = TextServer.AUTOWRAP_WORD  # add this

	_style_labels(self)

func _style_labels(node: Node) -> void:
	if node is Label:
		node.add_theme_color_override("font_color", Color.WHITE)
		node.add_theme_font_size_override("font_size", 20)
	elif node is RichTextLabel:
		node.add_theme_color_override("default_color", Color.WHITE)
		node.add_theme_font_size_override("normal_font_size", 20)
	for child in node.get_children():
		_style_labels(child)



func connect_to_panel(panel: Control) -> void:
	panel_ui = panel
	panel.entry_changed.connect(_on_entry_changed)

func _on_entry_changed(entry: Dictionary) -> void:
	if entry.has("status"):
		_show_status(entry["status"])
		return
	_populate(entry)

func _populate(entry: Dictionary) -> void:
	print("Populating with: ", entry["name"])
	name_label.text = entry["name"]
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
	description_label.scroll_active = false
	description_label.clip_contents = true

	var words = full_text.split(" ")
	var lo = 0
	var hi = words.size()
	var best_fit = 0

	while lo <= hi:
		var mid = (lo + hi) / 2
		description_label.text = " ".join(words.slice(0, mid))
		await get_tree().process_frame
		await get_tree().process_frame
		if description_label.get_content_height() <= description_label.size.y:
			best_fit = mid
			lo = mid + 1
		else:
			hi = mid - 1

	var top_text = " ".join(words.slice(0, best_fit)).strip_edges()
	var overflow_text = " ".join(words.slice(best_fit)).strip_edges()

	description_label.text = top_text
	if panel_ui:
		panel_ui.set_overflow(overflow_text if overflow_text.length() > 0 else "")

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
