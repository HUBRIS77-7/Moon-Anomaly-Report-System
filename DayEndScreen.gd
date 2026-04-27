# DayEndScreen.gd
extends CanvasLayer

const FONT_PATH := "res://Ac437_IBM_BIOS.ttf"

var _credit_tween: Tween = null
var _bg:            ColorRect
var _day_label:     Label
var _score_label:   Label
var _pct_label:     Label
var _earned_label:  Label   # credits earned this day — above next button
var _total_label:   Label   # running total — corner
var _next_btn:      Button
var _vbox:          VBoxContainer

func _ready() -> void:
	layer = 128
	_build_ui()
	hide()
	GameState.day_ended.connect(_on_day_ended)

func _build_ui() -> void:
	var font: Font = null
	if ResourceLoader.exists(FONT_PATH):
		font = load(FONT_PATH)

	_bg = ColorRect.new()
	_bg.color = Color(0, 0, 0, 1)
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)

	# ── Corner total label ────────────────────────────────────────────────────
	_total_label = Label.new()
	_total_label.text = "LC  0"
	_total_label.add_theme_color_override("font_color", Color(0.55, 0.85, 0.55))
	_total_label.add_theme_font_size_override("font_size", 14)
	if font:
		_total_label.add_theme_font_override("font", font)
	# Anchor to top-right corner
	_total_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_total_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_total_label.offset_right  = -12
	_total_label.offset_top    = 12
	_total_label.offset_left   = -160
	_total_label.offset_bottom = 34
	_total_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_total_label)

	# ── Centre vbox ───────────────────────────────────────────────────────────
	_vbox = VBoxContainer.new()
	_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_vbox.add_theme_constant_override("separation", 24)
	add_child(_vbox)

	_bg.resized.connect(_recentre_vbox)
	_vbox.resized.connect(_recentre_vbox)

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
	spacer.custom_minimum_size = Vector2(0, 8)
	_vbox.add_child(spacer)

	# Credits earned this day — sits just above the button
	_earned_label = _make_label.call("+ 0 LC", 22, Color(0.55, 0.85, 0.55))
	_vbox.add_child(_earned_label)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 8)
	_vbox.add_child(spacer2)

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
	_recentre_vbox.call_deferred()

func _recentre_vbox() -> void:
	if _vbox == null or _bg == null:
		return
	_vbox.position = ((_bg.size - _vbox.size) * 0.5).floor()

func _on_day_ended(day_number: int, correct: int, total: int, credits_earned: int) -> void:
	var pct := 0.0
	if total > 0:
		pct = (float(correct) / float(total)) * 100.0

	_day_label.text    = "DAY %d COMPLETE" % day_number
	_score_label.text  = "Calls correct: %d / %d" % [correct, total]
	_pct_label.text    = "Accuracy: %.0f%%" % pct
	_earned_label.text = "+ 0 LC"
	_total_label.text  = "LC  %d" % GameState.lunar_credits
	_next_btn.text     = "END WEEK  >" if day_number >= GameState.DAYS_PER_WEEK else "NEXT DAY  >"

	show()
	_recentre_vbox.call_deferred()
	_tick_up_credits(credits_earned)


func _tick_up_credits(target: int) -> void:
	if _credit_tween and _credit_tween.is_running():
		_credit_tween.kill()

	var counter := {"value": 0}
	var duration := clampf(target * 0.004, 0.6, 2.5)

	_credit_tween = create_tween()
	_credit_tween.set_ease(Tween.EASE_OUT)
	_credit_tween.set_trans(Tween.TRANS_CUBIC)
	_credit_tween.tween_method(
		func(v: float) -> void:
			var display := roundi(v)
			_earned_label.text = "+ %d LC" % display,
		0.0,
		float(target),
		duration
	)




func _on_next_day_pressed() -> void:
	hide()
	CallDatabase.reset_queue()
	GameState.advance_day()
