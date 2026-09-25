extends CanvasLayer
## Owns manager windows and their taskbar entries.

var taskbar: Control
var _saved_bounds: Dictionary = {}


func _ready() -> void:
	child_entered_tree.connect(_on_window_added)
	child_exiting_tree.connect(_on_window_removed)
	get_viewport().size_changed.connect(_fit_maximized_windows)


func _on_window_added(window: Node) -> void:
	if taskbar != null and window is CanvasItem:
		taskbar.add_window_tab(window as CanvasItem)


func _on_window_removed(window: Node) -> void:
	_saved_bounds.erase(window.get_instance_id())
	if taskbar != null:
		taskbar.remove_window_tab(window)


func minimize_window(window: CanvasItem) -> void:
	window.hide()
	if taskbar != null:
		taskbar.update_window_tab(window)


func restore_window(window: CanvasItem) -> void:
	window.show()
	window.move_to_front()
	if taskbar != null:
		taskbar.update_window_tab(window)


func toggle_fullscreen(window: CanvasItem, panel: Control) -> void:
	var id := window.get_instance_id()
	if _saved_bounds.has(id):
		var saved: Dictionary = _saved_bounds[id]
		panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		panel.scale = saved["scale"]
		panel.position = saved["position"]
		panel.size = saved["size"]
		_saved_bounds.erase(id)
	else:
		_saved_bounds[id] = {"position": panel.position, "size": panel.size, "scale": panel.scale}
		panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		panel.scale = Vector2.ONE
		panel.position = Vector2.ZERO
		panel.size = get_viewport().get_visible_rect().size
	if window.has_method("_sync_resize_handle"):
		window.call("_sync_resize_handle")


func _fit_maximized_windows() -> void:
	for window in get_children():
		if _saved_bounds.has(window.get_instance_id()):
			var panel := window as Control
			if panel == null:
				panel = window.get_node_or_null("EditorUI/PanelContainer") as Control
			if panel != null:
				panel.size = get_viewport().get_visible_rect().size
