extends "res://Scripts/Components/ProgramComponent.gd"

@export_range(0.01, 100000.0, 0.01) var upload_per_file := 1.0

var uploaded_files := 0.0


func get_kind() -> String:
	return "File Uploader"


func get_input_ports() -> Array[String]:
	return ["file", "upload"]


func evaluate(_computer: Computer, inputs: Dictionary, delta: float) -> Dictionary:
	var file_rate := maxf(float(inputs.get("file", 0.0)), 0.0)
	var upload_rate := maxf(float(inputs.get("upload", 0.0)), 0.0)
	uploaded_files += minf(file_rate, upload_rate / maxf(upload_per_file, 0.01)) * delta
	set_status("Uploaded: %.1f test files" % uploaded_files)
	return {}


func save_state() -> Dictionary:
	return {"uploaded_files": uploaded_files}


func load_state(state: Dictionary) -> void:
	uploaded_files = maxf(float(state.get("uploaded_files", 0.0)), 0.0)
	set_status("Uploaded: %.1f test files" % uploaded_files)
