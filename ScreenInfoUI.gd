# ScreenInfoUI.gd
# Full anomaly-database readout screen, projected onto the DatabaseComputer
# mesh. Replaces the old ScreenInfoUI + ScreenPanelUI split — that split
# existed to fit the deprecated L-shaped NEWLSHAPE screen. This screen now
# owns entry navigation itself; there's no separate panel viewport to
# delegate to.
#
# Design resolution: 1940x1080.

extends Control

signal entry_changed(entry: Dictionary)

const FONT_PATH := "res://Ac437_IBM_BIOS.ttf"

const DESIGN_W := 1940
const DESIGN_H := 1080

const PAD := 24
const GAP := 20

const C_BG     := Color(0.04, 0.04, 0.04)
const C_PANEL  := Color(0.08, 0.08, 0.08)
const C_BORDER := Color(0.22, 0.22, 0.22)
const C_TEXT   := Color(0.90, 0.90, 0.90)
const C_DIM    := Color(0.45, 0.45, 0.45)
const C_AMBER  := Color(0.95, 0.70, 0.10)
const C_RED    := Color(0.85, 0.15, 0.15)
const SEG_ON   := Color(0.0, 0.9, 0.2)
const SEG_OFF  := Color(0.1, 0.1, 0.1)

const FS_NAME    := 40
const FS_META    := 22
const FS_SECTION := 20
const FS_BODY    := 24
const FS_BTN     := 24

var _font: Font = null

var current_id: int = 1
var current_category: AnomalyDatabase.Category = AnomalyDatabase.Category.ALL

var _photo_rect:       TextureRect
var _name_label:       Label
var _number_label:     Label
var _sev_segs:         Array = []
var _dng_segs:         Array = []
var _scl_segs:         Array = []
var _type_label:       Label
var _subtype_label:    Label
var _description_rtl:  RichTextLabel
var _solution_rtl:     RichTextLabel
var _category_label:   Label
var _number_field:     LineEdit
var _current_id_label: Label

func _ready() -> void:
	custom_minimum_size = Vector2(DESIGN_W, DESIGN_H)
	if ResourceLoader.exists(FONT_PATH):
		_font = load(FONT_PATH)
	_build_ui()
	_load_entry(current_id)

# ── Layout construction ────────────────────────────────────────────────────

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var photo_w: float = 380.0
	var photo_h: float = DESIGN_H - PAD * 2.0

	var right_x: float = PAD + photo_w + GAP
	var right_w: float = DESIGN_W - right_x - PAD

	var header_h: float = 190.0

	var body_y: float = PAD + header_h + GAP
	var body_h: float = DESIGN_H - body_y - PAD

	var main_w: float = roundf(right_w * 0.60)
	var side_w: float = right_w - main_w - GAP
	var side_x: float = right_x + main_w + GAP

	_build_photo(Rect2(PAD, PAD, photo_w, photo_h))
	_build_header(Rect2(right_x, PAD, right_w, header_h))
	_build_main_column(Rect2(right_x, body_y, main_w, body_h))
	_build_side_column(Rect2(side_x, body_y, side_w, body_h))

func _build_photo(r: Rect2) -> void:
	var panel := _make_panel(C_PANEL, C_BORDER)
	panel.position = r.position
	panel.size = r.size
	add_child(panel)

	_photo_rect = TextureRect.new()
	_photo_rect.position = Vector2(8, 8)
	_photo_rect.size = r.size - Vector2(16, 16)
	_photo_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_photo_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	panel.add_child(_photo_rect)

