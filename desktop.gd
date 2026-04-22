# desktop.gd
extends Control

const CallWindowScene = preload("res://CallWindowUI.tscn")

@onready var window_layer: Control = $WindowLayer
@onready var taskbar_items: HBoxContainer = $Taskbar/TaskbarItems

var _taskbar_map: Dictionary = {}

func _ready() -> void:
	_apply_win95_style()

func receive_call(data: Dictionary) -> void:
	var call_ui: Control = CallWindowScene.instantiate()
	var win = spawn_window("INCOMING CALL", call_ui, Vector2(580, 524))
	win.position = Vector2(0, 0)
	call_ui.setup(data)

	var correct_id: int = data.get("correct_anomaly_id", -1)

	call_ui.call_submitted.connect(func(anomaly_id: int):
		# ── Record result ─────────────────────────────────────────────────────
		var was_correct := (correct_id != -1 and anomaly_id == correct_id)
		GameState.record_call(was_correct)

		var total    := GameState.total_calls
		var accuracy := GameState.accuracy_percent
		print(
			"[CALL RESULT] Filed as #%d | Correct: %s | Score: %d/%d (%.0f%%)" % [
				anomaly_id,
				"YES" if was_correct else "NO — correct was #%d" % correct_id,
				GameState.calls_correct,
				total,
				accuracy
			]
		)
		_destroy_window(win)
	)

	call_ui.call_declined.connect(func():
		print("[CALL DECLINED] Score unchanged: %d/%d (%.0f%%)" % [
			GameState.calls_correct,
			GameState.total_calls,
			GameState.accuracy_percent
		])
	)

## Fully removes a window and its taskbar button.
## Only called on submit — close and minimize deliberately leave the entry intact.
func _destroy_window(window: Panel) -> void:
	if _taskbar_map.has(window):
		_taskbar_map[window].queue_free()
		_taskbar_map.erase(window)
	window.queue_free()

func spawn_window(window_title: String, content: Control,
		spawn_size: Vector2 = Vector2(300, 200)) -> Panel:
	var window = preload("res://DraggableWindow.tscn").instantiate()
	window_layer.add_child(window)
	window.title = window_title
	window.size = spawn_size
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
			var db := get_node("/root/CallDatabase")
			if db.has_next_call():
				receive_call(db.next_call())
