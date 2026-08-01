# StubAppWindow.gd
# Placeholder content for any BigTerminal app without real functionality yet.
# Instantiate with:
#   var content := Control.new()
#   content.set_script(preload("res://StubAppWindow.gd"))
#   content.setup("App Name")

extends Control

var _label: Label

func _ready() -> void:
	custom_minimum_size = Vector2(400, 260)

	var bg := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#C0C0C0")
	bg.add_theme_stylebox_override("panel", style)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_label = Label.new()
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_label.offset_left   = 16
	_label.offset_top    = 16
	_label.offset_right  = -16
	_label.offset_bottom = -16
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_label.add_theme_color_override("font_color", Color(0.15, 0.15, 0.15))
	add_child(_label)

	if _pending_name != "":
		_apply_name(_pending_name)

var _pending_name: String = ""

func setup(app_name: String) -> void:
	_pending_name = app_name
	if _label != null:
		_apply_name(app_name)

func _apply_name(app_name: String) -> void:
	_label.text = (
		"%s\n\n— MODULE OFFLINE —\n\nThis application has not completed accreditation review.\nCheck back once your clearance updates."
		% app_name.to_upper()
	)
