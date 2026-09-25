extends "res://Scripts/Components/ProgramComponent.gd"

@export_range(0.0, 100.0, 0.1) var output_multiplier := 1.0


func get_kind() -> String:
	return "CPU"


func get_output_ports() -> Array[String]:
	return ["cpu"]


func evaluate(computer: Computer, _inputs: Dictionary, _delta: float) -> Dictionary:
	var rate := 0.0
	if computer.is_powered:
		rate = computer.cpu_output_per_core * computer.cpu_output_per_level * float(computer.cpu_lvl * computer.cpu_cores) * output_multiplier
	set_status("CPU: %.1f/s" % rate)
	return {"cpu": rate}
