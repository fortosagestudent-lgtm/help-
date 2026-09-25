class_name Computer
extends Node
#### Export Variables AHHHHH




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

######Variables####
const PROGRAM_EDITOR_SCENE: PackedScene = preload("res://program_editor.tscn")

var programs: Array[Dictionary] = []
var upload_speed: float = 0.0
var download_speed: float = 0.0
var cpu_lvl: int = 1
var cpu_output: float = 0.0
var gpu_output: float = 0.0
var ram_output: float = 0.0
var is_powered: bool = true
var network_timer: Timer
var cpu_timer: Timer
var gpu_timer: Timer
var ram_timer: Timer


###### Start#####
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
	_create_network_timer()
	_create_cpu_timer()
	_create_gpu_timer()
	_create_ram_timer()
	create_network_speed()
	create_cpu_output()
	create_gpu_output()
	create_ram_output()



#####Network########

var network_speed: float:
	get:
		return upload_speed + download_speed
		
func _create_network_timer() -> void:
	network_timer = Timer.new()
	network_timer.wait_time = maxf(network_tick_seconds, 0.01)
	network_timer.one_shot = false
	network_timer.timeout.connect(_on_network_timer_timeout)
	add_child(network_timer)
	
func create_network_speed() -> bool:
	if not is_powered:
		print("System is powered off.")
		return false

	if not network_timer.is_stopped():
		return true # Already running; don't charge again.

	var cost := get_network_power_cost()
	if power < cost:
		is_powered = false
		print("System shut down: need %.1f power, have %.1f." % [cost, power])
		return false

	power -= cost # One-time cost to start the network process.
	network_timer.start()
	return true
	
func get_network_power_cost() -> float:
	return maxf(float(router_lvl), 1.0) * power_cost_per_router_level
	
func stop_network() -> void:
	if network_timer != null:
		network_timer.stop()
	if cpu_timer != null:
		cpu_timer.stop()
	if gpu_timer != null:
		gpu_timer.stop()
	if ram_timer != null:
		ram_timer.stop()

var storage_capacity: float:
	get:
		return float(storage_lvl) * float(storage_drives) * storage_per_drive * storage_per_level

func _on_network_timer_timeout() -> void:
	if not is_powered:
		network_timer.stop()
		return

	var rate_per_second := float(router_lvl) * network_multi
	var amount_this_tick := rate_per_second * network_timer.wait_time
	upload_speed += amount_this_tick * 0.5
	download_speed += amount_this_tick * 0.5

	print("Upload: %.1f | Download: %.1f | Total: %.1f | CPU: %.1f | Power: %.1f" % [upload_speed,download_speed,network_speed,cpu_output,power])

#####CPU#####



func _create_cpu_timer() -> void:
	cpu_timer = Timer.new()
	cpu_timer.wait_time = maxf(cpu_tick_seconds, 0.01)
	cpu_timer.one_shot = false
	cpu_timer.timeout.connect(_on_cpu_timer_timeout)
	add_child(cpu_timer)


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
		return

	# Each core produces output, and cpu_lvl scales the output of every core.
	var output_per_core := cpu_output_per_core * float(cpu_lvl) * cpu_output_per_level
	cpu_output += output_per_core * float(cpu_cores) * cpu_timer.wait_time
	print("CPU output: %.1f | CPU level: %d | Cores: %d" % [cpu_output, cpu_lvl, cpu_cores])



########GPU#########
	
func _create_gpu_timer() -> void:
	gpu_timer = Timer.new()
	gpu_timer.wait_time = maxf(gpu_tick_seconds, 0.01)
	gpu_timer.one_shot = false
	gpu_timer.timeout.connect(_on_gpu_timer_timeout)
	add_child(gpu_timer)
	
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
		return

	# GPU level scales the output produced by every installed graphics card.
	var output_per_card := gpu_output_per_card * float(gpu_lvl) * gpu_output_per_level
	gpu_output += output_per_card * float(gpu_count) * gpu_timer.wait_time
	print("GPU output: %.1f | GPU level: %d | Cards: %d" % [gpu_output, gpu_lvl, gpu_count])



######RAM#####


func _create_ram_timer() -> void:
	ram_timer = Timer.new()
	ram_timer.wait_time = maxf(ram_tick_seconds, 0.01)
	ram_timer.one_shot = false
	ram_timer.timeout.connect(_on_ram_timer_timeout)
	add_child(ram_timer)

func add_ram_sticks(amount: int) -> void:
	ram_sticks = clampi(ram_sticks + amount, 1, max_ram_sticks)

func create_ram_output() -> void:
	if not is_powered:
		return
	if ram_timer.is_stopped():
		ram_timer.start()

func _on_ram_timer_timeout() -> void:
	if not is_powered:
		ram_timer.stop()
		return

	# RAM level scales the output produced by every installed memory stick.
	var output_per_stick := ram_output_per_stick * float(ram_lvl) * ram_output_per_level
	ram_output += output_per_stick * float(ram_sticks) * ram_timer.wait_time
	print("RAM output: %.1f | RAM level: %d | Sticks: %d" % [ram_output, ram_lvl, ram_sticks])
	
	#####POWER#######


func add_power(amount: float) -> void:
	power = clampf(power + amount, 0.0, max_power)
	if power > 0.0:
		is_powered = true
		
		
########STORAGE########
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
