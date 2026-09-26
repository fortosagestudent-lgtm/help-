extends "res://Scripts/Components/ProgramComponent.gd"

@export_range(0.0, 100.0, 0.1) var output_multiplier := 1.0


func get_kind() -> String:
	return "Server"


func get_output_ports() -> Array[String]:
	return ["network"]


func evaluate(computer: Computer, _inputs: Dictionary, _delta: float) -> Dictionary:
	var rate := computer.network_multi * output_multiplier if computer.is_network_active() else 0.0
	set_status("Network: %.1f/s" % rate)
	return {"network": rate}
