extends GraphNode

# Port names also identify the values passed between components each tick.
const PORT_TYPES := {
	"network": 0, "power": 1, "download": 2, "upload": 3,
	"cpu": 4, "gpu": 5, "file": 6
}
const PORT_COLORS := {
	"network": Color("80bcff"), "power": Color("ffce6d"),
	"download": Color("50bdf5"), "upload": Color("b195f0"),
	"cpu": Color("65d2d8"), "gpu": Color("e796cc"),
	"file": Color("75d5a2")
}

var status_label: Label


func _ready() -> void:
	title = get_kind()
	custom_minimum_size = Vector2(190, 0)
	_build_ports()
	status_label = Label.new()
	add_child(status_label)
	set_status("Ready")


func get_kind() -> String:
	return "Component"


func get_input_ports() -> Array[String]:
	return []


func get_output_ports() -> Array[String]:
	return []


func evaluate(_computer: Computer, _inputs: Dictionary, _delta: float) -> Dictionary:
	return {}


func save_state() -> Dictionary:
	return {}


func load_state(_state: Dictionary) -> void:
	pass


func set_status(message: String) -> void:
	if status_label != null:
		status_label.text = message


func _build_ports() -> void:
	var inputs := get_input_ports()
	var outputs := get_output_ports()
	for index in range(maxi(inputs.size(), outputs.size())):
		var input_name := inputs[index] if index < inputs.size() else ""
		var output_name := outputs[index] if index < outputs.size() else ""
		var row := HBoxContainer.new()
		add_child(row)
		var left := Label.new()
		left.text = input_name.capitalize()
		left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(left)
		var right := Label.new()
		right.text = output_name.capitalize()
		row.add_child(right)
		set_slot(
			index,
			not input_name.is_empty(), int(PORT_TYPES.get(input_name, 0)), PORT_COLORS.get(input_name, Color.WHITE),
			not output_name.is_empty(), int(PORT_TYPES.get(output_name, 0)), PORT_COLORS.get(output_name, Color.WHITE)
		)
