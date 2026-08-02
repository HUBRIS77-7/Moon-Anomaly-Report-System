# desktop.gd
extends Control

const CallWindowScene := preload("res://CallWindowUI.tscn")
const StubAppWindowScript := preload("res://StubAppWindow.gd")

const DESKTOP_SIZE := Vector2(1940, 640)
const TASKBAR_HEIGHT := 72.0
const CALL_WINDOW_SIZE := Vector2(DESKTOP_SIZE.x, DESKTOP_SIZE.y - TASKBAR_HEIGHT)
const ICON_SIZE    := Vector2(64, 64)
const ICON_SPACING := 16.0
const ICON_START   := Vector2(16, 16)

@onready var window_layer: Control = $WindowLayer
@onready var taskbar_items: HBoxContainer = $Taskbar/TaskbarItems
@onready var icon_layer: Control = $IconLayer

var _taskbar_map: Dictionary = {}     # window -> taskbar button
var _icon_buttons: Dictionary = {}    # app_id -> Button
var _app_windows: Dictionary = {}     # app_id -> Panel (currently open window)

func _ready() -> void:
	# in desktop.gd _ready()
	print("desktop actual viewport size: ", get_viewport().size)
	await get_tree().process_frame
	print("DesktopUI actual size: ", size)
	icon_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE 
	_apply_win95_style()
	_build_icon_layer()
	GameState.app_unlocked.connect(_on_app_unlocked)

# ── Desktop icons ─────────────────────────────────────────────────────────────

func _build_icon_layer() -> void:
	for child in icon_layer.get_children():
		child.queue_free()
	_icon_buttons.clear()

	for app_id: String in AppRegistry.get_all_ids():
		if GameState.is_app_unlocked(app_id):
			_add_icon(app_id)

func _on_app_unlocked(app_id: String) -> void:
	_add_icon(app_id)

func _add_icon(app_id: String) -> void:
	if _icon_buttons.has(app_id):
		return
	var app := AppRegistry.get_app(app_id)
	if app.is_empty():
		return

	var row: int = _icon_buttons.size()
	var btn := Button.new()
	btn.custom_minimum_size = ICON_SIZE
	btn.position = ICON_START + Vector2(0, row * (ICON_SIZE.y + ICON_SPACING))
	btn.focus_mode = Control.FOCUS_NONE
	btn.tooltip_text = app.get("name", app_id)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn.add_child(vbox)

	var icon_rect := ColorRect.new()
	icon_rect.custom_minimum_size = Vector2(32, 32)
	icon_rect.color = app.get("icon_color", Color.GRAY)
	icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(icon_rect)

	var label := Label.new()
	label.text = app.get("abbr", "???")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_font_size_override("font_size", 10)
	vbox.add_child(label)

	btn.gui_input.connect(_on_icon_gui_input.bind(app_id))
	icon_layer.add_child(btn)
	_icon_buttons[app_id] = btn

func _on_icon_gui_input(event: InputEvent, app_id: String) -> void:
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
		_open_app(app_id)

func _open_app(app_id: String) -> void:
	# Already open — just bring it forward instead of duplicating.
	if _app_windows.has(app_id) and is_instance_valid(_app_windows[app_id]):
		var existing: Panel = _app_windows[app_id]
		existing.show()
		existing.move_to_front()
		if _taskbar_map.has(existing):
			_taskbar_map[existing].button_pressed = true
		return

	var app := AppRegistry.get_app(app_id)
	if app.is_empty():
		return

	var content := Control.new()
	content.set_script(StubAppWindowScript)
	var win := spawn_window(app.get("name", "Untitled"), content, Vector2(420, 300))
	content.setup(app.get("name", app_id))

	_app_windows[app_id] = win
	win.closed.connect(func(_w): _app_windows.erase(app_id))

# ── Calls ─────────────────────────────────────────────────────────────────────

func receive_call(data: Dictionary) -> void:
	var call_ui: Control = CallWindowScene.instantiate()
	var call_window_size := window_layer.size
	if call_window_size == Vector2.ZERO:
		call_window_size = CALL_WINDOW_SIZE
	var win = spawn_window("INCOMING CALL", call_ui, call_window_size)
	win.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	win.position = Vector2.ZERO
	win.size = call_window_size
	call_ui.setup(data)

	var correct_id: int = data.get("correct_anomaly_id", -1)

	call_ui.call_submitted.connect(func(anomaly_id: int):
		var was_correct := (correct_id != -1 and anomaly_id == correct_id)
		GameState.record_call(was_correct)

		print(
			"[CALL RESULT] Filed as #%d | Correct: %s | Score: %d/%d (%.0f%%)" % [
				anomaly_id,
				"YES" if was_correct else "NO — correct was #%d" % correct_id,
				GameState.calls_correct,
				GameState.total_calls,
				GameState.accuracy_percent
			]
		)
		_destroy_window(win)
	)

	call_ui.call_declined.connect(func():
		GameState.record_decline()
		print("[CALL DECLINED] Score unchanged: %d/%d (%.0f%%)" % [
			GameState.calls_correct,
			GameState.total_calls,
			GameState.accuracy_percent
		])
	)

## Fully removes a window and its taskbar button.
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
	btn.custom_minimum_size = Vector2(220, 56)
	btn.add_theme_font_size_override("font_size", 24)
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
