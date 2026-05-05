# CallWindowUI.gd
extends Control

signal call_submitted(anomaly_id: int)
signal call_declined

const FONT_PATH := "res://Ac437_IBM_BIOS.ttf"
@export var transcription_speed: float = 3.0

const FONT_SIZES := {
	"heading":     10,
	"caller_name": 12,
	"info":        11,
	"body":       10,
	"meta":        10,
	"submit":      12,
	"timer":       10,
}

const C_BG        := Color(0.04, 0.04, 0.04)
const C_PANEL     := Color(0.08, 0.08, 0.08)
const C_BORDER    := Color(0.22, 0.22, 0.22)
const C_TEXT      := Color(0.90, 0.90, 0.90)
const C_DIM       := Color(0.45, 0.45, 0.45)
const C_GREEN     := Color(0.0,  0.85, 0.25)
const C_RED       := Color(0.85, 0.15, 0.15)
const C_AMBER     := Color(0.95, 0.70, 0.10)
const C_SELECTED  := Color(0.10, 0.35, 0.18)
const C_BAR_BG    := Color(0.12, 0.12, 0.12)

enum Phase { INCOMING, ACTIVE, DONE }
var _phase: Phase = Phase.INCOMING

var _call_data: Dictionary = {}
var _duration: float = 60.0
var _elapsed: float = 0.0
var _transcription_full: String = ""
var _transcription_shown: int = 0
var _selected_anomaly_id: int = -1
var _tasks_checks: Array[bool] = []
var _correct_anomaly_id: int = -1

var _incoming_layer: Control
var _active_layer: Control

var _inc_photo: TextureRect
var _inc_name: Label
var _inc_accept: Button
var _inc_decline: Button

var _act_photo: TextureRect
var _act_name: Label
var _act_bar: ColorRect
var _act_bar_bg: ColorRect
var _act_time_label: Label

var _transcription_rtl: RichTextLabel
var _extra_rtl: RichTextLabel

var _tasks_vbox: VBoxContainer
var _anomaly_scroll: ScrollContainer
var _anomaly_vbox: VBoxContainer
var _submit_btn: Button

var _audio_player: AudioStreamPlayer
var _font: Font = null

# ── Public API ────────────────────────────────────────────────────────────────

func setup(data: Dictionary) -> void:
	_call_data = data
	_duration           = float(data.get("duration", 60.0))
	_transcription_full = data.get("transcription", "")
	_correct_anomaly_id = data.get("correct_anomaly_id", -1)

	var tasks: Array = data.get("tasks", [])
	_tasks_checks.clear()
	for _t in tasks:
		_tasks_checks.append(false)

	_inc_name.text = data.get("caller_name", "UNKNOWN CALLER")
	var photo_path: String = data.get("caller_photo", "")
	_set_photo(_inc_photo, photo_path)
	_set_photo(_act_photo, photo_path)
	_act_name.text = _inc_name.text

	for child in _tasks_vbox.get_children():
		child.queue_free()
	for i in range(tasks.size()):
		var row := HBoxContainer.new()
		var chk := CheckBox.new()
		chk.button_pressed = false
		chk.toggled.connect(func(val: bool): _tasks_checks[i] = val; _refresh_submit())
		_style_checkbox(chk)
		var lbl := Label.new()
		lbl.text = tasks[i]
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_label(lbl, FONT_SIZES["body"], C_TEXT)
		row.add_child(chk)
		row.add_child(lbl)
		_tasks_vbox.add_child(row)

	_extra_rtl.text = data.get("additional_details", "")

	var audio_path: String = data.get("audio", "")
	if audio_path != "" and ResourceLoader.exists(audio_path):
		_audio_player.stream = load(audio_path)

	_refresh_submit()

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	custom_minimum_size = Vector2(580, 500)
	_load_font()
	_build_background()
	_build_incoming_layer()
	_build_active_layer()
	_build_audio_player()
	_show_phase(Phase.INCOMING)

# ── Font loading ──────────────────────────────────────────────────────────────

