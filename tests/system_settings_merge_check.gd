extends SceneTree
## Run with --headless --path . --script tests/system_settings_merge_check.gd.
## Use an isolated APPDATA folder: wallpaper selection deliberately saves settings.

var failures: Array[String] = []
var checks := 0
var visual := false


func _initialize() -> void:
	visual = OS.get_cmdline_user_args().has("--visual-check")
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)


func _settle() -> void:
	for frame in range(5):
		await process_frame


func _capture(file_name: String) -> void:
	if visual:
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/" + file_name)


func _run() -> void:
	root.size = Vector2i(1280, 800)
	var result := change_scene_to_file("res://computer.tscn")
	if result != OK:
		push_error("Could not load computer.tscn")
		quit(1)
		return
	await scene_changed
	var computer := current_scene as Computer
	computer.stop_network()
	var taskbar = computer.get_node("Ui/Taskbar")
	var windows = computer.get_node("OpenWindows")
	var wallpaper := computer.get_node("Ui/Wallpaper") as WallpaperController
	var menu := taskbar.get_node("HBoxContainer/StartButton/StartMenu/VBoxContainer")
	menu.get_node("SystemSettings_Start").pressed.emit()
	await _settle()
	var settings := windows.get_node("SystemSettings") as SystemSettings
	_check(settings != null, "Start menu opens merged System Settings")
	_check(taskbar.window_tabs.size() == 1, "Settings creates one taskbar tab")
	_check(not taskbar.start_menu.visible, "Opening settings closes the Start menu")
	_check(settings.wallpaper_grid.get_child_count() == 22, "All 22 wallpaper choices load")
	_check(settings.current_label.text == "Current: " + wallpaper.current_label(), "Current wallpaper label is populated")
	_check(settings.size.x <= root.get_visible_rect().size.x, "Summary header fits within the viewport")
	_check(settings.size == Vector2(816, 600), "Merged window keeps its authored size")

	var summary := settings.get_node("TabContainer/Summary/PanelContainer")
	var metrics := summary.get_node("VBoxContainer/TabContainer/Summary/VBoxContainer")
	computer.upload_speed = 7.0
	computer.download_speed = 11.0
	computer.cpu_cores = 2
	computer.cpu_output = 12.0
	await _settle()
	_check(metrics.get_node("NeworkSpeed").text == "Current Network Speed: 18.0/s", "Summary follows live network values")
	_check(metrics.get_node("TotalCpuCore").text == "Total CPU Cores: 2", "Summary follows core changes")
	_check(metrics.get_node("CpuPerCore").text == "Average Usage per Core: 6.0/s", "Summary shows usage per core")
	_check(metrics.get_node("CurrentPower").text == "Current Power: 95.0", "Opening settings does not charge network power again")
	await _capture("system-settings-summary.png")

	var tabs := settings.get_node("TabContainer") as TabContainer
	tabs.current_tab = 0
	await _settle()
	_check(settings.wallpaper_grid.is_visible_in_tree(), "Display tab reveals wallpaper controls")
	var choice := settings.wallpaper_grid.get_child(1).get_child(1) as Button
	choice.pressed.emit()
	_check(wallpaper.current_file == WallpaperController.BUILTIN_FILES[0], "Wallpaper button updates desktop")
	_check(settings.current_label.text == "Current: " + wallpaper.current_label(), "Wallpaper label updates after selection")
	settings.import_button.pressed.emit()
	_check(settings.file_dialog.visible, "Choose image opens the file dialog")
	settings.file_dialog.hide()
	settings.file_dialog.file_selected.emit(ProjectSettings.globalize_path(WallpaperController.DEFAULT_PATH))
	_check(wallpaper.using_custom_image, "Imported image reaches wallpaper controller")
	settings.wallpaper_grid.get_child(0).get_child(1).pressed.emit()
	_check(not wallpaper.using_custom_image and wallpaper.current_file == WallpaperController.DEFAULT_FILE, "Original wallpaper can be restored")
	await _settle()
	await _capture("system-settings-display.png")

	var headers := [settings.get_node("TabContainer/Display/VBox/Header"), summary.get_node("VBoxContainer/Header/PanelControls/HBoxContainer")]
	for index in range(headers.size()):
		tabs.current_tab = index
		await _settle()
		var header: Node = headers[index]
		var old_position := settings.position
		var old_size := settings.size
		header.get_node("Full").pressed.emit()
		await _settle()
		_check(settings.position == Vector2.ZERO and settings.size == root.get_visible_rect().size, "Tab %d maximizes the whole window" % index)
		header.get_node("Full").pressed.emit()
		await _settle()
		_check(settings.position.is_equal_approx(old_position) and settings.size.is_equal_approx(old_size), "Tab %d restores window bounds" % index)
		header.get_node("Min").pressed.emit()
		_check(not settings.visible and not taskbar.window_tabs[settings].button_pressed, "Tab %d minimizes and updates taskbar" % index)
		taskbar.window_tabs[settings].pressed.emit()
		_check(settings.visible, "Taskbar restores settings from tab %d" % index)

	menu.get_node("SystemSettings_Start").pressed.emit()
	_check(windows.get_child_count() == 1, "Reopening settings reuses its window")
	for index in [1, 0]:
		var header_path: String = "TabContainer/Display/VBox/Header" if index == 0 else "TabContainer/Summary/PanelContainer/VBoxContainer/Header/PanelControls/HBoxContainer"
		settings.get_node(header_path + "/Close").pressed.emit()
		await _settle()
		_check(windows.get_child_count() == 0 and taskbar.window_tabs.is_empty(), "Tab %d closes the entire window and removes its taskbar tab" % index)
		menu.get_node("SystemSettings_Start").pressed.emit()
		await _settle()
		settings = windows.get_node("SystemSettings") as SystemSettings
		_check(settings.wallpaper_grid.get_child_count() == 22, "Reopened settings repopulates wallpaper choices")

	var clock := computer.get_node("Ui/Clock/Button") as Button
	_check(clock.text.ends_with("AM") or clock.text.ends_with("PM"), "Clock starts in 12-hour format")
	clock.pressed.emit()
	_check(clock.text.length() == 8, "Clicking the clock selects 24-hour format")
	menu.get_node("FileManager_Start").pressed.emit()
	await _settle()
	_check(windows.get_child_count() == 2, "File Manager still opens after resolving the merge")
	_check(clock.text.length() == 8, "Other buttons do not change clock format")
	clock.pressed.emit()
	_check(clock.text.ends_with("AM") or clock.text.ends_with("PM"), "Second clock click restores 12-hour format")
	print("SYSTEM_SETTINGS_MERGE_CHECK: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
