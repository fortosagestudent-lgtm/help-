extends "res://Scripts/PanelControls/WindowButton.gd"
## Hiding keeps the window alive so its taskbar tab can restore it.
func _on_pressed() -> void:
	var window := _manager_window()
	if window != null:
		window.get_parent().minimize_window(window)
