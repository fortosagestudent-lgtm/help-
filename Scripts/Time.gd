extends Button
## Active desktop clock: only its own pressed signal switches time formats.
const ClockFormat = preload("res://Scripts/ClockFormat.gd")

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
	text = ClockFormat.format_time(Time.get_time_dict_from_system(), current_state == BehaviorState.STATE_A)
