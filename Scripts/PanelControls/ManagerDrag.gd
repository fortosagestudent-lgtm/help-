extends Node
## Drag a manager from unused panel space. Interactive controls keep their clicks.

@export var panel_path: NodePath = NodePath("..")
@export var resize_handle_path: NodePath

var panel: Control
var resize_handle: Control
var drag_mode := 0 # 0 = idle, 1 = move, 2 = resize.
var drag_start_mouse := Vector2.ZERO
var drag_start_position := Vector2.ZERO
var drag_start_size := Vector2.ZERO


func _ready() -> void:
	panel = get_node(panel_path) as Control
	if panel == null:
		push_error("ManagerDrag needs a panel_path pointing to a Control.")
		return
	panel.gui_input.connect(_on_panel_gui_input)
	_pass_background_input(panel)
	if not resize_handle_path.is_empty():
		resize_handle = get_node_or_null(resize_handle_path) as Control
		if resize_handle != null:
			resize_handle.gui_input.connect(_on_resize_handle_gui_input)


func _pass_background_input(root: Control) -> void:
	# Containers pass unused clicks up to the panel. Buttons and editors retain input.
	for child in root.get_children():
		if child is ScrollContainer:
			continue
		if child is Container:
			child.mouse_filter = Control.MOUSE_FILTER_PASS
			_pass_background_input(child)
		elif child is Label or child is NinePatchRect:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_begin_drag(1, event.global_position)
		panel.accept_event()


func _on_resize_handle_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_begin_drag(2, event.global_position)
		resize_handle.accept_event()


func _begin_drag(mode: int, mouse_position: Vector2) -> void:
	drag_mode = mode
	drag_start_mouse = mouse_position
	drag_start_position = panel.position
	drag_start_size = panel.size


func _input(event: InputEvent) -> void:
	if drag_mode == 0:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		drag_mode = 0
	elif event is InputEventMouseMotion:
		var offset: Vector2 = event.position - drag_start_mouse
		var viewport_size := panel.get_viewport_rect().size
		if drag_mode == 1:
			var maximum := (viewport_size - panel.size * panel.scale).max(Vector2.ZERO)
			panel.position = (drag_start_position + offset).clamp(Vector2.ZERO, maximum)
		else:
			var minimum := panel.get_combined_minimum_size().max(Vector2(600.0, 400.0))
			var maximum := ((viewport_size - panel.position) / panel.scale).max(minimum)
			panel.size = (drag_start_size + offset / panel.scale).clamp(minimum, maximum)
		if get_parent().has_method("_sync_resize_handle"):
			get_parent().call("_sync_resize_handle")
		get_viewport().set_input_as_handled()
