extends Button

# Track the current state/behavior
enum BehaviorState { STATE_A, STATE_B }
var current_state = BehaviorState.STATE_A

func _ready():
	# Connect the button's own pressed signal to itself
	self.pressed.connect(_on_button_pressed)

func _on_button_pressed():
	# 1. Swap the state logic
	if current_state == BehaviorState.STATE_A:
		current_state = BehaviorState.STATE_B
	else:
		current_state = BehaviorState.STATE_A
	
	# 2. Execute the active logic
	execute_behavior()

func execute_behavior():
	match current_state:
		BehaviorState.STATE_A:
			print("Running Script A Logic")
			text = "Switch to B"
			# Put your State A code here
			
	# 1. Get the current system time dictionary from the computer
	var time_dict = Time.get_time_dict_from_system()
	
	# 2. Extract hours, minutes, and seconds
	var hour = time_dict.hour
	var minute = time_dict.minute
	var second = time_dict.second
	
	# 3. Format the text to always display 2 digits (e.g., "05:09:01")
	text = "%02d:%02d:%02d" % [hour, minute, second]
		BehaviorState.STATE_B:
			print("Running Script B Logic")
			text = "Switch to A"
			# Put your State B code here
