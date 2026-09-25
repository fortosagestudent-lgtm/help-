extends "res://Scripts/Components/ProgramComponent.gd"

@export_range(0.0, 100.0, 0.1) var output_multiplier := 1.0


func get_kind() -> String:
	return "Power"


func get_output_ports() -> Array[String]:
	return ["power"]


func evaluate(computer: Computer, _inputs: Dictionary, _delta: float) -> Dictionary:
	# Reading available power does not drain it; the computer pays its startup cost.
	var available := computer.power * output_multiplier if computer.is_powered else 0.0
	set_status("Available: %.1f" % available)
	return {"power": available}