func _load_font() -> void:
	if FONT_PATH != "" and ResourceLoader.exists(FONT_PATH):
		_font = load(FONT_PATH)

func _style_label(lbl: Label, size: int, color: Color) -> void:
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", size)
	if _font:
		lbl.add_theme_font_override("font", _font)

func _style_rtl(rtl: RichTextLabel, size: int, color: Color) -> void:
	rtl.add_theme_color_override("default_color", color)
	rtl.add_theme_font_size_override("normal_font_size", size)
	if _font:
		rtl.add_theme_font_override("normal_font", _font)

func _style_button_font(btn: Button, size: int) -> void:
	btn.add_theme_font_size_override("font_size", size)
	if _font:
		btn.add_theme_font_override("font", _font)
		

func _style_restricted_btn(btn: Button) -> void:
	btn.add_theme_color_override("font_color", Color(0.45, 0.10, 0.10))
	btn.add_theme_color_override("font_disabled_color", Color(0.45, 0.10, 0.10))
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.06, 0.04, 0.04)
	s.border_color = Color(0.25, 0.08, 0.08)
	s.set_border_width_all(0)
	btn.add_theme_stylebox_override("normal", s)
	btn.add_theme_stylebox_override("disabled", s)


# ── Helpers ───────────────────────────────────────────────────────────────────

func _set_photo(tr: TextureRect, path: String) -> void:
	if path != "" and ResourceLoader.exists(path):
		tr.texture = load(path)
	else:
		tr.texture = _default_photo_texture()

func _make_photo_slot(size_px: Vector2) -> Control:
	var container := Control.new()
	container.custom_minimum_size = size_px
	container.size = size_px
	container.clip_contents = true

	var tr := TextureRect.new()
	tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	tr.texture = _default_photo_texture()
	container.add_child(tr)

	return container

# ── Build helpers ─────────────────────────────────────────────────────────────

func _build_background() -> void:
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

func _build_audio_player() -> void:
	_audio_player = AudioStreamPlayer.new()
	add_child(_audio_player)

func _hide_scrollbars(sc: ScrollContainer) -> void:
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.vertical_scroll_mode   = ScrollContainer.SCROLL_MODE_SHOW_NEVER

# ── Incoming layer ────────────────────────────────────────────────────────────

var _inc_card: Control  # kept so we can recentre on resize

func _recentre_card() -> void:
	if _inc_card == null:
		return
	await get_tree().process_frame
	_inc_card.position = ((_incoming_layer.size - _inc_card.size) * 0.5).floor()

func _build_incoming_layer() -> void:
	_incoming_layer = Control.new()
	_incoming_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_incoming_layer)

	# Dim overlay behind the card
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.75)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_incoming_layer.add_child(overlay)

	# Card — PanelContainer auto-sizes to fit its child, then gets centred via signal
	var card := PanelContainer.new()
	var card_style := StyleBoxFlat.new()
	card_style.bg_color     = Color(0.10, 0.10, 0.10)
	card_style.border_color = C_BORDER
	card_style.set_border_width_all(1)
	card_style.set_content_margin_all(16)  # inner padding
	card.add_theme_stylebox_override("panel", card_style)
	card.custom_minimum_size = Vector2(300, 0)
	_incoming_layer.add_child(card)
	_inc_card = card

	# Re-centre whenever the layer or card changes size
	_incoming_layer.resized.connect(_recentre_card)
	card.resized.connect(_recentre_card)
	_recentre_card()

	# VBox — just a normal child; PanelContainer sizes itself around it
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	card.add_child(vbox)

	# "INCOMING CALL" heading
	var inc_lbl := Label.new()
	inc_lbl.text = "INCOMING CALL"
	inc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inc_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_label(inc_lbl, FONT_SIZES["heading"], C_AMBER)
	vbox.add_child(inc_lbl)

	# Photo — fixed 72×72, centred via its own CenterContainer row
	var photo_center := CenterContainer.new()
	photo_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(photo_center)
	var photo_slot := _make_photo_slot(Vector2(72, 72))
	photo_center.add_child(photo_slot)
	_inc_photo = photo_slot.get_child(0) as TextureRect

	# Caller name — auto-wraps if long, min width 300 so short names look good
	_inc_name = Label.new()
	_inc_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_inc_name.autowrap_mode = TextServer.AUTOWRAP_WORD
	_inc_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_inc_name.custom_minimum_size = Vector2(300, 0)
	_style_label(_inc_name, FONT_SIZES["caller_name"], C_TEXT)
	vbox.add_child(_inc_name)

	# Accept / Decline row
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 20)
	btn_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(btn_row)

	_inc_accept = _make_button("ACCEPT", C_GREEN, Color(0.02, 0.10, 0.04))
	_inc_accept.custom_minimum_size = Vector2(110, 36)
	_inc_accept.pressed.connect(_on_accept)
	btn_row.add_child(_inc_accept)

	_inc_decline = _make_button("DECLINE", C_RED, Color(0.10, 0.02, 0.02))
	_inc_decline.custom_minimum_size = Vector2(110, 36)
	_inc_decline.pressed.connect(_on_decline)
	btn_row.add_child(_inc_decline)

