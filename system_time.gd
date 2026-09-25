extends Label

func _process(_delta: float) -> void:
	var time_dict = Time.get_time_dict_from_system()

	var hour: int = time_dict.hour
	var minute: int = time_dict.minute
	var second: int = time_dict.second

	var period := "AM"
	if hour >= 12:
		period = "PM"

	var display_hour := hour % 12
	if display_hour == 0:
		display_hour = 12

	text = "%02d:%02d:%02d %s" % [display_hour, minute, second, period]
