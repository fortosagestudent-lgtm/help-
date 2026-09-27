class_name Computer
extends Node
const WallpaperStorage = preload("res://Scripts/Wallpaper/WallpaperStorage.gd")
## Owns one computer's hardware, current activity, wallpaper, and in-memory programs.
## Views read these values; program editors replace their own activity report each tick.
signal wallpaper_changed(value: Texture2D)

@export_group("Desktop")
## This computer owns its wallpaper; its desktop view listens for changes.
@export var wallpaper: Texture2D:
	set(value):
		wallpaper = value
		wallpaper_changed.emit(value)
## Optional stable save ID for computers spawned or renamed at runtime.
## Leave empty to use this computer's scene-tree path. Use a different ID per computer.
@export var wallpaper_save_id := ""



@export_group("Network")
@export var network_multi: float = 2.0
@export var router_lvl: int = 1
@export_range(0.0, 100000.0, 0.1) var power_cost_per_router_level: float = 5.0
@export_range(0.01, 10.0, 0.01) var network_tick_seconds: float = 0.1

@export_group("CPU")
@export_range(0.01, 100000.0, 0.01) var cpu_output_per_core: float = 1.0
@export_range(0.01, 100000.0, 0.01) var cpu_output_per_level: float = 1.0
@export_range(0.01, 10.0, 0.01) var cpu_tick_seconds: float = 0.1
@export_range(1, 1024, 1) var max_cpu_cores: int = 8
@export_range(1, 1000, 1) var cpu_cores: int = 1

@export_group("GPU")
@export_range(0.01, 100000.0, 0.01) var gpu_output_per_card: float = 1.0
@export_range(0.01, 100000.0, 0.01) var gpu_output_per_level: float = 1.0
@export_range(0.01, 10.0, 0.01) var gpu_tick_seconds: float = 0.1
@export_range(1, 1024, 1) var max_gpu_count: int = 4
@export_range(1, 1024, 1) var gpu_count: int = 1
@export_range(1, 1000, 1) var gpu_lvl: int = 1

@export_group("RAM")
@export_range(0.01, 100000.0, 0.01) var ram_output_per_stick: float = 1.0
@export_range(0.01, 100000.0, 0.01) var ram_output_per_level: float = 1.0
@export_range(0.01, 10.0, 0.01) var ram_tick_seconds: float = 0.1
@export_range(1, 1000, 1) var ram_lvl: int = 1
@export_range(1, 1024, 1) var max_ram_sticks: int = 8
@export_range(1, 1024, 1) var ram_sticks: int = 1

@export_group("Storage")
@export_range(0.01, 100000.0, 0.01) var storage_per_drive: float = 128.0
@export_range(0.01, 100000.0, 0.01) var storage_per_level: float = 1.0
@export_range(1, 1000, 1) var storage_lvl: int = 1
@export_range(1, 1024, 1) var max_storage_drives: int = 4
@export_range(1, 1024, 1) var storage_drives: int = 1

@export_group("Power")
@export_range(1, 1000, 1) var power_lvl: int = 1
@export_range(0.1, 100000.0, 0.1) var power_capacity_per_level: float = 100.0
@export_range(0.1, 100000.0, 0.1) var max_power: float = 100.0
@export_range(0.0, 100000.0, 0.1) var power: float = 100.0

const PROGRAM_EDITOR_SCENE: PackedScene = preload("res://Scenes/program_editor.tscn")

var programs: Array[Dictionary] = []
var upload_speed: float = 0.0
var download_speed: float = 0.0
# Each running program owns one traffic report. Rates are replaced each tick,
# not accumulated, and removed when that program stops or closes.
var _network_activity: Dictionary = {}
var _network_running := false
var _compute_activity: Dictionary = {}
var cpu_lvl: int = 1
var cpu_output: float = 0.0
var gpu_output: float = 0.0
var ram_output: float = 0.0
var is_powered: bool = true
var network_timer: Timer
var cpu_timer: Timer
var gpu_timer: Timer
var ram_timer: Timer

# Derived values use the current hardware/activity rather than a second stored copy.
var network_speed: float:
	get:
		return upload_speed + download_speed

var storage_capacity: float:
	get:
		return float(storage_lvl) * float(storage_drives) * storage_per_drive * storage_per_level


