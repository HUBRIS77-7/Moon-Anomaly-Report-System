# DayEndScreen.gd
# Autoload this as "DayEndScreen" in Project Settings → Autoload.
# It is a CanvasLayer so it renders above the entire 3-D scene.
# Connects to GameState.day_ended automatically on startup.

extends CanvasLayer

const FONT_PATH := "res://Ac437_IBM_BIOS.ttf"

var _bg:          ColorRect
var _day_label:   Label
var _score_label: Label
var _pct_label:   Label
var _next_btn:    Button
var _vbox:        VBoxContainer   # kept so we can recentre it

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	layer = 128
	_build_ui()
	hide()
	GameState.day_ended.connect(_on_day_ended)

# ── UI construction ───────────────────────────────────────────────────────────

func _build_ui() -> void:
	var font: Font = null
	if ResourceLoader.exists(FONT_PATH):
		font = load(FONT_PATH)

	# Full-screen black background — direct child of CanvasLayer, fills viewport
	_bg = ColorRect.new()
	_bg.color = Color(0, 0, 0, 1)
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)

	# VBoxContainer floats freely; _recentre_vbox positions it after layout
	_vbox = VBoxContainer.new()
	_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_vbox.add_theme_constant_override("separation", 24)
	add_child(_vbox)

	# Re-centre whenever the background (= viewport size) or vbox size changes
	_bg.resized.connect(_recentre_vbox)
	_vbox.resized.connect(_recentre_vbox)

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

	_day_label   = _make_label.call("DAY 1 COMPLETE",       28, Color(0.95, 0.70, 0.10))
	_score_label = _make_label.call("Calls correct: 0 / 0", 20, Color(0.90, 0.90, 0.90))
	_pct_label   = _make_label.call("Accuracy: 0%",         20, Color(0.90, 0.90, 0.90))

	_vbox.add_child(_day_label)
	_vbox.add_child(_score_label)
	_vbox.add_child(_pct_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	_vbox.add_child(spacer)

	_next_btn = Button.new()
	_next_btn.text = "NEXT DAY  >"
	_next_btn.custom_minimum_size = Vector2(220, 48)
	_next_btn.add_theme_font_size_override("font_size", 20)
	if font:
		_next_btn.add_theme_font_override("font", font)
	_next_btn.pressed.connect(_on_next_day_pressed)

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

	_vbox.add_child(_next_btn)

	# Defer first centre pass so the layout has resolved sizes
	_recentre_vbox.call_deferred()

# ── Centring ──────────────────────────────────────────────────────────────────

func _recentre_vbox() -> void:
	if _vbox == null or _bg == null:
		return
	_vbox.position = ((_bg.size - _vbox.size) * 0.5).floor()

# ── Signal handlers ───────────────────────────────────────────────────────────

func _on_day_ended(day_number: int, correct: int, total: int) -> void:
	var pct := 0.0
	if total > 0:
		pct = (float(correct) / float(total)) * 100.0

	_day_label.text   = "DAY %d COMPLETE" % day_number
	_score_label.text = "Calls correct: %d / %d" % [correct, total]
	_pct_label.text   = "Accuracy: %.0f%%" % pct
	_next_btn.text    = "END WEEK  >" if day_number >= GameState.DAYS_PER_WEEK else "NEXT DAY  >"

	show()
	_recentre_vbox.call_deferred()

func _on_next_day_pressed() -> void:
	hide()
	GameState.advance_day()
