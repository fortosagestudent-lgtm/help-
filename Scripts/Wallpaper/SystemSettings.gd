class_name SystemSettings
extends PanelContainer
## The grid offers textures; only the owning Computer stores the selection.

var computer: Computer
var available_wallpapers: Array[Texture2D] = []
var choice_buttons: Array[Button] = []
var choice_group := ButtonGroup.new()

@onready var wallpaper_grid: GridContainer = %WallpaperGrid
@onready var current_label: Label = %CurrentWallpaper
@onready var import_button: Button = %ImportButton
@onready var file_dialog: FileDialog = %FileDialog


func _ready() -> void:
	if computer == null:
		computer = Computer.find_for(self)
	if computer == null:
		current_label.text = "No computer connected."
		import_button.disabled = true
		return
	computer.wallpaper_changed.connect(_on_wallpaper_changed)
	import_button.pressed.connect(_open_import_dialog)
	file_dialog.file_selected.connect(_on_file_selected)
	wallpaper_grid.get_parent().resized.connect(_resize_grid)
	get_wallpapers()


func get_wallpapers() -> void:
	_clear_grid()
	if WorldConstants.default_wallpaper != null:
		_add_wallpaper_choice(WorldConstants.default_wallpaper, "Default wallpaper")
	_add_folder_wallpapers(WorldConstants.default_wallpaper_folder)
	if computer.wallpaper != null and computer.wallpaper not in available_wallpapers:
		_add_wallpaper_choice(computer.wallpaper, "Current image")
	_on_wallpaper_changed(computer.wallpaper)
	_resize_grid()


func _clear_grid() -> void:
	# Rebuilding never duplicates tiles or keeps references to old textures.
	available_wallpapers.clear()
	choice_buttons.clear()
	for tile in wallpaper_grid.get_children():
		wallpaper_grid.remove_child(tile)
		tile.queue_free()


func _add_folder_wallpapers(folder: String) -> void:
	if not DirAccess.dir_exists_absolute(folder):
		return
	# ResourceLoader lists imported textures in exported games too.
	var files := ResourceLoader.list_directory(folder)
	files.sort()
	for file_name in files:
		if file_name.get_extension().to_lower() not in ["png", "jpg", "jpeg", "webp", "svg"]:
			continue
		var texture := load(folder.path_join(file_name)) as Texture2D
		if texture != null and texture not in available_wallpapers:
			_add_wallpaper_choice(texture, file_name.get_basename().replace("_", " "))


func _add_wallpaper_choice(texture: Texture2D, title: String) -> void:
	available_wallpapers.append(texture)
	var tile := VBoxContainer.new()
	tile.custom_minimum_size = Vector2(220, 168)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wallpaper_grid.add_child(tile)
	tile.add_child(_make_preview(texture))
	var button := Button.new()
	button.text = title
	button.tooltip_text = title
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.theme_type_variation = &"ManagerButton"
	button.toggle_mode = true
	button.button_group = choice_group
	button.pressed.connect(_select_wallpaper.bind(texture))
	tile.add_child(button)
	choice_buttons.append(button)


func _make_preview(texture: Texture2D) -> TextureRect:
	var preview := TextureRect.new()
	preview.custom_minimum_size = Vector2(220, 132)
	preview.texture = texture
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return preview


func _resize_grid() -> void:
	# Keep the preview size readable as the settings window changes width.
	var available_width: float = wallpaper_grid.get_parent().size.x - 16.0
	wallpaper_grid.columns = maxi(1, int((available_width + 12.0) / 232.0))


func _select_wallpaper(texture: Texture2D) -> Error:
	var result := computer.set_wallpaper(texture)
	if result != OK:
		_on_wallpaper_changed(computer.wallpaper)
		current_label.text = "Could not save wallpaper (error %d)." % result
	return result


func _open_import_dialog() -> void:
	file_dialog.popup_centered_ratio(0.7)


func _on_file_selected(path: String) -> void:
	var image := Image.load_from_file(path)
	if image == null:
		current_label.text = "Could not open that image."
		return
	if _select_wallpaper(ImageTexture.create_from_image(image)) == OK:
		get_wallpapers()


func _on_wallpaper_changed(texture: Texture2D) -> void:
	current_label.text = "Current Wallpaper: " + _wallpaper_title(texture)
	for index in choice_buttons.size():
		var selected := available_wallpapers[index] == texture
		choice_buttons[index].set_pressed_no_signal(selected)
		# Tint the selected preview in addition to the button's pressed style.
		var preview := choice_buttons[index].get_parent().get_child(0) as TextureRect
		preview.modulate = Color.WHITE if selected else Color(0.8, 0.8, 0.8)


func _wallpaper_title(texture: Texture2D) -> String:
	if texture == WorldConstants.default_wallpaper:
		return "Default wallpaper"
	if texture != null and not texture.resource_path.is_empty():
		return texture.resource_path.get_file().get_basename().replace("_", " ")
	return "Custom image"
