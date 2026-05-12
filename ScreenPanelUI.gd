# ScreenPanelUI.gd
extends Control

signal entry_changed(entry: Dictionary)

const FONT_PATH := "res://Ac437_IBM_BIOS.ttf"
var _font: Font = null

var current_id: int = 1
var current_category: AnomalyDatabase.Category = AnomalyDatabase.Category.ALL

@onready var description_overflow: RichTextLabel = $RichTextLabel
@onready var separator: HSeparator = $Separator
@onready var category_label: Label = $Controls/CategoryRow/CategoryLabel
@onready var number_field: LineEdit = $Controls/NumberRow/NumberField
@onready var current_id_label: Label = $Controls/NavRow/CurrentID

func _ready() -> void:
	if ResourceLoader.exists(FONT_PATH):
		_font = load(FONT_PATH)

	$Controls/CategoryRow/CatLeft.pressed.connect(_cycle_category.bind(-1))
	$Controls/CategoryRow/CatRight.pressed.connect(_cycle_category.bind(1))
	$Controls/NavRow/NavLeft.pressed.connect(_navigate.bind(-1))
	$Controls/NavRow/NavRight.pressed.connect(_navigate.bind(1))
	$Controls/NumberRow/NumberField.text_submitted.connect(_on_number_submitted)

	await get_tree().process_frame

	var controls_height = $Controls.get_minimum_size().y
	var separator_y = 640 - controls_height - 14
	var controls_y = 640 - controls_height - 8

	$Controls.position = Vector2(0, controls_y)
	$Controls.size = Vector2(240, controls_height)
	$HSeparator.position = Vector2(0, separator_y)
	$HSeparator.size = Vector2(240, 4)
	$RichTextLabel.position = Vector2(4, 4)
	$RichTextLabel.size = Vector2(232, separator_y - 8)
	$RichTextLabel.clip_contents = true
	$RichTextLabel.autowrap_mode = TextServer.AUTOWRAP_WORD
	$RichTextLabel.scroll_active = true

	_style_labels(self)


func _style_labels(node: Node) -> void:
	if node is Label:
		node.add_theme_color_override("font_color", Color.WHITE)
		node.add_theme_font_size_override("font_size", 14)
		if _font:
			node.add_theme_font_override("font", _font)
	elif node is RichTextLabel:
		node.add_theme_color_override("default_color", Color.WHITE)
		node.add_theme_font_size_override("normal_font_size", 14)
		if _font:
			node.add_theme_font_override("normal_font", _font)
	for child in node.get_children():
		_style_labels(child)


func _style_scrollbar(rtl: RichTextLabel) -> void:
	var scrollbar: VScrollBar = null
	for child in rtl.get_children(true):  # true = include internal nodes
		if child is VScrollBar:
			scrollbar = child
			break

	if scrollbar == null:
		return

	var grabber := StyleBoxFlat.new()
	grabber.bg_color = Color(0.0, 0.9, 0.2)
	grabber.set_corner_radius_all(0)

	var grabber_hover := StyleBoxFlat.new()
	grabber_hover.bg_color = Color(0.0, 1.0, 0.3)
	grabber_hover.set_corner_radius_all(0)

	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.05, 0.05, 0.05)
	track.set_corner_radius_all(0)

	scrollbar.add_theme_stylebox_override("scroll", track)
	scrollbar.add_theme_stylebox_override("scroll_focus", track)
	scrollbar.add_theme_stylebox_override("grabber", grabber)
	scrollbar.add_theme_stylebox_override("grabber_highlight", grabber_hover)
	scrollbar.add_theme_stylebox_override("grabber_pressed", grabber_hover)
	scrollbar.add_theme_constant_override("scroll_speed", 120)


func _load_entry(id: int) -> void:
	current_id = id
	current_id_label.text = str(id)
	number_field.text = str(id)
	var entry = AnomalyDatabase.get_entry(id)
	entry_changed.emit(entry)


func _navigate(direction: int) -> void:
	var next_id = AnomalyDatabase.get_next_id(current_id, direction, current_category)
	_load_entry(next_id)


func _cycle_category(direction: int) -> void:
	var max_cat = AnomalyDatabase.Category.size() - 1
	var cat_int = wrapi(int(current_category) + direction, 0, max_cat + 1)
	current_category = cat_int as AnomalyDatabase.Category
	category_label.text = AnomalyDatabase.get_category_name(current_category)


func _on_number_submitted(text: String) -> void:
	var id = text.strip_edges().to_int()
	if id > 0:
		_load_entry(id)
	else:
		number_field.text = str(current_id)


# Called by ScreenInfoUI to pass description overflow text
func set_overflow(text: String) -> void:
	description_overflow.text = text
	description_overflow.add_theme_color_override("default_color", Color.WHITE)
	description_overflow.add_theme_font_size_override("normal_font_size", 16)
	if _font:
		description_overflow.add_theme_font_override("normal_font", _font)
	# Style the scrollbar now that content exists to scroll
	await get_tree().process_frame
	_style_scrollbar(description_overflow)
