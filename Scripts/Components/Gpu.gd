extends "res://Scripts/Components/ProgramComponent.gd"

@export_range(0.0, 100.0, 0.1) var output_multiplier := 1.0


func get_kind() -> String:
	return "GPU"


func get_output_ports() -> Array[String]:
	return ["gpu"]


func evaluate(computer: Computer, _inputs: Dictionary, _delta: float) -> Dictionary:
	var rate := 0.0
	if computer.is_powered:
		rate = computer.gpu_output_per_card * computer.gpu_output_per_level * float(computer.gpu_lvl * computer.gpu_count) * output_multiplier
	set_status("GPU: %.1f/s" % rate)
	return {"gpu": rate}
