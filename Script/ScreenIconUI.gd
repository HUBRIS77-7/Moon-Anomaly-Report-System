# ScreenIconUI.gd
extends Control

@onready var icon_texture: TextureRect = $TextureRect

func connect_to_panel(panel: Control) -> void:
	panel.entry_changed.connect(_on_entry_changed)

func _on_entry_changed(entry: Dictionary) -> void:
	if entry.has("status") or entry.get("icon_path", "") == "":
		icon_texture.texture = null
		return
	icon_texture.texture = load(entry["icon_path"])
