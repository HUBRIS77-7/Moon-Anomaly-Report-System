extends Panel

signal closed(window)
signal minimized(window)

var _dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO

var _maximized: bool = false
var _pre_max_position: Vector2 = Vector2.ZERO
var _pre_max_size: Vector2 = Vector2.ZERO

@onready var title_label: Label = $TitleBar/TitleLabel
@onready var close_btn: Button = $TitleBar/CloseButton
@onready var minimize_btn: Button = $TitleBar/MinimizeButton
@onready var maximize_btn: Button = $TitleBar/MaximizeButton
@onready var title_bar: Control = $TitleBar
@onready var title_bar_bg: ColorRect = $TitleBarBg
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
	maximize_btn.pressed.connect(toggle_maximize)
	title_bar.gui_input.connect(_on_titlebar_input)
	_apply_win95_style()

func _on_titlebar_input(event: InputEvent) -> void:
	if _maximized:
		return  # don't let dragging fight with a maximized window
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			_drag_offset = get_global_mouse_position() - global_position
			move_to_front()
		else:
			_dragging = false
	elif event is InputEventMouseMotion and _dragging:
		var new_pos = get_global_mouse_position() - _drag_offset
		# Clamp so window can't be dragged off screen
		var parent_size = get_parent().size
		new_pos.x = clamp(new_pos.x, 0, parent_size.x - size.x)
		new_pos.y = clamp(new_pos.y, 0, parent_size.y - size.y)
		global_position = new_pos

func _on_close() -> void:
	closed.emit(self)
	hide()

func _on_minimize() -> void:
	minimized.emit(self)
	hide()

## Toggles between the window's normal size/position and filling its parent.
func toggle_maximize() -> void:
	if _maximized:
		size = _pre_max_size
		position = _pre_max_position
		_maximized = false
		maximize_btn.text = "□"
	else:
		_pre_max_position = position
		_pre_max_size = size
		position = Vector2.ZERO
		size = get_parent().size
		_maximized = true
		maximize_btn.text = "❐"
	move_to_front()

func set_content(content: Control) -> void:
	for child in content_area.get_children():
		child.queue_free()
	content_area.add_child(content)
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _apply_win95_style() -> void:
	# Main window grey background
	var window_style := StyleBoxFlat.new()
	window_style.bg_color = Color("#C0C0C0")
	window_style.border_width_left = 2
	window_style.border_width_top = 2
	window_style.border_width_right = 2
	window_style.border_width_bottom = 2
	window_style.border_color = Color("#FFFFFF")
	add_theme_stylebox_override("panel", window_style)

	# Blue title bar — drawn on TitleBarBg (a plain ColorRect), NOT on
	# TitleBar itself. TitleBar is an HBoxContainer, which has no "panel"
	# stylebox slot to draw into — a stylebox override on it is a silent
	# no-op. Previously the bar only appeared because it happened to sit
	# over this window's own grey background; that's fragile and broke
	# once window sizing changed. This makes it render unconditionally.
	title_bar_bg.color = Color("#000080")

	# Title text
	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_label.add_theme_font_size_override("font_size", 28)

	# Buttons
	for btn in [close_btn, minimize_btn, maximize_btn]:
		var btn_style := StyleBoxFlat.new()
		btn_style.bg_color = Color("#C0C0C0")
		btn_style.border_width_left = 2
		btn_style.border_width_top = 2
		btn_style.border_width_right = 2
		btn_style.border_width_bottom = 2
		btn_style.border_color = Color("#808080")
		btn.add_theme_stylebox_override("normal", btn_style)
		btn.add_theme_font_size_override("font_size", 22)
