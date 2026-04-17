# GameState.gd — add as Autoload in Project Settings → Autoload
extends Node

var is_seated: bool = true

# Call these from whatever handles your chair interaction
func sit_down() -> void:
	is_seated = true

func stand_up() -> void:
	is_seated = false
