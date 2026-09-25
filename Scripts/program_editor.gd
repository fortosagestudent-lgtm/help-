extends Node2D

@onready var panel: PanelContainer = $EditorUI/PanelContainer
@onready var resize_handle: Button = $EditorUI/ResizeHandle
@onready var graph: GraphEdit = $EditorUI/PanelContainer/MarginContainer/MainLayout/EditorBody/EditorContent/ProgramGraph
@onready var component_selector: OptionButton = $EditorUI/PanelContainer/MarginContainer/MainLayout/EditorBody/EditorContent/BuildToolbar/ComponentSelector
@onready var build_button: Button = $EditorUI/PanelContainer/MarginContainer/MainLayout/EditorBody/EditorContent/BuildToolbar/BuildComponentButton
@onready var status_hint: Label = $EditorUI/PanelContainer/MarginContainer/MainLayout/Footer/BuildAreaHint

@export_range(0.1, 10.0, 0.1) var program_tick_seconds := 1.0

const ProgramComponent = preload("res://Scripts/Components/ProgramComponent.gd")
const COMPONENT_SCRIPTS = {
	"Server": preload("res://Scripts/Components/Server.gd"),
	"Router": preload("res://Scripts/Components/Router.gd"),
	"Power": preload("res://Scripts/Components/Power.gd"),
	"CPU": preload("res://Scripts/Components/Cpu.gd"),
	"GPU": preload("res://Scripts/Components/Gpu.gd"),
	"File Selector": preload("res://Scripts/Components/FileSelector.gd"),
	"File Uploader": preload("res://Scripts/Components/FileUploader.gd")
}

var computer: Computer
var program_data: Dictionary = {}
var program_name := "Program 1"
var program_timer: Timer
var next_component_id := 1
func _ready() -> void:
	_center_editor()
	panel.resized.connect(_sync_resize_handle)
	get_viewport().size_changed.connect(_fit_window)
	call_deferred("_sync_resize_handle")
	var save_button := get_node_or_null("EditorUI/PanelContainer/MarginContainer/MainLayout/Header/SaveButton")
	if save_button != null:
		save_button.pressed.connect(_on_save_button_pressed)
	build_button.pressed.connect(_on_build_component_pressed)
	$EditorUI/PanelContainer/MarginContainer/MainLayout/Header/StartButton.pressed.connect(start_program)
	$EditorUI/PanelContainer/MarginContainer/MainLayout/Header/StopButton.pressed.connect(stop_program)
	$EditorUI/PanelContainer/MarginContainer/MainLayout/Footer/ClearButton.pressed.connect(clear_graph)
	graph.connection_request.connect(_on_connection_request)
	graph.disconnection_request.connect(_on_disconnection_request)
	program_timer = Timer.new()
	program_timer.wait_time = maxf(program_tick_seconds, 0.1)
	program_timer.timeout.connect(_on_program_tick)
	add_child(program_timer)


func _center_editor() -> void:
	panel.position = ((get_viewport_rect().size - panel.size * panel.scale) * 0.5).max(Vector2.ZERO)
	_sync_resize_handle()


func _sync_resize_handle() -> void:
	resize_handle.position = panel.position + panel.size * panel.scale - resize_handle.size


func _fit_window() -> void:
	var viewport_size := get_viewport_rect().size
	panel.position = panel.position.clamp(Vector2.ZERO, (viewport_size - panel.size * panel.scale).max(Vector2.ZERO))
	_sync_resize_handle()


func set_computer(target: Computer) -> void:
	computer = target
	var title := get_node_or_null("EditorUI/PanelContainer/MarginContainer/MainLayout/Header/Title")
	if title != null:
		title.text = "Program Builder - %s" % computer.name
	var hardware_selector := get_node_or_null("EditorUI/PanelContainer/MarginContainer/MainLayout/EditorBody/EditorContent/BuildToolbar/HardwareSelector") as OptionButton
	if hardware_selector != null:
		hardware_selector.set_item_text(0, computer.name)
		hardware_selector.disabled = true
	for saved in computer.programs:
		if str(saved.get("name", "")) == program_name:
			program_data = saved.get("data", {}).duplicate(true)
			_load_program_data()
			break


func _on_build_component_pressed() -> void:
	var kind := component_selector.get_item_text(component_selector.selected)
	var offset := Vector2(80 + ((next_component_id - 1) % 8) * 30, 80 + ((next_component_id - 1) % 8) * 30)
	_create_component(kind, "", graph.scroll_offset + offset)


