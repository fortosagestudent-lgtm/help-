extends Node
#######Game time variables
var game_time:= 0.0:
	set(value):
		game_time = value
		
var game_sec
var game_min
var game_hr
var game_day
######
var start_time
var end_time
var timer = Timer
# Called when the node enters the scene tree for the first time.
func _ready():
	game_timer()
	

func _on_new_timer_timeout():
	create_game_clock()
	
func create_game_clock():
	game_time+= 1
	game_sec = int(game_time)
	game_min = int(game_sec/60)
	game_hr = int(game_min/60)
	game_day = int(game_hr/24)
	
	#print("Game Clock: %s Days, %s Hours, %s Minutes, %s Seconds" % [game_day,game_hr,game_min,game_sec])

func game_timer():
	var new_timer = timer.new()
	new_timer.wait_time = 1
	new_timer.one_shot = false
	new_timer.timeout.connect(_on_new_timer_timeout)
	add_child(new_timer)
	new_timer.start()
