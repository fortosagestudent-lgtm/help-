extends RefCounted
## Disk operations stay here; each Computer supplies its own save directory.

static func load_wallpaper(directory: String) -> Texture2D:
	var settings := ConfigFile.new()
	if settings.load(directory + "/selection.cfg") != OK:
		return null
	var path: String = settings.get_value("wallpaper", "path", "")
	if path.begins_with("res://") and ResourceLoader.exists(path):
		return load(path) as Texture2D
	if path.begins_with("user://") and FileAccess.file_exists(path):
		var image := Image.load_from_file(path)
		if image != null:
			return ImageTexture.create_from_image(image)
	return null


static func save_wallpaper(directory: String, texture: Texture2D) -> Error:
	if texture == null:
		return ERR_INVALID_PARAMETER
	var result := DirAccess.make_dir_recursive_absolute(directory)
	if result != OK:
		return result
	var path := texture.resource_path
	if not path.begins_with("res://"):
		path = directory + "/custom.png"
		result = _save_image(texture, path)
		if result != OK:
			return result
	var settings := ConfigFile.new()
	settings.set_value("wallpaper", "path", path)
	return settings.save(directory + "/selection.cfg")


static func _save_image(texture: Texture2D, path: String) -> Error:
	# Copy imports so deleting the original file cannot break the saved wallpaper.
	var image := texture.get_image()
	if image == null:
		return ERR_INVALID_DATA
	return image.save_png(path)
