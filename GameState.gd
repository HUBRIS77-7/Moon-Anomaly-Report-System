# GameState.gd — Autoload in Project Settings → Autoload
extends Node

# ── Signals ───────────────────────────────────────────────────────────────────
signal day_ended(day_number: int, correct: int, total: int, credits_earned: int)
signal day_started(day_number: int)
## Emitted after any call is submitted or declined. themoon.gd listens to this
## to know when to start the next-icon countdown.
signal call_completed

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

# ── Currency ──────────────────────────────────────────────────────────────────
var lunar_credits: int = 0
var last_day_credits_earned: int = 0

## Base pay is 50 LC. Accuracy bonus scales up to 450 LC at 100%.
## Total range: 50 LC (0%) → 500 LC (100%).
func calculate_credits(correct: int, total: int) -> int:
	var pct := 0.0
	if total > 0:
		pct = (float(correct) / float(total)) * 100.0
	return 50 + roundi(pct * 4.5)

# ── Seating ───────────────────────────────────────────────────────────────────
var is_seated: bool = true

# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	_setup_day(current_day)

# ── Internal helpers ──────────────────────────────────────────────────────────
func _setup_day(day: int) -> void:
	var day_calls := CallDatabase.get_calls_for_day(day)
	_calls_remaining_today = day_calls.size()

func _decrement_remaining() -> void:
	_calls_remaining_today = max(0, _calls_remaining_today - 1)
	if _calls_remaining_today <= 0:
		last_day_credits_earned = calculate_credits(calls_correct, total_calls)
		lunar_credits += last_day_credits_earned
		day_ended.emit(current_day, calls_correct, total_calls, last_day_credits_earned)

# ── Public API ────────────────────────────────────────────────────────────────

## Called by desktop.gd after a call is submitted.
func record_call(was_correct: bool) -> void:
	if was_correct:
		calls_correct += 1
	else:
		calls_incorrect += 1
	call_completed.emit()
	_decrement_remaining()

## Called by desktop.gd when a call is declined (no score change, day still progresses).
func record_decline() -> void:
	call_completed.emit()
	_decrement_remaining()

## Advance to the next day. Called by DayEndScreen "Next Day" button.
func advance_day() -> void:
	current_day += 1
	if current_day > DAYS_PER_WEEK:
		current_day = 1
		current_week += 1

	calls_correct   = 0
	calls_incorrect = 0
	_setup_day(current_day)

	day_started.emit(current_day)

func reset_stats() -> void:
	calls_correct   = 0
	calls_incorrect = 0

func sit_down() -> void:
	is_seated = true

func stand_up() -> void:
	is_seated = false