# ── Active layer ──────────────────────────────────────────────────────────────

func _build_active_layer() -> void:
	_active_layer = Control.new()
	_active_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_active_layer)

	const PAD   := 8
	const W     := 580
	const H     := 500
	const HDR_H := 64
	const COL_L := 320
	const COL_R := 242
	const COL_R_X := COL_L + PAD * 2

	var hdr := _make_panel(C_PANEL, C_BORDER)
	hdr.position = Vector2(PAD, PAD)
	hdr.size = Vector2(W - PAD * 2, HDR_H)
	hdr.clip_contents = true
	_active_layer.add_child(hdr)

	var act_photo_slot := _make_photo_slot(Vector2(56, 56))
	act_photo_slot.position = Vector2(4, 4)
	hdr.add_child(act_photo_slot)
	_act_photo = act_photo_slot.get_child(0) as TextureRect

	_act_name = Label.new()
	_act_name.position = Vector2(66, 4)
	_act_name.size = Vector2(220, 22)
	_style_label(_act_name, FONT_SIZES["info"], C_TEXT)
	hdr.add_child(_act_name)

	_act_bar_bg = ColorRect.new()
	_act_bar_bg.position = Vector2(66, 30)
	_act_bar_bg.size = Vector2(W - PAD * 2 - 200, 14)
	_act_bar_bg.color = C_BAR_BG
	hdr.add_child(_act_bar_bg)

	_act_bar = ColorRect.new()
	_act_bar.position = Vector2(0, 0)
	_act_bar.size = Vector2(0, 14)
	_act_bar.color = C_GREEN
	_act_bar_bg.add_child(_act_bar)

	_act_time_label = Label.new()
	_act_time_label.position = Vector2(66, 46)
	_act_time_label.size = Vector2(160, 16)
	_style_label(_act_time_label, FONT_SIZES["timer"], C_DIM)
	hdr.add_child(_act_time_label)

	const LEFT_Y  := HDR_H + PAD * 2
	const TRANS_H := 240
	const EXTRA_H := H - LEFT_Y - TRANS_H - PAD * 3 - PAD

	var trans_panel := _make_panel(C_PANEL, C_BORDER)
	trans_panel.position = Vector2(PAD, LEFT_Y)
	trans_panel.size = Vector2(COL_L, TRANS_H)
	_active_layer.add_child(trans_panel)

	var trans_hdr := _make_section_header("TRANSCRIPTION")
	trans_hdr.position = Vector2(0, 0)
	trans_hdr.size = Vector2(COL_L, 18)
	trans_panel.add_child(trans_hdr)

	var trans_scroll := ScrollContainer.new()
	trans_scroll.position = Vector2(4, 20)
	trans_scroll.size = Vector2(COL_L - 8, TRANS_H - 24)
	_hide_scrollbars(trans_scroll)
	trans_panel.add_child(trans_scroll)

	_transcription_rtl = RichTextLabel.new()
	_transcription_rtl.bbcode_enabled = false
	_transcription_rtl.scroll_active = false
	_transcription_rtl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_transcription_rtl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_transcription_rtl.custom_minimum_size = Vector2(COL_L - 20, 0)
	_transcription_rtl.autowrap_mode = TextServer.AUTOWRAP_WORD
	_style_rtl(_transcription_rtl, FONT_SIZES["body"], C_TEXT)
	trans_scroll.add_child(_transcription_rtl)

	var extra_panel := _make_panel(C_PANEL, C_BORDER)
	extra_panel.position = Vector2(PAD, LEFT_Y + TRANS_H + PAD)
	extra_panel.size = Vector2(COL_L, EXTRA_H)
	_active_layer.add_child(extra_panel)

	var extra_hdr := _make_section_header("ADDITIONAL DETAILS (NOT IN CALL)")
	extra_hdr.position = Vector2(0, 0)
	extra_hdr.size = Vector2(COL_L, 18)
	extra_panel.add_child(extra_hdr)

	_extra_rtl = RichTextLabel.new()
	_extra_rtl.position = Vector2(4, 20)
	_extra_rtl.size = Vector2(COL_L - 8, EXTRA_H - 24)
	_extra_rtl.bbcode_enabled = false
	_extra_rtl.autowrap_mode = TextServer.AUTOWRAP_WORD
	_extra_rtl.scroll_active = false
	_style_rtl(_extra_rtl, FONT_SIZES["body"], C_DIM)
	extra_panel.add_child(_extra_rtl)

	const TASKS_H := 130
	const ANOM_H  := H - LEFT_Y - TASKS_H - 48 - PAD * 4

	var tasks_panel := _make_panel(C_PANEL, C_BORDER)
	tasks_panel.position = Vector2(COL_R_X, LEFT_Y)
	tasks_panel.size = Vector2(COL_R, TASKS_H)
	_active_layer.add_child(tasks_panel)

	var tasks_hdr := _make_section_header("TASKS BEFORE SUBMIT")
	tasks_hdr.position = Vector2(0, 0)
	tasks_hdr.size = Vector2(COL_R, 18)
	tasks_panel.add_child(tasks_hdr)

	var tasks_scroll := ScrollContainer.new()
	tasks_scroll.position = Vector2(4, 20)
	tasks_scroll.size = Vector2(COL_R - 8, TASKS_H - 24)
	_hide_scrollbars(tasks_scroll)
	tasks_panel.add_child(tasks_scroll)

	_tasks_vbox = VBoxContainer.new()
	_tasks_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tasks_vbox.custom_minimum_size = Vector2(COL_R - 20, 0)
	tasks_scroll.add_child(_tasks_vbox)

	var anom_panel := _make_panel(C_PANEL, C_BORDER)
	anom_panel.position = Vector2(COL_R_X, LEFT_Y + TASKS_H + PAD)
	anom_panel.size = Vector2(COL_R, ANOM_H)
	_active_layer.add_child(anom_panel)

	var anom_hdr := _make_section_header("ANOMALY LIST")
	anom_hdr.position = Vector2(0, 0)
	anom_hdr.size = Vector2(COL_R, 18)
	anom_panel.add_child(anom_hdr)

	var search := LineEdit.new()
	search.position = Vector2(4, 20)
	search.size = Vector2(COL_R - 8, 18)
	search.placeholder_text = "search..."
	search.add_theme_font_size_override("font_size", FONT_SIZES["meta"])
	if _font:
		search.add_theme_font_override("font", _font)
	search.text_changed.connect(_on_anomaly_search)
	anom_panel.add_child(search)

	_anomaly_scroll = ScrollContainer.new()
	_anomaly_scroll.position = Vector2(4, 40)
	_anomaly_scroll.size = Vector2(COL_R - 8, ANOM_H - 44)
	_hide_scrollbars(_anomaly_scroll)
	anom_panel.add_child(_anomaly_scroll)

	_anomaly_vbox = VBoxContainer.new()
	_anomaly_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_anomaly_vbox.custom_minimum_size = Vector2(COL_R - 20, 0)
	_anomaly_vbox.add_theme_constant_override("separation", 1)
	_anomaly_scroll.add_child(_anomaly_vbox)

	_populate_anomaly_list("")

	_submit_btn = _make_button("SUBMIT REPORT", C_GREEN, Color(0.02, 0.10, 0.04))
	_submit_btn.position = Vector2(COL_R_X, H - PAD - 40)
	_submit_btn.size = Vector2(COL_R, 40)
	_submit_btn.pressed.connect(_on_submit)
	_active_layer.add_child(_submit_btn)

