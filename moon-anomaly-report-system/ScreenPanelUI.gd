# ScreenPanelUI.gd
extends Control

signal entry_changed(entry: Dictionary)

var current_id: int = 1
var current_category: AnomalyDatabase.Category = AnomalyDatabase.Category.ALL

@onready var description_overflow: RichTextLabel = $RichTextLabel
@onready var separator: HSeparator = $Separator
@onready var category_label: Label = $Controls/CategoryRow/CategoryLabel
@onready var number_field: LineEdit = $Controls/NumberRow/NumberField
@onready var current_id_label: Label = $Controls/NavRow/CurrentID

func _ready() -> void:
	$Controls/CategoryRow/CatLeft.pressed.connect(_cycle_category.bind(-1))
	$Controls/CategoryRow/CatRight.pressed.connect(_cycle_category.bind(1))
	$Controls/NavRow/NavLeft.pressed.connect(_navigate.bind(-1))
	$Controls/NavRow/NavRight.pressed.connect(_navigate.bind(1))
	$Controls/NumberRow/NumberField.text_submitted.connect(_on_number_submitted)
	$Controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	$RichTextLabel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	$HSeparator.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)

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