func _enter_tree() -> void:
	# Initialize before child views enter: saved choice, Inspector override, shared default.
	if wallpaper == null:
		wallpaper = WorldConstants.default_wallpaper
	var saved := WallpaperStorage.load_wallpaper(wallpaper_storage_directory())
	if saved != null:
		wallpaper = saved


func set_wallpaper(value: Texture2D) -> Error:
	var result := WallpaperStorage.save_wallpaper(wallpaper_storage_directory(), value)
	if result == OK:
		wallpaper = value
	return result


func _ready() -> void:
	power_lvl = maxi(power_lvl, 1)
	max_power = power_capacity_per_level * float(power_lvl)
	max_power = maxf(max_power, 0.1)
	power = clampf(power, 0.0, max_power)
	max_cpu_cores = maxi(max_cpu_cores, 1)
	cpu_cores = clampi(cpu_cores, 1, max_cpu_cores)
	max_gpu_count = maxi(max_gpu_count, 1)
	gpu_count = clampi(gpu_count, 1, max_gpu_count)
	max_ram_sticks = maxi(max_ram_sticks, 1)
	ram_sticks = clampi(ram_sticks, 1, max_ram_sticks)
	max_storage_drives = maxi(max_storage_drives, 1)
	storage_drives = clampi(storage_drives, 1, max_storage_drives)
	network_timer = _create_resource_timer(network_tick_seconds, _on_network_timer_timeout)
	cpu_timer = _create_resource_timer(cpu_tick_seconds, _on_cpu_timer_timeout)
	gpu_timer = _create_resource_timer(gpu_tick_seconds, _on_gpu_timer_timeout)
	ram_timer = _create_resource_timer(ram_tick_seconds, _on_ram_timer_timeout)
	create_network_speed()
	create_cpu_output()
	create_gpu_output()
	create_ram_output()


func wallpaper_storage_directory() -> String:
	var identity := wallpaper_save_id if not wallpaper_save_id.is_empty() else str(get_path())
	return "user://computers/" + identity.sha256_text() + "/wallpaper"


# Each hardware timer keeps its exported interval; only construction is shared.
func _create_resource_timer(interval: float, callback: Callable) -> Timer:
	var resource_timer := Timer.new()
	resource_timer.wait_time = maxf(interval, 0.01)
	resource_timer.timeout.connect(callback)
	add_child(resource_timer)
	return resource_timer


func create_network_speed() -> bool:
	if not is_powered:
		print("System is powered off.")
		return false

	if _network_running:
		return true # Already running; don't charge again.

	var cost := get_network_power_cost()
	if power < cost:
		is_powered = false
		print("System shut down: need %.1f power, have %.1f." % [cost, power])
		return false

	power -= cost # One-time cost to start the network process.
	_network_running = true
	network_timer.start()
	_refresh_network_speed()
	return true


func get_network_power_cost() -> float:
	return maxf(float(router_lvl), 1.0) * power_cost_per_router_level

## Existing shutdown helper stops all resource timers, not just network sampling.
func stop_network() -> void:
	_network_running = false
	_network_activity.clear()
	_compute_activity.clear()
	upload_speed = 0.0
	download_speed = 0.0
	cpu_output = 0.0
	gpu_output = 0.0
	if network_timer != null:
		network_timer.stop()
	if cpu_timer != null:
		cpu_timer.stop()
	if gpu_timer != null:
		gpu_timer.stop()
	if ram_timer != null:
		ram_timer.stop()


func _on_network_timer_timeout() -> void:
	if not is_powered:
		_network_running = false
		network_timer.stop()
	_refresh_network_speed()


func is_network_active() -> bool:
	# Timer time_left can briefly be nonpositive during a slow frame. It is
	# a sampling clock, so use explicit running state to decide connectivity.
	return is_powered and _network_running


func report_network_activity(source: Node, upload_rate: float, download_rate: float) -> void:
	_network_activity[source] = Vector2(maxf(upload_rate, 0.0), maxf(download_rate, 0.0))
	_refresh_network_speed()


func clear_network_activity(source: Node) -> void:
	_network_activity.erase(source)
	_refresh_network_speed()


