extends Node

var use_second_script: bool = false

func _input(event: InputEvent) -> void:
	# Check for a mouse click (e.g., left mouse button)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		use_second_script = not use_second_script
		print("Swapped state! Second script active: ", use_second_script)

func _process(delta: float) -> void:
	if use_second_script:
		second_script_behavior(delta)
	else:
		first_script_behavior(delta)

func first_script_behavior(delta: float) -> void:
	# Put code for your first script here
	pass

func second_script_behavior(delta: float) -> void:
	# Put code for your second script here
	pass
