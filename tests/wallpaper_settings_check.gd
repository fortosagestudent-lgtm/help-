extends SceneTree
## Run with a fresh APPDATA folder so the checks never overwrite player choices.
var checks := 0
var failures := 0
var computer_scene: PackedScene


func _initialize() -> void:
	call_deferred("_run")


func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(description)


func make_computer(id: String) -> Node:
	var computer := computer_scene.instantiate()
	computer.wallpaper_save_id = id
	root.add_child(computer)
	return computer


func _run() -> void:
	# Load after autoloads exist; the scenes read WorldConstants during startup.
	computer_scene = load("res://Scenes/computer.tscn")
	var defaults = root.get_node("WorldConstants")
	var first := make_computer("wallpaper-check-first")
	var second := make_computer("wallpaper-check-second")
	second.get_node("Ui").hide()
	check(first.wallpaper == defaults.default_wallpaper, "First computer uses shared default")
	check(second.wallpaper == defaults.default_wallpaper, "Second computer uses shared default")
	check(first.wallpaper_storage_directory() != second.wallpaper_storage_directory(), "Separate save folders")
	var taskbar = first.get_node("Ui/Taskbar")
	taskbar._on_system_settings_pressed()
	await process_frame
	await process_frame
	var settings = first.get_node("OpenWindows/SystemSettings")
	check(settings.computer == first, "Settings belongs to first computer")
	check(settings.available_wallpapers.size() == 22, "Default plus 21 folder wallpapers")
	check(settings.wallpaper_grid.get_child_count() == 22, "Grid contains preview tiles")
	check(settings.wallpaper_grid.size.y > 132, "Grid has visible area")
	var selected: Texture2D = settings.available_wallpapers[1]
	settings.choice_buttons[1].pressed.emit()
	check(first.wallpaper == selected, "Grid button selects wallpaper")
	check(second.wallpaper == defaults.default_wallpaper, "Selection leaves second computer unchanged")
	check(first.get_node("Ui/Wallpaper").texture == selected, "Desktop updates immediately")
	check(settings.choice_buttons[1].button_pressed, "Current choice is highlighted")
	check(not settings.choice_buttons[0].button_pressed, "Old choice is unselected")
	check(settings.current_label.text.contains(selected.resource_path.get_file().get_basename()), "Current wallpaper label updates")
	settings.get_wallpapers()
	check(settings.wallpaper_grid.get_child_count() == 22, "Rebuilding does not duplicate tiles")
	if "--visual-check" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/wallpaper-settings-debug.png")
	settings.get_node("PanelContainer/VBoxContainer/Header/Full").pressed.emit()
	await process_frame
	await process_frame
	check(settings.wallpaper_grid.columns >= 3, "Grid expands with window")
	settings.get_node("PanelContainer/VBoxContainer/Header/Full").pressed.emit()
	settings.get_node("PanelContainer/VBoxContainer/Header/Close").pressed.emit()
	await process_frame
	taskbar._on_system_settings_pressed()
	settings = first.get_node("OpenWindows/SystemSettings")
	check(settings.choice_buttons[1].button_pressed, "Reopening preserves highlighted selection")
	first.queue_free()
	await process_frame
	first = make_computer("wallpaper-check-first")
	check(first.wallpaper == selected, "Built-in selection survives computer reload")
	check(first.get_node("Ui/Wallpaper").texture == selected, "Reloaded desktop displays saved choice")
	var imported := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	imported.fill(Color.RED)
	var import_path := "user://wallpaper-check-import.png"
	check(imported.save_png(import_path) == OK, "Test import is created")
	first.get_node("Ui/Taskbar")._on_system_settings_pressed()
	settings = first.get_node("OpenWindows/SystemSettings")
	settings._on_file_selected(import_path)
	check(first.wallpaper.get_image().get_pixel(0, 0).is_equal_approx(Color.RED), "Import selects image")
	check(settings.available_wallpapers.size() == 23, "Import appears as current image tile")
	check(second.wallpaper == defaults.default_wallpaper, "Import stays on first computer")
	DirAccess.remove_absolute(import_path)
	first.queue_free()
	await process_frame
	first = make_computer("wallpaper-check-first")
	check(first.wallpaper.get_image().get_pixel(0, 0).is_equal_approx(Color.RED), "Import reloads after original is deleted")
	check(first.set_wallpaper(null) == ERR_INVALID_PARAMETER, "Invalid selection rejected")
	check(first.set_wallpaper(defaults.default_wallpaper) == OK, "Default can be restored")
	check(first.get_node("Ui/Wallpaper").texture == defaults.default_wallpaper, "Restored default displays")
	var original_default: Texture2D = defaults.default_wallpaper
	defaults.default_wallpaper = selected
	var third := make_computer("wallpaper-check-third")
	check(third.wallpaper == selected, "Changing shared default affects new computers")
	check(second.wallpaper == original_default, "Changing default preserves existing choices")
	defaults.default_wallpaper = original_default
	var custom := computer_scene.instantiate()
	custom.wallpaper_save_id = "wallpaper-check-override"
	custom.wallpaper = selected
	root.add_child(custom)
	check(custom.wallpaper == selected, "Inspector override wins over shared default")
	third.get_node("Ui/Taskbar")._on_system_settings_pressed()
	var third_settings = third.get_node("OpenWindows/SystemSettings")
	var folder: String = defaults.default_wallpaper_folder
	defaults.default_wallpaper_folder = "res://missing-wallpaper-folder"
	third_settings.get_wallpapers()
	check(third_settings.available_wallpapers.size() == 2, "Missing folder keeps default and current choices")
	defaults.default_wallpaper_folder = folder
	third.queue_free()
	custom.queue_free()
	first.queue_free()
	second.queue_free()
	await process_frame
	print("WALLPAPER_SETTINGS_CHECK: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
