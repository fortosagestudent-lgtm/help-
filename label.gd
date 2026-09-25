extends Label

func _process(_delta: float) -> void:
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
