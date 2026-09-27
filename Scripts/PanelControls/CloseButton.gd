extends "res://Scripts/PanelControls/WindowButton.gd"
## Closing frees the whole window; WindowManager removes its taskbar entry.
func _on_pressed() -> void:
	var window := _manager_window()
	if window != null:
		window.queue_free()
