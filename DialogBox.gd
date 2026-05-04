# DialogBox.gd
# Full procedural UI — no separate scene layout needed beyond a bare Control node.
# Sits inside DialogManager's CanvasLayer; never instantiate directly.
#
# Signals (connected by DialogManager):
#   all_finished          — last step of the sequence completed
#   choice_made(id)       — player clicked a choice button

extends Control

signal all_finished
signal choice_made(choice_id: String)

# ── Tunables ──────────────────────────────────────────────────────────────────
const FONT_PATH     := "res://Ac437_IBM_BIOS.ttf"
const CHARS_PER_SEC := 38.0
const BOX_HEIGHT    := 190

# ── Palette ───────────────────────────────────────────────────────────────────
const C_BG           := Color(0.04, 0.04, 0.04, 0.93)
const C_BORDER       := Color(0.38, 0.32, 0.08)
const C_SPEAKER      := Color(0.95, 0.70, 0.10)
const C_TEXT         := Color(0.90, 0.90, 0.90)
const C_CHOICE_BG    := Color(0.10, 0.10, 0.10)
const C_CHOICE_HOVER := Color(0.28, 0.22, 0.04)
const C_CHOICE_SEL   := Color(0.20, 0.16, 0.02)

# ── State ─────────────────────────────────────────────────────────────────────
var _sequence:    Array  = []
var _step:        int    = 0
var _full_text:   String = ""
var _shown_chars: float  = 0.0
var _typing:      bool   = false
var _font:        Font   = null

# ── Node refs (all created in _build_ui) ─────────────────────────────────────
var _portrait:   TextureRect
var _name_lbl:   Label
var _text_rtl:   RichTextLabel
var _hint_lbl:   Label
var _choice_box: VBoxContainer

# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	_font = load(FONT_PATH) if ResourceLoader.exists(FONT_PATH) else null
	_build_ui()
	set_process(false)

# ── UI construction ───────────────────────────────────────────────────────────
func _build_ui() -> void:
	# Set anchors manually — set_anchors_preset can misbehave when the
	# Control lives inside a CanvasLayer owned by an autoload node.
	anchor_left   = 0.0
	anchor_right  = 1.0
	anchor_top    = 1.0
	anchor_bottom = 1.0
	offset_left   = 0.0
	offset_right  = 0.0
	offset_top    = -BOX_HEIGHT
	offset_bottom = 0.0
	mouse_filter  = Control.MOUSE_FILTER_STOP

	# Belt-and-suspenders: also force the size directly once we know
	# the viewport rect. This covers the case where anchors still
	# don't resolve on the first frame.
	await get_tree().process_frame
	var vp := get_viewport().get_visible_rect().size
	position = Vector2(0.0, vp.y - BOX_HEIGHT)
	size     = Vector2(vp.x, BOX_HEIGHT)
	# Keep it updated if the window is resized.
	get_viewport().size_changed.connect(_on_viewport_resized)

	# Background
	var bg       := Panel.new()
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color         = C_BG
	bg_style.border_color     = C_BORDER
	bg_style.border_width_top = 2
	bg.add_theme_stylebox_override("panel", bg_style)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Outer HBox: [portrait] [content vbox]
	var outer := HBoxContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.offset_left   =  14
	outer.offset_right  = -14
	outer.offset_top    =  10
	outer.offset_bottom = -10
	outer.add_theme_constant_override("separation", 14)
	add_child(outer)

	# Portrait (hidden when "" is passed for the portrait path)
	_portrait = TextureRect.new()
	_portrait.custom_minimum_size = Vector2(80, 80)
	_portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_portrait.stretch_mode        = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.expand_mode         = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_portrait.visible             = false
	outer.add_child(_portrait)

	# Content column: speaker name, text row, choices
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 6)
	outer.add_child(content)

	_name_lbl = Label.new()
	_name_lbl.add_theme_color_override("font_color", C_SPEAKER)
	_name_lbl.add_theme_font_size_override("font_size", 14)
	if _font: _name_lbl.add_theme_font_override("font", _font)
	content.add_child(_name_lbl)

	# Text row: RTL body + ▼ hint
	var text_row := HBoxContainer.new()
	text_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_row.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	text_row.add_theme_constant_override("separation", 4)
	content.add_child(text_row)

	_text_rtl = RichTextLabel.new()
	_text_rtl.bbcode_enabled             = false
	_text_rtl.scroll_active              = false
	_text_rtl.autowrap_mode              = TextServer.AUTOWRAP_WORD
	_text_rtl.size_flags_horizontal      = Control.SIZE_EXPAND_FILL
	_text_rtl.size_flags_vertical        = Control.SIZE_EXPAND_FILL
	_text_rtl.add_theme_color_override("default_color", C_TEXT)
	_text_rtl.add_theme_font_size_override("normal_font_size", 12)
	if _font: _text_rtl.add_theme_font_override("normal_font", _font)
	text_row.add_child(_text_rtl)

	_hint_lbl = Label.new()
	_hint_lbl.text                    = "▼"
	_hint_lbl.vertical_alignment      = VERTICAL_ALIGNMENT_BOTTOM
	_hint_lbl.size_flags_vertical     = Control.SIZE_SHRINK_END
	_hint_lbl.add_theme_color_override("font_color", C_SPEAKER)
	_hint_lbl.add_theme_font_size_override("font_size", 14)
	_hint_lbl.visible = false
	text_row.add_child(_hint_lbl)

	# Choices container (hidden until a step has choices)
	_choice_box = VBoxContainer.new()
	_choice_box.add_theme_constant_override("separation", 3)
	_choice_box.visible = false
	content.add_child(_choice_box)