# ── Anomaly list ──────────────────────────────────────────────────────────────

func _populate_anomaly_list(filter: String) -> void:
	for child in _anomaly_vbox.get_children():
		child.queue_free()

	var lower := filter.to_lower()
	for entry in AnomalyDatabase.entries:
		if not entry.get("accessible", true):
			continue

		var entry_id: int = entry.get("id", -1)
		var name_str: String = entry.get("name", "")
		var unlock_day: int = entry.get("unlocked_on_day", 1)
		var is_locked: bool = GameState.current_day < unlock_day

		# Apply search filter — locked entries still show unless filtered out
		if lower != "" and name_str.to_lower().find(lower) == -1:
			if not "restricted".find(lower) != -1:
				continue

		var btn := Button.new()

		if is_locked:
			btn.text = "#%d  [RESTRICTED]" % entry_id
			btn.disabled = true
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.custom_minimum_size = Vector2(0, 20)
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.add_theme_font_size_override("font_size", FONT_SIZES["meta"])
			if _font:
				btn.add_theme_font_override("font", _font)
			_style_restricted_btn(btn)
		else:
			btn.text = "#%d  %s" % [entry_id, name_str]
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.custom_minimum_size = Vector2(0, 20)
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.add_theme_font_size_override("font_size", FONT_SIZES["meta"])
			if _font:
				btn.add_theme_font_override("font", _font)
			_style_anomaly_btn(btn, entry_id == _selected_anomaly_id)
			btn.pressed.connect(func(): _on_anomaly_selected(entry_id))

		_anomaly_vbox.add_child(btn)

