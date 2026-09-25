extends Button
## Attach to Full inside a manager opened in OpenWindows.

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	var window := _manager_window()
	if window == null:
		return
	var panel := window as Control
	if panel == null:
		panel = window.get_node_or_null("EditorUI/PanelContainer") as Control
	if panel != null:
		window.get_parent().toggle_fullscreen(window, panel)

func _manager_window() -> CanvasItem:
	var ancestor := get_parent()
	while ancestor != null:
		if ancestor.get_parent() is CanvasLayer and ancestor.get_parent().has_method("toggle_fullscreen"):
			return ancestor as CanvasItem
		ancestor = ancestor.get_parent()
	return null
