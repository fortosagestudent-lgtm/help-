extends "res://Scripts/Components/ProgramComponent.gd"

@export_range(0.0, 100.0, 0.1) var processing_multiplier := 1.0


func get_kind() -> String:
	return "File Selector"


func get_input_ports() -> Array[String]:
	return ["download", "cpu", "gpu"]


func get_output_ports() -> Array[String]:
	return ["file"]


func evaluate(_computer: Computer, inputs: Dictionary, _delta: float) -> Dictionary:
	# Prototype flow: downloaded data becomes test files at the available compute rate.
	var download := maxf(float(inputs.get("download", 0.0)), 0.0)
	var compute := maxf(float(inputs.get("cpu", 0.0)), 0.0) + maxf(float(inputs.get("gpu", 0.0)), 0.0)
	var files := minf(download, compute * processing_multiplier)
	set_status("Selected: %.1f files/s" % files)
	return {"file": files}