func _on_anomaly_search(text: String) -> void:
	_populate_anomaly_list(text)

func _on_anomaly_selected(entry_id: int) -> void:
	_selected_anomaly_id = entry_id
	_populate_anomaly_list("")
	_refresh_submit()

# ── Phase control ─────────────────────────────────────────────────────────────

func _show_phase(phase: Phase) -> void:
	_phase = phase
	_incoming_layer.visible = (phase == Phase.INCOMING)
	_active_layer.visible   = (phase == Phase.ACTIVE)

func _on_accept() -> void:
	_show_phase(Phase.ACTIVE)
	_elapsed = 0.0
	_transcription_shown = 0
	_transcription_rtl.text = ""
	if _audio_player.stream:
		_audio_player.play()

func _on_decline() -> void:
	call_declined.emit()
	_show_phase(Phase.DONE)

func _on_submit() -> void:
	if _selected_anomaly_id == -1:
		return

	if _correct_anomaly_id != -1:
		if _selected_anomaly_id == _correct_anomaly_id:
			print("[SUBMIT] CORRECT — filed as #%d" % _selected_anomaly_id)
		else:
			print("[SUBMIT] WRONG — filed as #%d, correct was #%d" % [
				_selected_anomaly_id, _correct_anomaly_id
			])
	else:
		print("[SUBMIT] No correct answer defined. Filed as #%d" % _selected_anomaly_id)

	call_submitted.emit(_selected_anomaly_id)
	_show_phase(Phase.DONE)
	_audio_player.stop()