func _build_header(r: Rect2) -> void:
	var panel := _make_panel(C_PANEL, C_BORDER)
	panel.position = r.position
	panel.size = r.size
	add_child(panel)

	_name_label = Label.new()
	_name_label.position = Vector2(16, 8)
	_name_label.size = Vector2(r.size.x - 260.0, 48)
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_style_label(_name_label, FS_NAME, C_TEXT)
	panel.add_child(_name_label)

	_number_label = Label.new()
	_number_label.position = Vector2(r.size.x - 240.0, 8)
	_number_label.size = Vector2(224, 32)
	_number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_style_label(_number_label, FS_META, C_DIM)
	panel.add_child(_number_label)

	var bar_y: float = 82.0
	var bar_col_w: float = (r.size.x - 32.0) / 3.0
	_sev_segs = _build_bar_group(panel, "SEVERITY", Vector2(16.0, bar_y), bar_col_w)
	_dng_segs = _build_bar_group(panel, "DANGER",   Vector2(16.0 + bar_col_w, bar_y), bar_col_w)
	_scl_segs = _build_bar_group(panel, "SCALE",    Vector2(16.0 + bar_col_w * 2.0, bar_y), bar_col_w)

func _build_bar_group(parent: Control, label_text: String, pos: Vector2, w: float) -> Array:
	var lbl := Label.new()
	lbl.position = pos
	lbl.size = Vector2(w - 16.0, 24)
	_style_label(lbl, FS_META, C_DIM)
	lbl.text = label_text
	parent.add_child(lbl)

	var row := HBoxContainer.new()
	row.position = pos + Vector2(0, 30)
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)

	var segs: Array = []
	for i in range(5):
		var seg := ColorRect.new()
		seg.custom_minimum_size = Vector2(38, 20)
		seg.color = SEG_OFF
		row.add_child(seg)
		segs.append(seg)
	return segs

func _build_main_column(r: Rect2) -> void:
	var type_row_h: float = 70.0

	var type_panel := _make_panel(C_PANEL, C_BORDER)
	type_panel.position = r.position
	type_panel.size = Vector2(r.size.x, type_row_h)
	add_child(type_panel)

	_type_label = Label.new()
	_type_label.position = Vector2(16, 8)
	_type_label.size = Vector2(r.size.x * 0.5 - 24.0, 54)
	_style_label(_type_label, FS_BODY, C_TEXT)
	type_panel.add_child(_type_label)

	_subtype_label = Label.new()
	_subtype_label.position = Vector2(r.size.x * 0.5 + 8.0, 8)
	_subtype_label.size = Vector2(r.size.x * 0.5 - 24.0, 54)
	_style_label(_subtype_label, FS_BODY, C_TEXT)
	type_panel.add_child(_subtype_label)

	var desc_y: float = r.position.y + type_row_h + GAP
	var desc_h: float = r.size.y - type_row_h - GAP

	var desc_panel := _make_panel(C_PANEL, C_BORDER)
	desc_panel.position = Vector2(r.position.x, desc_y)
	desc_panel.size = Vector2(r.size.x, desc_h)
	add_child(desc_panel)

	var desc_hdr := _make_section_header("DESCRIPTION")
	desc_hdr.position = Vector2(0, 0)
	desc_hdr.size = Vector2(r.size.x, 36)
	desc_panel.add_child(desc_hdr)

	_description_rtl = RichTextLabel.new()
	_description_rtl.position = Vector2(16, 44)
	_description_rtl.size = Vector2(r.size.x - 32.0, desc_h - 56.0)
	_description_rtl.bbcode_enabled = false
	_description_rtl.scroll_active = true
	_description_rtl.autowrap_mode = TextServer.AUTOWRAP_WORD
	_style_rtl(_description_rtl, FS_BODY, C_TEXT)
	desc_panel.add_child(_description_rtl)

