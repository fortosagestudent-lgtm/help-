extends Button

# STATE_A shows 12-hour time; STATE_B shows 24-hour time.
enum BehaviorState { STATE_A, STATE_B }
var current_state = BehaviorState.STATE_A


func _ready() -> void:
	pressed.connect(_on_button_pressed)
	execute_behavior()


func _process(_delta: float) -> void:
	execute_behavior()


func _on_button_pressed() -> void:
	if current_state == BehaviorState.STATE_A:
		current_state = BehaviorState.STATE_B
	else:
		current_state = BehaviorState.STATE_A
	execute_behavior()


func execute_behavior() -> void:
	var time_dict := Time.get_time_dict_from_system()
	var hour: int = time_dict.hour
	var minute: int = time_dict.minute
	var second: int = time_dict.second

	match current_state:
		BehaviorState.STATE_A:
			var am_pm := "AM" if hour < 12 else "PM"
			hour = hour % 12
			if hour == 0:
				hour = 12
			text = "%02d:%02d:%02d %s" % [hour, minute, second, am_pm]
		BehaviorState.STATE_B:
			text = "%02d:%02d:%02d" % [hour, minute, second]
