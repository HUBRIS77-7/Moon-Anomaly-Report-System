extends Control

@onready var window_layer: Control = $WindowLayer
@onready var taskbar_items: HBoxContainer = $Taskbar/TaskbarItems

var _taskbar_map: Dictionary = {}

func _ready() -> void:
	_apply_win95_style()
	# Temporary test — remove after confirming it works
	var test_label = Label.new()
	test_label.text = "Hello from a window!"
	spawn_window("Test Window", test_label, Vector2(250, 150))

func spawn_window(window_title: String, content: Control, 
		spawn_size: Vector2 = Vector2(300, 200)) -> Panel:
	var window = preload("res://DraggableWindow.tscn").instantiate()
	window_layer.add_child(window)
	window.title = window_title
	window.size = spawn_size
	# Slight offset so multiple windows don't perfectly stack
	var offset = _taskbar_map.size() * 20
	window.position = Vector2(40 + offset, 40 + offset)
	window.set_content(content)
	window.closed.connect(_on_window_closed.bind(window))
	window.minimized.connect(_on_window_minimized.bind(window))
	_add_taskbar_button(window, window_title)
	return window

func _add_taskbar_button(window: Panel, window_title: String) -> void:
	var btn := Button.new()
	btn.text = window_title
	btn.custom_minimum_size = Vector2(100, 28)
	btn.toggle_mode = true
	btn.button_pressed = true
	btn.pressed.connect(_on_taskbar_pressed.bind(window, btn))
	taskbar_items.add_child(btn)
	_taskbar_map[window] = btn

func _on_taskbar_pressed(window: Panel, btn: Button) -> void:
	if window.visible:
		window.hide()
		btn.button_pressed = false
	else:
		window.show()
		window.move_to_front()
		btn.button_pressed = true

func _on_window_closed(window: Panel) -> void:
	if _taskbar_map.has(window):
		_taskbar_map[window].queue_free()
		_taskbar_map.erase(window)

func _on_window_minimized(window: Panel) -> void:
	if _taskbar_map.has(window):
		_taskbar_map[window].button_pressed = false

func _apply_win95_style() -> void:
	var taskbar_style := StyleBoxFlat.new()
	taskbar_style.bg_color = Color("#C0C0C0")
	taskbar_style.border_width_top = 2
	taskbar_style.border_color = Color("#FFFFFF")
	$Taskbar.add_theme_stylebox_override("panel", taskbar_style)
