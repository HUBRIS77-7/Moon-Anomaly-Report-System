# GameState.gd — Autoload in Project Settings → Autoload
extends Node

# ── Signals ───────────────────────────────────────────────────────────────────
signal day_ended(day_number: int, correct: int, total: int, credits_earned: int)
signal day_started(day_number: int)
## Emitted once the day is actually ready for calls to start coming in — either
## immediately after day_started (no day-start task for this day), or once a
## pending day-start task is completed. themoon.gd waits on this instead of
## day_started so it doesn't spawn call icons before a morning task is done.
signal day_ready(day_number: int)
## Emitted after any call is submitted or declined. themoon.gd listens to this
## to know when to start the next-icon countdown.
signal call_completed
signal app_unlocked(app_id: String)

## ── Post-call task gating ─────────────────────────────────────────────────
## On some days, once every call is handled, TaskDatabase may have a
## "day_end" task registered for that day. If so, day_ended is HELD BACK —
## task_assigned fires instead, and day_ended only fires once something calls
## complete_task() with the matching id. If TaskDatabase has nothing for
## that day, behavior is unchanged: day_ended fires immediately, same as
## before this system existed.
##
## ── Pre-call task gating ──────────────────────────────────────────────────
## Symmetric to the above but at the start of the day: if TaskDatabase has a
## "day_start" task for the day, task_assigned fires and day_ready is held
## back until complete_task() is called with the matching id. Otherwise
## day_ready fires immediately after day_started, same as before this
## system existed.
signal task_assigned(task_id: String)
signal task_completed(task_id: String)

# ── Constants ─────────────────────────────────────────────────────────────────
const DAYS_PER_WEEK: int = 5

# ── Day / Week state ──────────────────────────────────────────────────────────
var current_day: int = 1
var current_week: int = 1
var current_week_id: String = "training"

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

# ── Post-call task state ──────────────────────────────────────────────────────
## "" when no task is currently pending completion.
var current_task_id: String = ""
var _day_end_pending: bool = false

# ── Pre-call (day-start) task state ───────────────────────────────────────────
var current_start_task_id: String = ""
var _day_start_pending: bool = false

## Whether call icons / anything gated on the day being "ready" should wait.
func is_day_start_pending() -> bool:
	return _day_start_pending

#---APPs----------------------------------------------------------------------------
var unlocked_apps: Array[String] = []

func is_app_unlocked(app_id: String) -> bool:
	return unlocked_apps.has(app_id)

func _refresh_unlocked_apps() -> void:
	var past_training: bool = current_week_id != WeekDatabase.TRAINING_WEEK_ID
	for app_id: String in AppRegistry.get_all_ids():
		if unlocked_apps.has(app_id):
			continue
		var unlock_day: int = AppRegistry.get_unlock_day(app_id)
		if past_training or current_day >= unlock_day:
			unlocked_apps.append(app_id)
			app_unlocked.emit(app_id)


# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	_setup_day(current_day)
	_refresh_unlocked_apps()
	call_deferred("_check_day_start_task")

# ── Internal helpers ──────────────────────────────────────────────────────────
func _setup_day(day: int) -> void:
	# Route through WeekDatabase so required + random-draw calls are counted.
	var day_calls: Array[Dictionary] = WeekDatabase.draw_calls_for_day(current_week_id, day)
	_calls_remaining_today = day_calls.size()

func _decrement_remaining() -> void:
	_calls_remaining_today = max(0, _calls_remaining_today - 1)
	if _calls_remaining_today <= 0:
		last_day_credits_earned = calculate_credits(calls_correct, total_calls)
		lunar_credits += last_day_credits_earned

		var task: Dictionary = TaskDatabase.get_end_task_for_day(current_week_id, current_day)
		if not task.is_empty():
			current_task_id = task.get("id", "")
			_day_end_pending = true
			task_assigned.emit(current_task_id)
		else:
			day_ended.emit(current_day, calls_correct, total_calls, last_day_credits_earned)

## Checks TaskDatabase for a day-start task on the current day. If one
## exists, task_assigned fires and day_ready is held back until it's
## completed. Otherwise day_ready fires right away.
func _check_day_start_task() -> void:
	var task: Dictionary = TaskDatabase.get_start_task_for_day(current_week_id, current_day)
	if not task.is_empty():
		current_start_task_id = task.get("id", "")
		_day_start_pending = true
		task_assigned.emit(current_start_task_id)
	else:
		_day_start_pending = false
		day_ready.emit(current_day)

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

## Generic task-completion entrypoint. ANYTHING can call this — a location
## Area3D (TaskLocationTrigger.gd), an interact-prop (TaskInteractable.gd),
## a DialogManager.choice_selected callback, a button on a future BigTerminal
## app, whatever. It checks the day-start slot first, then the day-end slot;
## if task_id doesn't match either active task, it's a silent no-op, so it's
## always safe to call.
func complete_task(task_id: String) -> void:
	if task_id == "":
		return

	if task_id == current_start_task_id:
		task_completed.emit(current_start_task_id)
		current_start_task_id = ""
		if _day_start_pending:
			_day_start_pending = false
			day_ready.emit(current_day)
		return

	if task_id == current_task_id:
		task_completed.emit(current_task_id)
		current_task_id = ""
		if _day_end_pending:
			_day_end_pending = false
			day_ended.emit(current_day, calls_correct, total_calls, last_day_credits_earned)

## Advance to the next day. Called by DayEndScreen "Next Day" button.
func advance_day() -> void:
	current_day += 1
	if current_day > DAYS_PER_WEEK:
		current_day = 1
		current_week += 1

	calls_correct       = 0
	calls_incorrect     = 0
	current_task_id      = ""
	_day_end_pending      = false
	current_start_task_id = ""
	_day_start_pending     = false
	_setup_day(current_day)
	_refresh_unlocked_apps()

	day_started.emit(current_day)
	_check_day_start_task()

func reset_stats() -> void:
	calls_correct   = 0
	calls_incorrect = 0

func sit_down() -> void:
	is_seated = true

func stand_up() -> void:
	is_seated = false
