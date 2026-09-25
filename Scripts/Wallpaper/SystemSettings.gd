class_name SystemSettings
extends PanelContainer

var wallpaper_controller: WallpaperController

@onready var wallpaper_grid: GridContainer = $Margin/VBox/Wallpapers/WallpaperGrid
@onready var current_label: Label = $Margin/VBox/CurrentWallpaper
@onready var import_button: Button = $Margin/VBox/Actions/ImportButton
@onready var file_dialog: FileDialog = $FileDialog


func _ready() -> void:
	import_button.pressed.connect(_on_import_pressed)
	file_dialog.file_selected.connect(_on_file_selected)
	if wallpaper_controller == null:
		current_label.text = "Wallpaper control is unavailable."
		import_button.disabled = true
		return
	current_label.text = "Current: " + wallpaper_controller.current_label()
	_add_wallpaper_choice(WallpaperController.DEFAULT_FILE, WallpaperController.DEFAULT_PATH, "Original desktop")
	for file_name in WallpaperController.BUILTIN_FILES:
		_add_wallpaper_choice(file_name, WallpaperController.BUILTIN_DIRECTORY + file_name, file_name.get_basename().replace("_", " "))


func _on_import_pressed() -> void:
	file_dialog.popup_centered_ratio(0.7)


func _add_wallpaper_choice(file_name: String, path: String, display_name: String) -> void:
	var tile := VBoxContainer.new()
	tile.custom_minimum_size = Vector2(220, 168)
	wallpaper_grid.add_child(tile)

	var preview := TextureRect.new()
	preview.custom_minimum_size = Vector2(220, 132)
	preview.texture = load(path) as Texture2D
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(preview)

	var select_button := Button.new()
	select_button.text = display_name
	select_button.theme_type_variation = &"ManagerButton"
	select_button.pressed.connect(_on_builtin_selected.bind(file_name))
	tile.add_child(select_button)


func _on_builtin_selected(file_name: String) -> void:
	var result: Error
	if file_name == WallpaperController.DEFAULT_FILE:
		result = wallpaper_controller.set_original()
	else:
		result = wallpaper_controller.set_builtin(file_name)
	_show_result(result)


func _on_file_selected(path: String) -> void:
	var result := wallpaper_controller.set_custom(path)
	_show_result(result)


func _show_result(result: Error) -> void:
	if result == OK:
		current_label.text = "Current: " + wallpaper_controller.current_label()
	else:
		current_label.text = "Could not change wallpaper (error %d)." % result
