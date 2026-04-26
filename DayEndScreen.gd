# DayEndScreen.gd
# Autoload this as "DayEndScreen" in Project Settings → Autoload.
# It is a CanvasLayer so it renders above the entire 3-D scene.
# Connects to GameState.day_ended automatically on startup.

extends CanvasLayer

const FONT_PATH := "res://Ac437_IBM_BIOS.ttf"

# UI nodes built procedurally
var _bg:          ColorRect
var _day_label:   Label
var _score_label: Label
var _pct_label:   Label
var _next_btn:    Button

# Stored when day_ended fires so the button can read them
var _day_number:  int   = 1
var _correct:     int   = 0
var _total:       int   = 0

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	layer = 128          # Render above everything else
	_build_ui()
	hide()               # Hidden until a day ends

	GameState.day_ended.connect(_on_day_ended)

# ── UI construction ───────────────────────────────────────────────────────────

func _build_ui() -> void:
	var font: Font = null
	if ResourceLoader.exists(FONT_PATH):
		font = load(FONT_PATH)

	# Full-screen black background — added directly to the CanvasLayer
	_bg = ColorRect.new()
	_bg.color = Color(0, 0, 0, 1)
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)

	# Full-rect Control that acts as the layout root (ColorRect has no layout)
	var layout_root := Control.new()
	layout_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(layout_root)

	# CenterContainer fills the layout root and centres its single child
	var center_box := CenterContainer.new()
	center_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout_root.add_child(center_box)

	# VBoxContainer holds all the text + button
	var centre := VBoxContainer.new()
	centre.alignment = BoxContainer.ALIGNMENT_CENTER
	centre.add_theme_constant_override("separation", 24)
	center_box.add_child(centre)

	# Helper to make a styled label
	var _make_label := func(text: String, size: int, color: Color) -> Label:
		var lbl := Label.new()
		lbl.text = text
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_color_override("font_color", color)
		lbl.add_theme_font_size_override("font_size", size)
		if font:
			lbl.add_theme_font_override("font", font)
		return lbl

	_day_label  = _make_label.call("DAY 1 COMPLETE",        28, Color(0.95, 0.70, 0.10))
	_score_label = _make_label.call("Calls correct: 0 / 0",  20, Color(0.90, 0.90, 0.90))
	_pct_label  = _make_label.call("Accuracy: 0%",           20, Color(0.90, 0.90, 0.90))

	centre.add_child(_day_label)
	centre.add_child(_score_label)
	centre.add_child(_pct_label)

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	centre.add_child(spacer)

	# Next Day button
	_next_btn = Button.new()
	_next_btn.text = "NEXT DAY  >"
	_next_btn.custom_minimum_size = Vector2(220, 48)
	_next_btn.add_theme_font_size_override("font_size", 20)
	if font:
		_next_btn.add_theme_font_override("font", font)
	_next_btn.pressed.connect(_on_next_day_pressed)

	# Give the button a visible dark style
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color     = Color(0.08, 0.08, 0.08)
	btn_style.border_color = Color(0.95, 0.70, 0.10)
	btn_style.set_border_width_all(2)
	_next_btn.add_theme_stylebox_override("normal", btn_style)

	var btn_hover := btn_style.duplicate() as StyleBoxFlat
	btn_hover.bg_color = Color(0.18, 0.14, 0.02)
	_next_btn.add_theme_stylebox_override("hover", btn_hover)

	_next_btn.add_theme_color_override("font_color",       Color(0.95, 0.70, 0.10))
	_next_btn.add_theme_color_override("font_hover_color", Color(1.00, 0.85, 0.30))

	centre.add_child(_next_btn)

# ── Signal handlers ───────────────────────────────────────────────────────────

func _on_day_ended(day_number: int, correct: int, total: int) -> void:
	_day_number = day_number
	_correct    = correct
	_total      = total

	var pct := 0.0
	if total > 0:
		pct = (float(correct) / float(total)) * 100.0

	_day_label.text   = "DAY %d COMPLETE" % day_number
	_score_label.text = "Calls correct: %d / %d" % [correct, total]
	_pct_label.text   = "Accuracy: %.0f%%" % pct

	# Label the button differently on the last day of the week
	if day_number >= GameState.DAYS_PER_WEEK:
		_next_btn.text = "END WEEK  >"
	else:
		_next_btn.text = "NEXT DAY  >"

	show()

func _on_next_day_pressed() -> void:
	hide()
	GameState.advance_day()
