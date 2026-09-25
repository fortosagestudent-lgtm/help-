extends Button

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
	# 1. Get the current system time dictionary from the computer
	var time_dict = Time.get_time_dict_from_system()
	
	# 2. Extract hours, minutes, and seconds
	var hour = time_dict.hour
	var minute = time_dict.minute
	var second = time_dict.second
	
	# 3. Format the text to always display 2 digits (e.g., "05:09:01")
	text = "%02d:%02d:%02d" % [hour, minute, second]
	pass

func second_script_behavior(delta: float) -> void:
	var time_dict = Time.get_time_dict_from_system()
	
	var hour = time_dict.hour
	var minute = time_dict.minute
	var second = time_dict.second
	
	# Determine AM or PM
	var am_pm = "AM" if hour < 12 else "PM"
	
	# Convert 24-hour to 12-hour format
	hour = hour % 12
	if hour == 0:
		hour = 12 # Adjust for midnight or noon
		
	text = "%02d:%02d:%02d %s" % [hour, minute, second, am_pm]
	pass