func _refresh_network_speed() -> void:
	upload_speed = 0.0
	download_speed = 0.0
	if not is_network_active():
		_network_activity.clear()
		return
	var rates := _sum_active_reports(_network_activity)
	upload_speed = rates.x
	download_speed = rates.y


func create_cpu_output() -> void:
	if not is_powered:
		return
	if cpu_timer.is_stopped():
		cpu_timer.start()


func add_cpu_cores(amount: int) -> void:
	cpu_cores = clampi(cpu_cores + amount, 1, max_cpu_cores)


func _on_cpu_timer_timeout() -> void:
	if not is_powered:
		cpu_timer.stop()
	_refresh_compute_usage()


func report_compute_activity(source: Node, cpu_rate: float, gpu_rate: float) -> void:
	_compute_activity[source] = Vector2(maxf(cpu_rate, 0.0), maxf(gpu_rate, 0.0))
	_refresh_compute_usage()


func clear_compute_activity(source: Node) -> void:
	_compute_activity.erase(source)
	_refresh_compute_usage()


func _refresh_compute_usage() -> void:
	# These values now describe current work per second, rather than stored output.
	cpu_output = 0.0
	gpu_output = 0.0
	if not is_powered:
		_compute_activity.clear()
		return
	var rates := _sum_active_reports(_compute_activity)
	cpu_output = rates.x
	gpu_output = rates.y


func create_gpu_output() -> void:
	if not is_powered:
		return
	if gpu_timer.is_stopped():
		gpu_timer.start()


func add_gpus(amount: int) -> void:
	gpu_count = clampi(gpu_count + amount, 1, max_gpu_count)


func _on_gpu_timer_timeout() -> void:
	if not is_powered:
		gpu_timer.stop()
	_refresh_compute_usage()


func add_ram_sticks(amount: int) -> void:
	ram_sticks = clampi(ram_sticks + amount, 1, max_ram_sticks)


func create_ram_output() -> void:
	if not is_powered:
		return
	if ram_timer.is_stopped():
		ram_timer.start()

## RAM still accumulates output; CPU/GPU/network report current usage instead.
func _on_ram_timer_timeout() -> void:
	if not is_powered:
		ram_timer.stop()
		return

	# RAM level scales the output produced by every installed memory stick.
	var output_per_stick := ram_output_per_stick * float(ram_lvl) * ram_output_per_level
	ram_output += output_per_stick * float(ram_sticks) * ram_timer.wait_time


func add_power(amount: float) -> void:
	power = clampf(power + amount, 0.0, max_power)
	if power > 0.0:
		is_powered = true


func add_storage_drives(amount: int) -> void:
	storage_drives = clampi(storage_drives + amount, 1, max_storage_drives)


func open_program_editor() -> Node:
	var editor := PROGRAM_EDITOR_SCENE.instantiate()
	if not editor.has_method("set_computer"):
		push_error("Program editor is missing set_computer(computer).")
		editor.queue_free()
		return null

	# Keep the editor in this computer's window layer when available.
	var window_parent: Node = get_node_or_null("OpenWindows")
	if window_parent == null:
		window_parent = get_tree().root
	window_parent.add_child(editor)
	editor.set_computer(self)
	return editor


## Store a detached graph snapshot in this Computer. This is not a disk save.
func save_program(program_name: String, program_data: Dictionary) -> void:
	var saved_program := {
		"name": program_name,
		"data": program_data.duplicate(true)
	}
	for index in range(programs.size()):
		if programs[index].get("name", "") == program_name:
			programs[index] = saved_program
			return
	programs.append(saved_program)


func _sum_active_reports(reports: Dictionary) -> Vector2:
	# A freed/closed editor cannot keep contributing phantom activity.
	var total := Vector2.ZERO
	for source in reports.keys():
		if not is_instance_valid(source) or source.is_queued_for_deletion() or not source.is_inside_tree():
			reports.erase(source)
			continue
		total += reports[source] as Vector2
	return total


static func find_for(node: Node) -> Computer:
	# Shared ancestor lookup works for nested computers and moved UI panels.
	var ancestor := node.get_parent()
	while ancestor != null:
		if ancestor is Computer:
			return ancestor as Computer
		ancestor = ancestor.get_parent()
	return null
