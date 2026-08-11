# ScreenViewportTag.gd
# Marks a SubViewport as discoverable by ScreenManager without needing
# a hardcoded path to it.

extends SubViewport

@export var screen_id: String = ""

func _ready() -> void:
	if screen_id == "":
		push_warning("ScreenViewportTag on '%s' has no screen_id set." % name)
		return
	add_to_group("screen_viewports")
