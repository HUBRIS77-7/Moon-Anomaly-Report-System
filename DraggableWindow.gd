extends Panel

signal closed(window)
signal minimized(window)

var _dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO

@export var draggable: bool = true

@export var show_title_bar: bool = true:
	set(v):
		show_title_bar = v
		if title_bar:
			_apply_title_bar_visibility()

@onready var title_label: Label = $TitleBar/TitleLabel
@onready var close_btn: Button = $TitleBar/CloseButton
@onready var minimize_btn: Button = $TitleBar/MinimizeButton
@onready var title_bar: Control = $TitleBar
@onready var content_area: Control = $ContentArea

@export var title: String = "Window":
	set(v):
		title = v
		if title_label:
			title_label.text = v

func _ready() -> void:
	title_label.text = title
	close_btn.pressed.connect(_on_close)
	minimize_btn.pressed.connect(_on_minimize)
	title_bar.gui_input.connect(_on_titlebar_input)
	_apply_win95_style()
	_apply_title_bar_visibility()

func _apply_title_bar_visibility() -> void:
	title_bar.visible = show_title_bar
	if show_title_bar:
		content_area.offset_top = 24
	else:
		content_area.offset_top = 0

func _on_titlebar_input(event: InputEvent) -> void:
	if not draggable:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			_drag_offset = get_global_mouse_position() - global_position
			move_to_front()
		else:
			_dragging = false
	elif event is InputEventMouseMotion and _dragging:
		var new_pos = get_global_mouse_position() - _drag_offset
		var parent_size = get_parent().size
		var margin = 12.0
		new_pos.x = clamp(new_pos.x, margin, max(margin, parent_size.x - size.x - margin))
		new_pos.y = clamp(new_pos.y, margin, max(margin, parent_size.y - size.y - margin))
		global_position = new_pos

func clamp_to_bounds() -> void:
	if not is_instance_valid(get_parent()):
		return
	var parent_size = get_parent().size
	var margin = 12.0
	position.x = clamp(position.x, margin, max(margin, parent_size.x - size.x - margin))
	position.y = clamp(position.y, margin, max(margin, parent_size.y - size.y - margin))

func _on_close() -> void:
	closed.emit(self)
	hide()

func _on_minimize() -> void:
	minimized.emit(self)
	hide()

func set_content(content: Control) -> void:
	for child in content_area.get_children():
		child.queue_free()
	content_area.add_child(content)
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _apply_win95_style() -> void:
	var window_style := StyleBoxFlat.new()
	window_style.bg_color = Color("#C0C0C0")
	window_style.border_width_left = 2
	window_style.border_width_top = 2
	window_style.border_width_right = 2
	window_style.border_width_bottom = 2
	window_style.border_color = Color("#FFFFFF")
	add_theme_stylebox_override("panel", window_style)

	var title_style := StyleBoxFlat.new()
	title_style.bg_color = Color("#000080")
	$TitleBar.add_theme_stylebox_override("panel", title_style)

	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_label.add_theme_font_size_override("font_size", 28)

	for btn in [close_btn, minimize_btn]:
		var btn_style := StyleBoxFlat.new()
		btn_style.bg_color = Color("#C0C0C0")
		btn_style.border_width_left = 2
		btn_style.border_width_top = 2
		btn_style.border_width_right = 2
		btn_style.border_width_bottom = 2
		btn_style.border_color = Color("#808080")
		btn.add_theme_stylebox_override("normal", btn_style)
		btn.add_theme_font_size_override("font_size", 22)
