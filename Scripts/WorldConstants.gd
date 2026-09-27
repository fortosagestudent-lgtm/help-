extends Node
## Shared defaults and the game clock.

# Change these to choose the wallpaper library and new-computer default.
var default_wallpaper_folder := "res://Assets/Textures/Wallpapers/Default/"
var default_wallpaper: Texture2D = preload("res://Assets/Textures/street-1.png")

## Elapsed totals, independent of the OS desktop clock.
## Minutes/hours/days are total elapsed units, not wrapped clock-face values.

var game_time := 0.0
var game_sec: int
var game_min: int
var game_hr: int
var game_day: int


func _ready() -> void:
	game_timer()


func _on_new_timer_timeout() -> void:
	create_game_clock()


func create_game_clock() -> void:
	game_time += 1.0
	game_sec = int(game_time)
	game_min = int(game_sec / 60.0)
	game_hr = int(game_min / 60.0)
	game_day = int(game_hr / 24.0)


func game_timer() -> void:
	var new_timer := Timer.new()
	new_timer.wait_time = 1.0
	new_timer.timeout.connect(_on_new_timer_timeout)
	add_child(new_timer)
	new_timer.start()
