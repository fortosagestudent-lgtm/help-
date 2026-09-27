extends PanelContainer
## Displays live hardware values from the Computer that owns this Summary window.
## Reading these values never spends resources or changes hardware.

var computer: Computer

# Unique scene names keep the live values connected when their tabs move.
@onready var metrics: Node = owner


func _ready() -> void:
	# Walk up from this window so summaries also work with multiple computers.
	computer = Computer.find_for(self)
	set_process(computer != null)
	if computer != null:
		_refresh_metrics()


func _process(_delta: float) -> void:
	if is_visible_in_tree():
		_refresh_metrics()


func _refresh_metrics() -> void:
	var output_per_core := computer.cpu_output_per_core * float(computer.cpu_lvl) * computer.cpu_output_per_level
	var output_per_card := computer.gpu_output_per_card * float(computer.gpu_lvl) * computer.gpu_output_per_level
	var ram_rate := computer.ram_output_per_stick * computer.ram_output_per_level * float(computer.ram_lvl * computer.ram_sticks)

	# Network
	metrics.get_node("%RouterLevel").text = "Router Level: %d" % computer.router_lvl
	metrics.get_node("%NeworkSpeed").text = "Current Network Speed: %.1f/s" % computer.network_speed
	metrics.get_node("%DownloadSpeed").text = "Current Download Speed: %.1f/s" % computer.download_speed
	metrics.get_node("%UploadSpeed").text = "Current Upload Speed: %.1f/s" % computer.upload_speed

	# CPU
	metrics.get_node("%CpuLevel").text = "CPU Level: %d" % computer.cpu_lvl
	metrics.get_node("%TotalCpuCore").text = "Total CPU Cores: %d" % computer.cpu_cores
	metrics.get_node("%TotalCpuPower").text = "CPU Output per Second: %.1f" % (output_per_core * float(computer.cpu_cores))
	metrics.get_node("%CurrentCPu").text = "Current CPU Usage: %.1f/s" % computer.cpu_output
	metrics.get_node("%CpuPerCore").text = "Average Usage per Core: %.1f/s" % (computer.cpu_output / float(maxi(computer.cpu_cores, 1)))

	# GPU
	metrics.get_node("%GpuLevel").text = "GPU Level: %d" % computer.gpu_lvl
	metrics.get_node("%TotalGpuCards").text = "Total GPU Cards: %d" % computer.gpu_count
	metrics.get_node("%TotalGpuPower").text = "GPU Output per Second: %.1f" % (output_per_card * float(computer.gpu_count))
	metrics.get_node("%CurrentGpu").text = "Current GPU Usage: %.1f/s" % computer.gpu_output
	metrics.get_node("%GpuPerCard").text = "Average Usage per Card: %.1f/s" % (computer.gpu_output / float(maxi(computer.gpu_count, 1)))

	# RAM
	metrics.get_node("%RamLevel").text = "RAM Level: %d" % computer.ram_lvl
	metrics.get_node("%RamSticks").text = "Installed RAM Sticks: %d / %d" % [computer.ram_sticks, computer.max_ram_sticks]
	metrics.get_node("%RamRate").text = "RAM Output per Second: %.1f" % ram_rate
	metrics.get_node("%RamOutput").text = "Accumulated RAM Output: %.1f" % computer.ram_output

	# Storage
	metrics.get_node("%StorageLevel").text = "Storage Level: %d" % computer.storage_lvl
	metrics.get_node("%StorageDrives").text = "Installed Storage Drives: %d / %d" % [computer.storage_drives, computer.max_storage_drives]
	metrics.get_node("%StorageCapacity").text = "Total Storage Capacity: %.1f" % computer.storage_capacity

	# Power
	metrics.get_node("%PowerLevel").text = "Power Level: %d" % computer.power_lvl
	metrics.get_node("%PowerStatus").text = "Status: " + ("Powered on" if computer.is_powered else "Powered off")
	metrics.get_node("%TotalPower").text = "Max Power: %.1f" % computer.max_power
	metrics.get_node("%CurrentPower").text = "Current Power: %.1f" % computer.power
	metrics.get_node("%NetworkStartupCost").text = "Network Startup Cost: %.1f" % computer.get_network_power_cost()
