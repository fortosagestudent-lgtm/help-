extends SceneTree

var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)


func _build_transfer(computer: Computer) -> Node:
	var editor = computer.open_program_editor()
	for kind in ["Server", "Router", "Power", "File Selector", "File Uploader"]:
		editor._create_component(kind, kind.replace(" ", ""), Vector2.ZERO)
	var graph: GraphEdit = editor.graph
	graph.connect_node("Server", 0, "Router", 0)
	graph.connect_node("Power", 0, "Router", 1)
	graph.connect_node("Router", 0, "FileSelector", 0)
	graph.connect_node("FileSelector", 0, "FileUploader", 0)
	graph.connect_node("Router", 1, "FileUploader", 1)
	return editor


func _settle() -> void:
	for frame in range(5):
		await process_frame


func _run() -> void:
	if change_scene_to_file("res://computer.tscn") != OK:
		quit(1)
		return
	await scene_changed
	var computer := current_scene as Computer
	computer.cpu_timer.stop()
	computer.gpu_timer.stop()
	computer.ram_timer.stop()
	var power_after_start := computer.power
	for tick in range(20):
		computer._on_network_timer_timeout()
		computer._on_cpu_timer_timeout()
		computer._on_gpu_timer_timeout()
	_check(computer.network_speed == 0.0 and computer.cpu_output == 0.0 and computer.gpu_output == 0.0, "Idle resources stay at zero")
	var editor = _build_transfer(computer)
	var selector = editor.graph.get_node("FileSelector")
	_check(selector.get_input_ports() == ["download"] and selector.get_input_port_count() == 1, "File Selector exposes only its download input")
	_check(selector.get_output_ports() == ["file"], "File output is preserved")
	_check(computer.network_speed == 0.0, "Building a program does not create traffic")
	editor.start_program()
	_check(is_equal_approx(computer.download_speed, 1.0) and is_equal_approx(computer.upload_speed, 1.0), "Transfers run without any CPU or GPU nodes")
	_check(editor.graph.get_node("FileUploader").uploaded_files > 0.0, "Download-only selector supplies real files to the uploader")
	_check(computer.cpu_output == 0.0 and computer.gpu_output == 0.0, "File selection consumes no CPU or GPU")
	for tick in range(20):
		editor._on_program_tick()
		computer._on_network_timer_timeout()
	_check(is_equal_approx(computer.network_speed, 2.0), "Repeated ticks replace rates instead of accumulating")
	_check(computer.power == power_after_start, "Traffic sampling does not drain more power")
	var router = editor.graph.get_node("Router")
	router.download_share = 0.125
	editor._on_program_tick()
	_check(is_equal_approx(computer.network_speed, 0.5), "Slower downloads reduce file and upload rates")
	router.download_share = 0.5
	editor._on_program_tick()
	_check(is_equal_approx(computer.network_speed, 2.0), "Faster downloads raise transfer rates")
	selector.processing_multiplier = 0.0
	editor._on_program_tick()
	_check(computer.network_speed == 0.0, "Disabled selection consumes no bandwidth")
	selector.processing_multiplier = 1.0
	editor.graph.disconnect_node("Router", 0, "FileSelector", 0)
	editor._on_program_tick()
	_check(computer.network_speed == 0.0, "No download input means no selected or uploaded files")
	editor.graph.connect_node("Router", 0, "FileSelector", 0)
	editor._on_program_tick()
	var second = _build_transfer(computer)
	second.start_program()
	_check(is_equal_approx(computer.network_speed, 4.0), "Running programs contribute their actual rates")
	second.stop_program()
	_check(is_equal_approx(computer.network_speed, 2.0), "Stopping one program preserves the other report")
	second.start_program()
	second.queue_free()
	await _settle()
	_check(is_equal_approx(computer.network_speed, 2.0), "Closing a program removes its report")
	editor.stop_program()
	_check(computer.network_speed == 0.0, "Stopping the last program returns speed to zero")

	# Old saved selectors had CPU/GPU input indices 1 and 2. Load those saves
	# without invalid-port errors, retaining all valid transfer connections.
	editor._create_component("CPU", "CPU", Vector2.ZERO)
	editor._create_component("GPU", "GPU", Vector2.ZERO)
	var saved: Dictionary = editor._capture_program_data()
	saved["connections"].append({"from_node": "CPU", "from_port": 0, "to_node": "FileSelector", "to_port": 1})
	saved["connections"].append({"from_node": "GPU", "from_port": 0, "to_node": "FileSelector", "to_port": 2})
	editor.program_data = saved
	editor._load_program_data()
	_check(editor.graph.get_connection_list().size() == 5, "Older saves retain valid wires and drop obsolete CPU/GPU wires")
	editor.start_program()
	_check(is_equal_approx(computer.network_speed, 2.0), "Migrated program still transfers files")
	_check(computer.cpu_output == 0.0 and computer.gpu_output == 0.0, "Unused CPU/GPU nodes do not create usage")
	computer.get_node("Ui/Taskbar")._on_system_settings_pressed()
	await _settle()
	var metrics := computer.get_node("OpenWindows/SystemSettings/TabContainer/Summary/PanelContainer/VBoxContainer/TabContainer/Summary/VBoxContainer")
	_check(metrics.get_node("NeworkSpeed").text == "Current Network Speed: 2.0/s", "Summary displays current transfer speed")
	_check(metrics.get_node("CurrentCPu").text == "Current CPU Usage: 0.0/s" and metrics.get_node("CurrentGpu").text == "Current GPU Usage: 0.0/s", "Summary shows no compute requirement for file selection")
	if OS.get_cmdline_user_args().has("--visual-check"):
		computer.get_node("OpenWindows/SystemSettings").hide()
		var graph: GraphEdit = editor.graph
		graph.scroll_offset = Vector2.ZERO
		graph.zoom = 1.0
		var file_selector: Control = graph.get_node("FileSelector")
		file_selector.position_offset = Vector2(80, 80)
		for child in graph.get_children():
			if child is GraphNode and child != file_selector:
				child.position_offset = Vector2(2200, 2200)
		await _settle()
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/file-selector-download-only.png")
	editor.stop_program()
	_check(computer.network_speed == 0.0, "Stopping the migrated program clears rates")
	editor.start_program()
	computer.is_powered = false
	computer._on_network_timer_timeout()
	computer._on_cpu_timer_timeout()
	computer._on_gpu_timer_timeout()
	_check(computer.network_speed == 0.0 and computer.cpu_output == 0.0 and computer.gpu_output == 0.0, "Power-off clears resource usage")
	computer.is_powered = true
	computer.create_network_speed()
	_check(computer.network_speed == 0.0, "Restart does not restore stale traffic")
	editor._on_program_tick()
	computer.stop_network()
	editor._on_program_tick()
	_check(computer.network_speed == 0.0, "Stopped network cannot supply downloads")
	editor.queue_free()
	await _settle()
	print("NETWORK_ACTIVITY_CHECK: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
