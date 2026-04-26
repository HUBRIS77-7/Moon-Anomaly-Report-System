# GameState.gd — Autoload in Project Settings → Autoload
extends Node

# ── Signals ───────────────────────────────────────────────────────────────────
signal day_ended(day_number: int, correct: int, total: int)
signal day_started(day_number: int)

# ── Constants ─────────────────────────────────────────────────────────────────
const DAYS_PER_WEEK: int = 5

# ── Day / Week state ──────────────────────────────────────────────────────────
var current_day: int = 1
var current_week: int = 1

# ── Call tracking (reset each day) ───────────────────────────────────────────
var calls_correct:   int = 0
var calls_incorrect: int = 0
var _calls_remaining_today: int = 0

var total_calls: int:
	get: return calls_correct + calls_incorrect

var accuracy_percent: float:
	get:
		if total_calls == 0:
			return 0.0
		return (float(calls_correct) / float(total_calls)) * 100.0

# ── Seating ───────────────────────────────────────────────────────────────────
var is_seated: bool = true

# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	# CallDatabase entries are defined as class-level vars so they are
	# available immediately even though this autoload is listed first.
	_setup_day(current_day)

# ── Internal helpers ──────────────────────────────────────────────────────────
func _setup_day(day: int) -> void:
	var day_calls := CallDatabase.get_calls_for_day(day)
	_calls_remaining_today = day_calls.size()

func _decrement_remaining() -> void:
	_calls_remaining_today = max(0, _calls_remaining_today - 1)
	if _calls_remaining_today <= 0:
		day_ended.emit(current_day, calls_correct, total_calls)

# ── Public API ────────────────────────────────────────────────────────────────

## Called by desktop.gd after a call is submitted.
func record_call(was_correct: bool) -> void:
	if was_correct:
		calls_correct += 1
	else:
		calls_incorrect += 1
	_decrement_remaining()

## Called by desktop.gd when a call is declined (no score change, day still progresses).
func record_decline() -> void:
	_decrement_remaining()

## Advance to the next day. Called by DayEndScreen "Next Day" button.
func advance_day() -> void:
	current_day += 1
	if current_day > DAYS_PER_WEEK:
		current_day = 1          # Loop back for now; add week logic later
		current_week += 1

	# Reset per-day stats
	calls_correct   = 0
	calls_incorrect = 0
	_setup_day(current_day)

	day_started.emit(current_day)

func reset_stats() -> void:
	calls_correct   = 0
	calls_incorrect = 0

# ── Seating ───────────────────────────────────────────────────────────────────
func sit_down() -> void:
	is_seated = true

func stand_up() -> void:
	is_seated = false
