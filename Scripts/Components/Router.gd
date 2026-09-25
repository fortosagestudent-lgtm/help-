extends "res://Scripts/Components/ProgramComponent.gd"

@export_range(0.0, 1.0, 0.01) var download_share := 0.5
@export_range(0.0, 100000.0, 0.1) var required_power := 1.0


func get_kind() -> String:
	return "Router"


func get_input_ports() -> Array[String]:
	return ["network", "power"]


func get_output_ports() -> Array[String]:
	return ["download", "upload"]


func evaluate(computer: Computer, inputs: Dictionary, _delta: float) -> Dictionary:
	var bandwidth := 0.0
	if computer.is_powered and float(inputs.get("power", 0.0)) >= required_power:
		bandwidth = maxf(float(inputs.get("network", 0.0)), 0.0) * float(maxi(computer.router_lvl, 1))
	var share := clampf(download_share, 0.0, 1.0)
	var download := bandwidth * share
	var upload := bandwidth - download
	set_status("Down %.1f/s | Up %.1f/s" % [download, upload])
	return {"download": download, "upload": upload}
