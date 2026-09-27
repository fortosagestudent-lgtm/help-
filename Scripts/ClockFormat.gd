extends RefCounted
## Shared formatting for the desktop clock and older clock scenes.
## Supplying a time dictionary also lets tests check midnight/noon deterministically.
static func format_time(time: Dictionary, use_12_hour: bool, pad_hour: bool = true) -> String:
	var hour: int = time.hour
	var minute: int = time.minute
	var second: int = time.second
	var suffix := ""
	if use_12_hour:
		suffix = " AM" if hour < 12 else " PM"
		hour = hour % 12
		if hour == 0:
			hour = 12
	var hour_text := "%02d" % hour if pad_hour else str(hour)
	return "%s:%02d:%02d%s" % [hour_text, minute, second, suffix]
