# DialogManager.gd
# ── AUTOLOAD SETUP ────────────────────────────────────────────────────────────
# Project Settings → Autoload → add as "DialogManager"
# Order: GameState → AnomalyDatabase → CallDatabase → DialogDatabase → DialogManager
#
# ── USAGE ─────────────────────────────────────────────────────────────────────
#   DialogManager.play("sequence_id")         # trigger a sequence by id
#   DialogManager.is_active()                 # check if dialog is running
#   DialogManager.dialog_finished.connect(fn) # notified when sequence ends
#   DialogManager.choice_selected.connect(fn) # notified on each choice
#
# ── DATA ──────────────────────────────────────────────────────────────────────
# All sequences live in DialogDatabase.gd — this file is purely mechanical.

extends Node

# ── Signals ───────────────────────────────────────────────────────────────────
## Emitted when a sequence begins.
signal dialog_started(sequence_id: String)

## Emitted when the last step of a sequence finishes.
signal dialog_finished(sequence_id: String)

## Emitted each time the player selects a choice button.
## choice_id is the "id" value set in the choice dict in DialogDatabase.
signal choice_selected(sequence_id: String, choice_id: String)

# ── Private state ─────────────────────────────────────────────────────────────
var _box:        Control = null
var _current_id: String  = ""
var _is_active:  bool    = false

# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	# Build a CanvasLayer parented to this autoload node.
	# Because autoloads are children of /root, this appears above the game scene
	# but we use layer = 64 so it sits under DayEndScreen (layer 128).
	var layer      := CanvasLayer.new()
	layer.layer    =  64
	layer.name     = "DialogLayer"
	add_child(layer)

	_box = preload("res://DialogBox.tscn").instantiate()
	layer.add_child(_box)
	_box.hide()
	_box.all_finished.connect(_on_all_finished)
	_box.choice_made.connect(_on_choice_made)

	# Day 1 fires on launch (GameState doesn't emit day_started for the initial day).
	if GameState.current_day == 1:
		# Wait one frame so the 3D scene and other autoloads finish _ready,
		# then a short extra delay so the player sees the scene before dialog starts.
		await get_tree().process_frame
		await get_tree().create_timer(0.8).timeout
		_play_day_start(1)

	GameState.day_started.connect(_on_day_started)

# ── Public API ────────────────────────────────────────────────────────────────

## Play a sequence by id. Does nothing if dialog is already active.
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

## Stop any active dialog immediately (use sparingly — prefer letting it finish).
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
		# Play the first matching sequence. If you want multiple back-to-back,
		# chain them via the dialog_finished signal externally.
		_start(seq)
		return

func _on_day_started(day: int) -> void:
	# Short delay so the day transition settles before dialog appears.
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
