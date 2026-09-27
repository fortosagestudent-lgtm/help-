extends Button
## Shared behavior for the three window buttons. A window is the direct child
## of WindowManager, even when its title-bar button is nested many levels deep.
func _ready() -> void:
	pressed.connect(_on_pressed)


func _on_pressed() -> void:
	pass # Close, Minimize, and Maximize supply their own action.


func _manager_window(required_method: StringName = &"minimize_window") -> CanvasItem:
	var ancestor := get_parent()
	while ancestor != null:
		var manager := ancestor.get_parent()
		if manager is CanvasLayer and manager.has_method(required_method):
			return ancestor as CanvasItem
		ancestor = manager
	return null