func _create_component(kind: String, component_name: String, graph_position: Vector2) -> ProgramComponent:
	var component_script: GDScript = COMPONENT_SCRIPTS.get(kind)
	if component_script == null:
		return null
	var component: ProgramComponent = component_script.new()
	component.name = component_name if not component_name.is_empty() else "Component_%d" % next_component_id
	graph.add_child(component)
	component.position_offset = graph_position
	next_component_id += 1
	return component


func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	if from_node == to_node:
		return
	for connection in graph.get_connection_list():
		if connection["to_node"] == to_node and int(connection["to_port"]) == to_port:
			status_hint.text = "That input already has a connection."
			return
	graph.connect_node(from_node, from_port, to_node, to_port)
	status_hint.text = "Connected. Press Start to run the program."


func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	graph.disconnect_node(from_node, from_port, to_node, to_port)


func start_program() -> void:
	if not program_timer.is_stopped():
		return
	if not is_instance_valid(computer):
		status_hint.text = "Open this editor from a computer to run the program."
		return
	if not computer.is_powered:
		status_hint.text = "This computer is powered off."
		return
	_on_program_tick()
	program_timer.start()


func stop_program() -> void:
	program_timer.stop()
	status_hint.text = "Stopped."


func clear_graph() -> void:
	stop_program()
	graph.clear_connections()
	for child in graph.get_children():
		if child is ProgramComponent:
			graph.remove_child(child)
			child.queue_free()
	next_component_id = 1
	status_hint.text = "Graph cleared."


func _on_program_tick() -> void:
	if not is_instance_valid(computer) or not computer.is_powered:
		stop_program()
		return
	var cache: Dictionary = {}
	var visiting: Dictionary = {}
	for child in graph.get_children():
		if child is ProgramComponent:
			_evaluate_component(child, cache, visiting)
	var uploaded := 0.0
	for child in graph.get_children():
		if child is ProgramComponent and child.get_kind() == "File Uploader":
			uploaded += child.uploaded_files
	status_hint.text = "Running — %.1f test files uploaded" % uploaded


func _evaluate_component(component: ProgramComponent, cache: Dictionary, visiting: Dictionary) -> Dictionary:
	var component_name := str(component.name)
	if cache.has(component_name):
		return cache[component_name]
	if visiting.has(component_name):
		status_hint.text = "Connection loop detected. Remove a wire."
		return {}
	visiting[component_name] = true
	var inputs: Dictionary = {}
	for connection in graph.get_connection_list():
		if str(connection["to_node"]) != component_name:
			continue
		var source := graph.get_node_or_null(str(connection["from_node"])) as ProgramComponent
		if source == null:
			continue
		var from_port := int(connection["from_port"])
		var to_port := int(connection["to_port"])
		var output_names := source.get_output_ports()
		var input_names := component.get_input_ports()
		if from_port >= output_names.size() or to_port >= input_names.size():
			continue
		var source_values := _evaluate_component(source, cache, visiting)
		var input_name := input_names[to_port]
		inputs[input_name] = float(inputs.get(input_name, 0.0)) + float(source_values.get(output_names[from_port], 0.0))
	visiting.erase(component_name)
	var outputs := component.evaluate(computer, inputs, program_timer.wait_time)
	cache[component_name] = outputs
	return outputs


func _capture_program_data() -> Dictionary:
	var nodes: Array[Dictionary] = []
	for child in graph.get_children():
		if child is ProgramComponent:
			nodes.append({
				"kind": child.get_kind(), "name": str(child.name),
				"position": child.position_offset, "state": child.save_state()
			})
	return {"nodes": nodes, "connections": graph.get_connection_list().duplicate(true)}


func _load_program_data() -> void:
	clear_graph()
	for entry in program_data.get("nodes", []):
		var component := _create_component(str(entry.get("kind", "")), str(entry.get("name", "")), entry.get("position", Vector2(80, 80)))
		if component != null:
			component.load_state(entry.get("state", {}))
	for connection in program_data.get("connections", []):
		graph.connect_node(
			StringName(connection.get("from_node", "")), int(connection.get("from_port", 0)),
			StringName(connection.get("to_node", "")), int(connection.get("to_port", 0))
		)
	status_hint.text = "Loaded %s from this computer." % program_name


func save_current_program() -> bool:
	if not is_instance_valid(computer):
		push_warning("Cannot save: this program editor has no computer assigned.")
		return false

	program_data = _capture_program_data()
	computer.save_program(program_name, program_data)
	status_hint.text = "Saved %s on this computer." % program_name
	return true


func _on_save_button_pressed() -> void:
	var name_input := get_node_or_null("EditorUI/PanelContainer/MarginContainer/MainLayout/Header/ProgramName")
	if name_input != null and not name_input.text.strip_edges().is_empty():
		program_name = name_input.text.strip_edges()
	save_current_program()
