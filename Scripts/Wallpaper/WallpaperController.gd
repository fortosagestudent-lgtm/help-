extends TextureRect
## This view displays its Computer's wallpaper; the Computer owns the selection.

func _ready() -> void:
	var computer := Computer.find_for(self)
	if computer == null:
		return
	texture = computer.wallpaper
	computer.wallpaper_changed.connect(_on_wallpaper_changed)


func _on_wallpaper_changed(value: Texture2D) -> void:
	texture = value
