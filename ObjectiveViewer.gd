# ObjectiveViewer.gd — Autoload as "ObjectiveViewer"
# Non-diegetic overlay HUD that shows the current post-call task, if any.
# Purely reactive to GameState signals — it has no idea HOW a task gets
# completed. That's the point: TaskLocationTrigger, TaskInteractable, a
# dialog choice, a terminal app — anything calling GameState.complete_task()
# drives this the same way.

extends CanvasLayer

const FONT_PATH := "res://Ac437_IBM_BIOS.ttf"

const C_BG     := Color(0.04, 0.04, 0.04, 0.88)
const C_BORDER := Color(0.38, 0.32, 0.08)
const C_TITLE  := Color(0.95, 0.70, 0.10)
const C_TEXT   := Color(0.90, 0.90, 0.90)
const C_DONE   := Color(0.45, 0.85, 0.45)

const PANEL_WIDTH  := 360.0
const PANEL_MARGIN := 16.0

var _font: Font = null
var _panel: Panel
var _header_lbl: Label
var _title_lbl: Label
var _desc_lbl: Label
var _fade_tween: Tween = null

func _ready() -> void:
	layer = 32   # under DialogBox (64) and DayEndScreen (128)
	if ResourceLoader.exists(FONT_PATH):
		_font = load(FONT_PATH)
	_build_ui()
	_set_panel_visible(false)

	GameState.task_assigned.connect(_on_task_assigned)
	GameState.task_completed.connect(_on_task_completed)
	GameState.day_started.connect(_on_day_started)

func _build_ui() -> void:
	_panel = Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color            = C_BG
	style.border_color        = C_BORDER
	style.set_border_width_all(1)
	style.set_content_margin_all(14)
	_panel.add_theme_stylebox_override("panel", style)
	_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_panel.position = Vector2(PANEL_MARGIN, PANEL_MARGIN)
	_panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0)
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 4)
	_panel.add_child(vbox)

	_header_lbl = _make_label("OBJECTIVE", 12, C_TITLE)
	vbox.add_child(_header_lbl)

	_title_lbl = _make_label("", 16, C_TEXT)
	_title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(_title_lbl)

	_desc_lbl = _make_label("", 13, C_TEXT)
	_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	_desc_lbl.modulate.a = 0.8
	vbox.add_child(_desc_lbl)

func _make_label(text: String, size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", size)
	if _font:
		lbl.add_theme_font_override("font", _font)
	return lbl

# ── Signal handlers ────────────────────────────────────────────────────────

func _on_task_assigned(task_id: String) -> void:
	var task: Dictionary = TaskDatabase.get_task(task_id)
	if task.is_empty():
		return
	_header_lbl.text = "OBJECTIVE"
	_header_lbl.add_theme_color_override("font_color", C_TITLE)
	_title_lbl.text = task.get("title", "")
	_desc_lbl.text  = task.get("description", "")
	_fade_in()

func _on_task_completed(_task_id: String) -> void:
	_header_lbl.text = "OBJECTIVE COMPLETE"
	_header_lbl.add_theme_color_override("font_color", C_DONE)
	await get_tree().create_timer(2.5).timeout
	_fade_out()

func _on_day_started(_day: int) -> void:
	_set_panel_visible(false)

# ── Show / hide ──────────────────────────────────────────────────────────────

func _fade_in() -> void:
	if _fade_tween and _fade_tween.is_running():
		_fade_tween.kill()
	_panel.show()
	_panel.modulate.a = 0.0
	_fade_tween = create_tween()
	_fade_tween.tween_property(_panel, "modulate:a", 1.0, 0.35)

func _fade_out() -> void:
	if _fade_tween and _fade_tween.is_running():
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(_panel, "modulate:a", 0.0, 0.35)
	_fade_tween.finished.connect(func(): _panel.hide(), CONNECT_ONE_SHOT)

func _set_panel_visible(v: bool) -> void:
	if _fade_tween and _fade_tween.is_running():
		_fade_tween.kill()
	_panel.visible = v
	_panel.modulate.a = 1.0 if v else 0.0
