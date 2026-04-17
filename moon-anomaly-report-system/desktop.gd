# desktop.gd
extends Control

const CallWindowScene = preload("res://CallWindowUI.tscn")

@onready var window_layer: Control = $WindowLayer
@onready var taskbar_items: HBoxContainer = $Taskbar/TaskbarItems

var _taskbar_map: Dictionary = {}

func _ready() -> void:
	_apply_win95_style()
	# (remove the test spawn_window call that was here)

func receive_call(data: Dictionary) -> void:
	var call_ui: Control = CallWindowScene.instantiate()
	var win = spawn_window("INCOMING CALL", call_ui, Vector2(580, 524))
	win.position = Vector2(0, 0)  # anchor to top-left, no offset drift
	call_ui.setup(data)
	# ... signals unchanged
	call_ui.call_submitted.connect(func(anomaly_id: int):
		print("Filed as anomaly #", anomaly_id)
		# hook into scoring / game state here later
	)
	call_ui.call_declined.connect(func():
		print("Call declined")
	)

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
		_taskbar_map[window].button_pressed = false

func _on_window_minimized(window: Panel) -> void:
	if _taskbar_map.has(window):
		_taskbar_map[window].button_pressed = false

func _apply_win95_style() -> void:
	var taskbar_style := StyleBoxFlat.new()
	taskbar_style.bg_color = Color("#C0C0C0")
	taskbar_style.border_width_top = 2
	taskbar_style.border_color = Color("#FFFFFF")
	$Taskbar.add_theme_stylebox_override("panel", taskbar_style)
	
	


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F5:
			receive_call({
				"caller_name":   "Station 7 — Cmdr. Reyes",
				"caller_photo":  "res://ICONS/Maxwell.jpg",
				"duration":      55.0,
				"audio":         "",
				"transcription":
					"Yes, hello, this is Commander Reyes from Station Seven. "
					+ "We've had repeating seismic readings since 04:00 Lunar Hours. "
					+ "Small tremors, every three minutes. Two fuel lines are vibrating. "
					+ "Our geologist says it feels different from a normal Luna Shake.",
				"additional_details":
					"Station 7 sits 2 km from the Kepler Ridge fault zone. "
					+ "Fixed-interval seismic activity may indicate an artificial source.",
				"tasks": [
					"Ask if Volatile Regolith warnings are active nearby",
					"Check Satellite Database for recent orbital changes",
					"Confirm drill shutdown has been logged with Industrial",
				],
			})
