extends Button
## Legacy click-anywhere clock. The active desktop uses Time.gd, where only
## clicking the clock switches formats. Keep this behavior for old scenes.
const ClockFormat = preload("res://Scripts/ClockFormat.gd")

var use_second_script := false


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		use_second_script = not use_second_script


func _process(delta: float) -> void:
	if use_second_script:
		second_script_behavior(delta)
	else:
		first_script_behavior(delta)


func first_script_behavior(_delta: float) -> void:
	text = ClockFormat.format_time(Time.get_time_dict_from_system(), false)


func second_script_behavior(_delta: float) -> void:
	text = ClockFormat.format_time(Time.get_time_dict_from_system(), true)
