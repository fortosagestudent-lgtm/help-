extends "res://Scripts/Components/ProgramComponent.gd"
## Consumes file and upload rates, accumulating completed test files for this component.

@export_range(0.01, 100000.0, 0.01) var upload_per_file := 1.0

var uploaded_files := 0.0


func get_kind() -> String:
	return "File Uploader"


func get_input_ports() -> Array[String]:
	return ["file", "upload"]


func evaluate(_computer: Computer, inputs: Dictionary, delta: float) -> Dictionary:
	var file_rate := maxf(float(inputs.get("file", 0.0)), 0.0)
	var upload_rate := maxf(float(inputs.get("upload", 0.0)), 0.0)
	# Upload only as many files as both inputs allow. delta turns the rate into
	# a cumulative file count, while current_upload_rate remains a live rate.
	var bandwidth_per_file := maxf(upload_per_file, 0.01)
	var files_this_second := minf(file_rate, upload_rate / bandwidth_per_file)
	current_upload_rate = files_this_second * bandwidth_per_file
	uploaded_files += files_this_second * delta
	set_status("Uploaded: %.1f test files" % uploaded_files)
	return {}


func save_state() -> Dictionary:
	return {"uploaded_files": uploaded_files}


func load_state(state: Dictionary) -> void:
	uploaded_files = maxf(float(state.get("uploaded_files", 0.0)), 0.0)
	set_status("Uploaded: %.1f test files" % uploaded_files)