func _build_side_column(r: Rect2) -> void:
	var solution_h: float = roundf(r.size.y * 0.55)
	var nav_h: float = r.size.y - solution_h - GAP

	# ── Solution info ──────────────────────────────────────────────────────
	var sol_panel := _make_panel(C_PANEL, C_BORDER)
	sol_panel.position = r.position
	sol_panel.size = Vector2(r.size.x, solution_h)
	add_child(sol_panel)

	var sol_hdr := _make_section_header("SOLUTION INFORMATION")
	sol_hdr.position = Vector2(0, 0)
	sol_hdr.size = Vector2(r.size.x, 36)
	sol_panel.add_child(sol_hdr)

	_solution_rtl = RichTextLabel.new()
	_solution_rtl.position = Vector2(16, 44)
	_solution_rtl.size = Vector2(r.size.x - 32.0, solution_h - 56.0)
	_solution_rtl.bbcode_enabled = false
	_solution_rtl.scroll_active = true
	_solution_rtl.autowrap_mode = TextServer.AUTOWRAP_WORD
	_style_rtl(_solution_rtl, FS_BODY, C_DIM)
	sol_panel.add_child(_solution_rtl)

	# ── Filter + navigation ────────────────────────────────────────────────
	var nav_y: float = r.position.y + solution_h + GAP
	var nav_panel := _make_panel(C_PANEL, C_BORDER)
	nav_panel.position = Vector2(r.position.x, nav_y)
	nav_panel.size = Vector2(r.size.x, nav_h)
	add_child(nav_panel)

	var filter_hdr := _make_section_header("FILTER BY TYPE")
	filter_hdr.position = Vector2(0, 0)
	filter_hdr.size = Vector2(r.size.x, 36)
	nav_panel.add_child(filter_hdr)

	var cat_row := HBoxContainer.new()
	cat_row.position = Vector2(16, 44)
	cat_row.size = Vector2(r.size.x - 32.0, 48)
	cat_row.add_theme_constant_override("separation", 12)
	nav_panel.add_child(cat_row)

	var cat_left := _make_button("<", C_TEXT, C_PANEL)
	cat_left.custom_minimum_size = Vector2(48, 44)
	cat_left.pressed.connect(_cycle_category.bind(-1))
	cat_row.add_child(cat_left)

	_category_label = Label.new()
	_category_label.custom_minimum_size = Vector2(200, 44)
	_category_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_category_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_style_label(_category_label, FS_BODY, C_AMBER)
	cat_row.add_child(_category_label)

	var cat_right := _make_button(">", C_TEXT, C_PANEL)
	cat_right.custom_minimum_size = Vector2(48, 44)
	cat_right.pressed.connect(_cycle_category.bind(1))
	cat_row.add_child(cat_right)

	var nav_hdr := _make_section_header("NAVIGATE BY ENTRY #")
	nav_hdr.position = Vector2(0, 100)
	nav_hdr.size = Vector2(r.size.x, 36)
	nav_panel.add_child(nav_hdr)

	_number_field = LineEdit.new()
	_number_field.position = Vector2(16, 144)
	_number_field.size = Vector2(r.size.x - 32.0, 44)
	_number_field.placeholder_text = "ENTRY #"
	_number_field.add_theme_font_size_override("font_size", FS_BODY)
	if _font:
		_number_field.add_theme_font_override("font", _font)
	_number_field.text_submitted.connect(_on_number_submitted)
	nav_panel.add_child(_number_field)

	var nav_row := HBoxContainer.new()
	nav_row.position = Vector2(16, 196)
	nav_row.size = Vector2(r.size.x - 32.0, 48)
	nav_row.add_theme_constant_override("separation", 12)
	nav_panel.add_child(nav_row)

	var nav_left := _make_button("<", C_TEXT, C_PANEL)
	nav_left.custom_minimum_size = Vector2(48, 44)
	nav_left.pressed.connect(_navigate.bind(-1))
	nav_row.add_child(nav_left)

	_current_id_label = Label.new()
	_current_id_label.custom_minimum_size = Vector2(200, 44)
	_current_id_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_current_id_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_style_label(_current_id_label, FS_BODY, C_TEXT)
	nav_row.add_child(_current_id_label)

	var nav_right := _make_button(">", C_TEXT, C_PANEL)
	nav_right.custom_minimum_size = Vector2(48, 44)
	nav_right.pressed.connect(_navigate.bind(1))
	nav_row.add_child(nav_right)

# ── Entry loading ────────────────────────────────────────────────────────────

func _load_entry(id: int) -> void:
	current_id = id
	if _current_id_label:
		_current_id_label.text = str(id)
	if _number_field:
		_number_field.text = str(id)

	var entry: Dictionary = AnomalyDatabase.get_entry(id)
	if entry.has("status"):
		_show_status(entry["status"])
	else:
		_populate(entry)
	entry_changed.emit(entry)

func _navigate(direction: int) -> void:
	var next_id: int = AnomalyDatabase.get_next_id(current_id, direction, current_category)
	_load_entry(next_id)

