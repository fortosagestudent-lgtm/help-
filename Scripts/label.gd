extends Label
## Legacy 12-hour label with padded hours, unlike system_time.gd.
const ClockFormat = preload("res://Scripts/ClockFormat.gd")


func _process(_delta: float) -> void:
	text = ClockFormat.format_time(Time.get_time_dict_from_system(), true)
