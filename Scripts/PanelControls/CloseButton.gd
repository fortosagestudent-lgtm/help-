extends Button
## Attach to Close inside a manager opened in OpenWindows.

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	var window := _manager_window()
	if window != null:
		window.queue_free()

func _manager_window() -> CanvasItem:
	var ancestor := get_parent()
	while ancestor != null:
		if ancestor.get_parent() is CanvasLayer and ancestor.get_parent().has_method("minimize_window"):
			return ancestor as CanvasItem
		ancestor = ancestor.get_parent()
	return null
