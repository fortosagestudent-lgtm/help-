extends "res://Scripts/Components/ProgramComponent.gd"

@export_range(0.0, 100.0, 0.1) var processing_multiplier := 1.0


func get_kind() -> String:
	return "File Selector"


func get_input_ports() -> Array[String]:
	return ["download"]


func get_output_ports() -> Array[String]:
	return ["file"]


func evaluate(_computer: Computer, inputs: Dictionary, _delta: float) -> Dictionary:
	# Downloaded data becomes files without needing CPU or GPU connections.
	var download := maxf(float(inputs.get("download", 0.0)), 0.0)
	var multiplier := maxf(processing_multiplier, 0.0)
	var files := download * multiplier
	current_download_rate = download if multiplier > 0.0 else 0.0
	current_cpu_rate = 0.0
	current_gpu_rate = 0.0
	set_status("Selected: %.1f files/s" % files)
	return {"file": files}
