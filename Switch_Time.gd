extends Label

@onready var script_node_one: Label = $"System time"
@onready var script_node_two: Label = $"System time2"

var is_first_active: bool = true

func _ready() -> void:
	# Start with the first active and the second disabled
	script_node_one.set_process(true)
	script_node_one.set_physics_process(true)
	script_node_two.set_process(false)
	script_node_two.set_physics_process(false)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		is_first_active = not is_first_active
		
		# Toggle processing for both scripts
		script_node_one.set_process(is_first_active)
		script_node_one.set_physics_process(is_first_active)
		
		script_node_two.set_process(not is_first_active)
		script_node_two.set_physics_process(not is_first_active)