# ── Process ───────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if _phase != Phase.ACTIVE:
		return

	_elapsed = min(_elapsed + delta, _duration)

	var ratio: float = _elapsed / _duration if _duration > 0.0 else 1.0
	_act_bar.size.x = _act_bar_bg.size.x * ratio

	if ratio < 0.5:
		_act_bar.color = C_GREEN
	elif ratio < 0.8:
		_act_bar.color = C_AMBER
	else:
		_act_bar.color = C_RED

	var remaining := _duration - _elapsed
	_act_time_label.text = "%s  |  -%s" % [_fmt_time(_elapsed), _fmt_time(remaining)]

	var target_chars := int((_elapsed / _duration) * float(_transcription_full.length()) * transcription_speed)
	target_chars = min(target_chars, _transcription_full.length())
	if target_chars > _transcription_shown:
		_transcription_shown = target_chars
		_transcription_rtl.text = _transcription_full.substr(0, _transcription_shown)

	await get_tree().process_frame
	_transcription_rtl.scroll_to_line(_transcription_rtl.get_line_count() - 1)

func _refresh_submit() -> void:
	if _submit_btn == null:
		return
	var all_checked := true
	for v in _tasks_checks:
		if not v:
			all_checked = false
			break
	var can_submit := all_checked and _selected_anomaly_id != -1
	_submit_btn.disabled = not can_submit
	_submit_btn.modulate = Color.WHITE if can_submit else Color(0.4, 0.4, 0.4)

# ── Style helpers ─────────────────────────────────────────────────────────────

func _make_panel(bg: Color, border: Color) -> Panel:
	var p := Panel.new()
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(0)
	p.add_theme_stylebox_override("panel", s)
	return p

func _make_button(label_text: String, fg: Color, bg: Color) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.add_theme_color_override("font_color", fg)
	btn.add_theme_color_override("font_hover_color", fg.lightened(0.2))
	btn.add_theme_font_size_override("font_size", FONT_SIZES["submit"])
	if _font:
		btn.add_theme_font_override("font", _font)
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = fg
	s.set_border_width_all(1)
	btn.add_theme_stylebox_override("normal", s)
	var s_hover := s.duplicate() as StyleBoxFlat
	s_hover.bg_color = fg.darkened(0.6)
	btn.add_theme_stylebox_override("hover", s_hover)
	var s_pressed := s.duplicate() as StyleBoxFlat
	s_pressed.bg_color = fg.darkened(0.4)
	btn.add_theme_stylebox_override("pressed", s_pressed)
	return btn

func _style_checkbox(chk: CheckBox) -> void:
	chk.add_theme_color_override("font_color", C_TEXT)
	chk.add_theme_font_size_override("font_size", FONT_SIZES["body"])
	if _font:
		chk.add_theme_font_override("font", _font)

func _style_anomaly_btn(btn: Button, selected: bool) -> void:
	btn.add_theme_color_override("font_color", C_GREEN if selected else C_TEXT)
	var s := StyleBoxFlat.new()
	s.bg_color = C_SELECTED if selected else C_PANEL
	s.border_color = C_GREEN if selected else C_BORDER
	s.set_border_width_all(1 if selected else 0)
	btn.add_theme_stylebox_override("normal", s)
	var s_hover := s.duplicate() as StyleBoxFlat
	s_hover.bg_color = C_SELECTED.lightened(0.1)
	btn.add_theme_stylebox_override("hover", s_hover)

func _make_section_header(title: String) -> ColorRect:
	var bar := ColorRect.new()
	bar.color = Color(0.16, 0.16, 0.16)
	var lbl := Label.new()
	lbl.text = title
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_label(lbl, FONT_SIZES["meta"], C_AMBER)
	bar.add_child(lbl)
	return bar

func _default_photo_texture() -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_RGB8)
	img.fill(Color(0.18, 0.18, 0.18))
	return ImageTexture.create_from_image(img)

static func _fmt_time(seconds: float) -> String:
	var s := int(seconds)
	return "%d:%02d" % [s / 60, s % 60]
