extends Label

func _process(_delta: float) -> void:
	# 1. Get the current system time dictionary from the computer
	var time_dict = Time.get_time_dict_from_system()
	
	# 2. Extract hours, minutes, and seconds
	var hour = time_dict.hour
	var minute = time_dict.minute
	var second = time_dict.second
	
	# 3. Format the text to always display 2 digits (e.g., "05:09:01")
	text = "%02d:%02d:%02d" % [hour, minute, second]
