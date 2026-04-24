# GameState.gd — Autoload in Project Settings → Autoload
extends Node

var is_seated: bool = true

# ── Call tracking ─────────────────────────────────────────────────────────────
var calls_correct:   int = 0
var calls_incorrect: int = 0

var total_calls: int:
	get: return calls_correct + calls_incorrect

var accuracy_percent: float:
	get:
		if total_calls == 0:
			return 0.0
		return (float(calls_correct) / float(total_calls)) * 100.0

func record_call(was_correct: bool) -> void:
	if was_correct:
		calls_correct += 1
	else:
		calls_incorrect += 1

func reset_stats() -> void:
	calls_correct   = 0
	calls_incorrect = 0

# ── Seating ───────────────────────────────────────────────────────────────────
func sit_down() -> void:
	is_seated = true

func stand_up() -> void:
	is_seated = false
