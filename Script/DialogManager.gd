extends Node

# ── Signals ───────────────────────────────────────────────────────────────────
signal dialog_started(sequence_id: String)
signal dialog_finished(sequence_id: String)
signal choice_selected(sequence_id: String, choice_id: String)

# ── Private state ─────────────────────────────────────────────────────────────
var _box:        Control = null
var _current_id: String  = ""
var _is_active:  bool    = false
var _day1_intro_played: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	var layer      := CanvasLayer.new()
	layer.layer    =  64
	layer.name     = "DialogLayer"
	add_child(layer)

	_box = preload("res://DialogBox.tscn").instantiate()
	layer.add_child(_box)
	_box.hide()
	_box.all_finished.connect(_on_all_finished)
	_box.choice_made.connect(_on_choice_made)

	# Day 1's intro no longer auto-fires on launch — it waits for the player
	# to physically enter the PrimaryRoom. See trigger_day1_intro() below,
	# called by PrimaryRoomEntryTrigger.gd.
	GameState.day_started.connect(_on_day_started)

# ── Public API ────────────────────────────────────────────────────────────────

func play(id: String) -> void:
	if _is_active:
		push_warning("DialogManager: already playing '%s' — ignoring play('%s')" \
			% [_current_id, id])
		return

	var seq: Dictionary = DialogDatabase.get_sequence(id)
	if seq.is_empty():
		push_warning("DialogManager: no sequence found for id '%s'" % id)
		return

	_start(seq)

func stop() -> void:
	if not _is_active:
		return
	_box.hide()
	var finished_id := _current_id
	_is_active  = false
	_current_id = ""
	dialog_finished.emit(finished_id)

func is_active() -> bool:
	return _is_active

## Called by a room-entry trigger (PrimaryRoomEntryTrigger.gd) once the
## player walks into the PrimaryRoom. No-op if already played, or if it
## isn't day 1 anymore (e.g. the player re-enters the room on a later day).
func trigger_day1_intro() -> void:
	if _day1_intro_played or GameState.current_day != 1:
		return
	_day1_intro_played = true
	_play_day_start(1)

# ── Internal ──────────────────────────────────────────────────────────────────

func _start(seq: Dictionary) -> void:
	_current_id = seq.get("id", "")
	_is_active  = true
	_box.show()
	_box.start_sequence(seq.get("steps", []))
	dialog_started.emit(_current_id)

func _play_day_start(day: int) -> void:
	var matches: Array[Dictionary] = DialogDatabase.get_by_trigger("day_start", day)
	for seq in matches:
		_start(seq)
		return

func _on_day_started(day: int) -> void:
	await get_tree().create_timer(0.8).timeout
	_play_day_start(day)

func _on_all_finished() -> void:
	_box.hide()
	var finished_id := _current_id
	_is_active  = false
	_current_id = ""
	dialog_finished.emit(finished_id)

func _on_choice_made(choice_id: String) -> void:
	choice_selected.emit(_current_id, choice_id)