func _cycle_category(direction: int) -> void:
	var max_cat: int = AnomalyDatabase.Category.size() - 1
	var cat_int: int = wrapi(int(current_category) + direction, 0, max_cat + 1)
	current_category = cat_int as AnomalyDatabase.Category
	_category_label.text = AnomalyDatabase.get_category_name(current_category)

func _on_number_submitted(text: String) -> void:
	var id: int = text.strip_edges().to_int()
	if id > 0:
		_load_entry(id)
	else:
		_number_field.text = str(current_id)

# ── Display ───────────────────────────────────────────────────────────────────

func _populate(entry: Dictionary) -> void:
	_name_label.modulate = Color.WHITE
	_name_label.text = entry.get("name", "---")
	_number_label.text = "ENTRY #" + str(entry.get("id", current_id))

	var category: AnomalyDatabase.Category = entry.get("category", AnomalyDatabase.Category.ALL)
	var subtype: AnomalyDatabase.Category = entry.get("type", AnomalyDatabase.Category.ALL)
	_type_label.text = "TYPE:\n" + AnomalyDatabase.get_category_name(category)
	_subtype_label.text = "SUB-TYPE:\n" + AnomalyDatabase.get_category_name(subtype)

	_set_bar(_sev_segs, entry.get("severity", 0))
	_set_bar(_dng_segs, entry.get("danger", 0))
	_set_bar(_scl_segs, entry.get("scale", 0))

	_description_rtl.text = entry.get("description", "")

	var solution: String = entry.get("solution", "")
	if solution.is_empty():
		_solution_rtl.text = "NO SOLUTION DATA ON FILE.\nPENDING DATABASE UPDATE."
		_solution_rtl.add_theme_color_override("default_color", C_DIM)
	else:
		_solution_rtl.text = solution
		_solution_rtl.add_theme_color_override("default_color", C_TEXT)

	var icon_path: String = entry.get("icon_path", "")
	if icon_path != "" and ResourceLoader.exists(icon_path):
		_photo_rect.texture = load(icon_path)
	else:
		_photo_rect.texture = _default_photo_texture()

func _show_status(status: String) -> void:
	_clear_display()
	match status:
		AnomalyDatabase.NOT_FOUND:
			_name_label.text = "NOT FOUND"
			_name_label.modulate = C_RED
		AnomalyDatabase.NOT_ACCESSIBLE:
			_name_label.text = "NOT ACCESSIBLE"
			_name_label.modulate = C_RED

func _clear_display() -> void:
	_name_label.text = "---"
	_name_label.modulate = Color.WHITE
	_number_label.text = ""
	_type_label.text = ""
	_subtype_label.text = ""
	_description_rtl.text = ""
	_solution_rtl.text = ""
	_set_bar(_sev_segs, 0)
	_set_bar(_dng_segs, 0)
	_set_bar(_scl_segs, 0)
	_photo_rect.texture = _default_photo_texture()

func _set_bar(segs: Array, value: int) -> void:
	for i in range(segs.size()):
		segs[i].color = SEG_ON if i < value else SEG_OFF

# ── Style helpers ────────────────────────────────────────────────────────────

func _make_panel(bg: Color, border: Color) -> Panel:
	var p := Panel.new()
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(0)
	p.add_theme_stylebox_override("panel", s)
	return p

func _make_section_header(title_text: String) -> ColorRect:
	var bar := ColorRect.new()
	bar.color = Color(0.16, 0.16, 0.16)
	var lbl := Label.new()
	lbl.text = title_text
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_style_label(lbl, FS_SECTION, C_AMBER)
	bar.add_child(lbl)
	return bar

func _make_button(label_text: String, fg: Color, bg: Color) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.add_theme_color_override("font_color", fg)
	btn.add_theme_color_override("font_hover_color", fg.lightened(0.2))
	btn.add_theme_font_size_override("font_size", FS_BTN)
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
	return btn

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

func _default_photo_texture() -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_RGB8)
	img.fill(Color(0.18, 0.18, 0.18))
	return ImageTexture.create_from_image(img)
