extends "res://Scripts/PanelControls/WindowButton.gd"
## WindowManager remembers the original bounds for the next click.
func _on_pressed() -> void:
	var window := _manager_window(&"toggle_fullscreen")
	if window == null:
		return
	var panel := window as Control
	# Program Editor has a Node2D root and a separate visible panel.
	if panel == null:
		panel = window.get_node_or_null("EditorUI/PanelContainer") as Control
	if panel != null:
		window.get_parent().toggle_fullscreen(window, panel)
