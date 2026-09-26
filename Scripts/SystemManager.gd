extends PanelContainer
## The merged Summary tab reads live values from the Computer that owns its window.

var computer: Computer

@onready var metrics: VBoxContainer = $VBoxContainer/TabContainer/Summary/VBoxContainer


func _ready() -> void:
	# Walk up from this window so summaries also work with multiple computers.
	var ancestor := get_parent()
	while ancestor != null:
		if ancestor is Computer:
			computer = ancestor as Computer
			break
		ancestor = ancestor.get_parent()
	set_process(computer != null)
	if computer != null:
		_refresh_metrics()


func _process(_delta: float) -> void:
	if is_visible_in_tree():
		_refresh_metrics()


func _refresh_metrics() -> void:
	var output_per_core := computer.cpu_output_per_core * float(computer.cpu_lvl) * computer.cpu_output_per_level
	var output_per_card := computer.gpu_output_per_card * float(computer.gpu_lvl) * computer.gpu_output_per_level
	metrics.get_node("NeworkSpeed").text = "Current Network Speed: %.1f/s" % computer.network_speed
	metrics.get_node("DownloadSpeed").text = "Current Download Speed: %.1f/s" % computer.download_speed
	metrics.get_node("UploadSpeed").text = "Current Upload Speed: %.1f/s" % computer.upload_speed
	metrics.get_node("TotalPower").text = "Max Power: %.1f" % computer.max_power
	metrics.get_node("CurrentPower").text = "Current Power: %.1f" % computer.power
	metrics.get_node("TotalCpuCore").text = "Total CPU Cores: %d" % computer.cpu_cores
	metrics.get_node("TotalCpuPower").text = "CPU Output per Second: %.1f" % (output_per_core * float(computer.cpu_cores))
	metrics.get_node("CurrentCPu").text = "Current CPU Usage: %.1f/s" % computer.cpu_output
	metrics.get_node("CpuPerCore").text = "Average Usage per Core: %.1f/s" % (computer.cpu_output / float(maxi(computer.cpu_cores, 1)))
	metrics.get_node("TotalGpuCards").text = "Total GPU Cards: %d" % computer.gpu_count
	metrics.get_node("TotalGpuPower").text = "GPU Output per Second: %.1f" % (output_per_card * float(computer.gpu_count))
	metrics.get_node("CurrentGpu").text = "Current GPU Usage: %.1f/s" % computer.gpu_output
	metrics.get_node("GpuPerCard").text = "Average Usage per Card: %.1f/s" % (computer.gpu_output / float(maxi(computer.gpu_count, 1)))