# ── Public API ────────────────────────────────────────────────────────────────

func start_sequence(steps: Array) -> void:
	_sequence = steps
	_step     = 0
	_show_step()

# ── Step display ──────────────────────────────────────────────────────────────

func _show_step() -> void:
	if _step >= _sequence.size():
		all_finished.emit()
		return

	var entry: Dictionary = _sequence[_step]

	# Portrait
	var path: String = entry.get("portrait", "")
	if path != "" and ResourceLoader.exists(path):
		_portrait.texture = load(path)
		_portrait.visible = true
	else:
		_portrait.visible = false

	_name_lbl.text = entry.get("speaker", "")

	# Typewriter reset
	_full_text   = entry.get("text", "")
	_shown_chars = 0.0
	_typing      = true
	_text_rtl.text    = ""
	_hint_lbl.visible = false

	# Clear old choices
	for child in _choice_box.get_children():
		child.queue_free()
	_choice_box.visible = false

	set_process(true)

# ── Typewriter ────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	_shown_chars = minf(_shown_chars + CHARS_PER_SEC * delta, float(_full_text.length()))
	_text_rtl.text = _full_text.substr(0, int(_shown_chars))

	if int(_shown_chars) >= _full_text.length():
		_typing = false
		set_process(false)
		_on_type_done()

func _on_type_done() -> void:
	var choices: Array = _sequence[_step].get("choices", [])
	if choices.is_empty():
		_hint_lbl.visible = true
	else:
		_build_choices(choices)

# ── Choice buttons ────────────────────────────────────────────────────────────

func _build_choices(choices: Array) -> void:
	for choice in choices:
		var btn := Button.new()
		btn.text                    = ">  " + choice.get("text", "???")
		btn.size_flags_horizontal   = Control.SIZE_EXPAND_FILL
		btn.alignment               = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_color_override("font_color",       C_TEXT)
		btn.add_theme_color_override("font_hover_color", C_SPEAKER)
		btn.add_theme_font_size_override("font_size", 12)
		if _font: btn.add_theme_font_override("font", _font)

		var s := StyleBoxFlat.new()
		s.bg_color = C_CHOICE_BG; s.border_color = C_BORDER
		s.set_border_width_all(1)
		btn.add_theme_stylebox_override("normal", s)

		var sh := s.duplicate() as StyleBoxFlat
		sh.bg_color = C_CHOICE_HOVER
		btn.add_theme_stylebox_override("hover", sh)

		var sp := s.duplicate() as StyleBoxFlat
		sp.bg_color = C_CHOICE_SEL
		btn.add_theme_stylebox_override("pressed", sp)

		var cid: String = choice.get("id", "")
		btn.pressed.connect(func() -> void: _on_choice(cid))
		_choice_box.add_child(btn)

	_choice_box.visible = true

func _on_choice(choice_id: String) -> void:
	choice_made.emit(choice_id)
	_step += 1
	_show_step()

# ── Input ─────────────────────────────────────────────────────────────────────
# Using _input (not _unhandled_input) so we can consume mouse events before
# ScreenManager.gd sees them and tries to raycast into the 3D scene.

func _input(event: InputEvent) -> void:
	if not visible:
		return

	# Always swallow mouse events while the dialog is open so nothing behind
	# the box gets accidentally clicked.  Choice buttons handle their own
	# clicks via the GUI system before _input fires, so they still work.
	if event is InputEventMouseButton:
		get_viewport().set_input_as_handled()
		# Advance on left-click only when not waiting on a choice.
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT \
				and not _choice_box.visible:
			_handle_advance()
		return

	# Space / Enter to advance when no choices are showing.
	if event is InputEventKey and event.pressed and not event.echo \
			and not _choice_box.visible:
		if event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
			get_viewport().set_input_as_handled()
			_handle_advance()

func _handle_advance() -> void:
	if _typing:
		# Instant-complete the current line.
		_shown_chars   = float(_full_text.length())
		_text_rtl.text = _full_text
		_typing        = false
		set_process(false)
		_on_type_done()
	else:
		_step += 1
		_show_step()



func _on_viewport_resized() -> void:
	var vp := get_viewport().get_visible_rect().size
	position = Vector2(0.0, vp.y - BOX_HEIGHT)
	size     = Vector2(vp.x, BOX_HEIGHT)
