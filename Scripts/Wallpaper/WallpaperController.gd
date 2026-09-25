class_name WallpaperController
extends TextureRect

const BUILTIN_DIRECTORY := "res://Assets/Textures/Wallpapers/Original/"
const BUILTIN_FILES := [
	"Ascent.png", "Autumn.png", "Azul.png", "Bliss.png",
	"Blue_Abstract.png", "Crystal.png", "Follow.png", "Friend.png",
	"Green_Abstract.png", "Home.png", "Moon_flower.png", "Peace.png",
	"Power.png", "Purple_flower.png", "Radiance.png", "Red_moon_desert.png",
	"Ripple.png", "Stonehenge.png", "Tulips.png", "Vortec_space.png", "Wind.png",
]
const DEFAULT_FILE := "street-1.png"
const DEFAULT_PATH := "res://Assets/Textures/street-1.png"
const SETTINGS_FILE := "user://wallpaper.cfg"
const CUSTOM_DIRECTORY := "user://wallpaper"
const CUSTOM_FILE := "user://wallpaper/custom.png"

var current_file := DEFAULT_FILE
var using_custom_image := false


func _ready() -> void:
	_load_selection()


func set_builtin(file_name: String) -> Error:
	if not BUILTIN_FILES.has(file_name):
		return ERR_INVALID_PARAMETER
	var chosen_texture := load(BUILTIN_DIRECTORY + file_name) as Texture2D
	if chosen_texture == null:
		return ERR_FILE_NOT_FOUND
	var result := _save_selection("builtin", file_name)
	if result != OK:
		return result
	texture = chosen_texture
	current_file = file_name
	using_custom_image = false
	return OK


func set_original() -> Error:
	var original_texture := load(DEFAULT_PATH) as Texture2D
	if original_texture == null:
		return ERR_FILE_NOT_FOUND
	var result := _save_selection("original", DEFAULT_FILE)
	if result != OK:
		return result
	texture = original_texture
	current_file = DEFAULT_FILE
	using_custom_image = false
	return OK


func set_custom(source_path: String) -> Error:
	var image := Image.new()
	var result := image.load(source_path)
	if result != OK:
		return result
	result = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CUSTOM_DIRECTORY))
	if result != OK:
		return result
	result = image.save_png(CUSTOM_FILE)
	if result != OK:
		return result
	result = _save_selection("custom", "custom.png")
	if result != OK:
		return result
	texture = ImageTexture.create_from_image(image)
	current_file = "custom.png"
	using_custom_image = true
	return OK


func current_label() -> String:
	if using_custom_image:
		return "Uploaded image"
	if current_file == DEFAULT_FILE:
		return "Original desktop"
	return current_file.get_basename().replace("_", " ")


func _load_selection() -> void:
	var settings := ConfigFile.new()
	if settings.load(SETTINGS_FILE) == OK:
		var kind := String(settings.get_value("wallpaper", "kind", "builtin"))
		if kind == "custom":
			var image := Image.new()
			if image.load(CUSTOM_FILE) == OK:
				texture = ImageTexture.create_from_image(image)
				current_file = "custom.png"
				using_custom_image = true
				return
		elif kind == "original":
			var original_texture := load(DEFAULT_PATH) as Texture2D
			if original_texture != null:
				texture = original_texture
				current_file = DEFAULT_FILE
				return
		elif kind == "builtin":
			var file_name := String(settings.get_value("wallpaper", "file", DEFAULT_FILE))
			if BUILTIN_FILES.has(file_name):
				var chosen_texture := load(BUILTIN_DIRECTORY + file_name) as Texture2D
				if chosen_texture != null:
					texture = chosen_texture
					current_file = file_name
					return
	texture = load(DEFAULT_PATH) as Texture2D
	current_file = DEFAULT_FILE
	using_custom_image = false


func _save_selection(kind: String, file_name: String) -> Error:
	var settings := ConfigFile.new()
	settings.set_value("wallpaper", "kind", kind)
	settings.set_value("wallpaper", "file", file_name)
	return settings.save(SETTINGS_FILE)
