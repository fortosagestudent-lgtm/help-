extends PanelContainer


# ============================================================
# SCENES
# ============================================================

const SYSTEM_SETTINGS_SCENE: PackedScene = preload("res://SystemSettings.tscn")

const FILE_MANAGER_SCENE: PackedScene = preload("res://file_manager.tscn")


# ============================================================
# NODE REFERENCES
# ============================================================

@onready var start_menu: PanelContainer = %StartMenu
@onready var open_windows: CanvasLayer = $"../../OpenWindows"
@onready var wallpaper_controller: WallpaperController = $"../Wallpaper"
@onready var tab_row: HBoxContainer = $HBoxContainer


# ============================================================
# VARIABLES
# ============================================================

# Stores each open window and its taskbar button.
#
# Example:
# SystemManager -> Button
# FileManager   -> Button
var window_tabs: Dictionary = {}


# ============================================================
# READY
# ============================================================

func _ready() -> void:
	open_windows.taskbar = self

	# Add taskbar tabs for any windows that already exist.
	for window in open_windows.get_children():
		if window is CanvasItem:
			add_window_tab(window)


# ============================================================
# ADD WINDOW TAB
# ============================================================

func add_window_tab(window: CanvasItem) -> void:
	
	# Don't create another tab if this window already has one.
	if window_tabs.has(window):
		return

	var tab := Button.new()

	tab.toggle_mode = true

	# Use the root node's name as the taskbar name.
	# Example:
	#
	# SystemManager -> System Manager
	# FileManager   -> File Manager
	#
	tab.text = window.name.capitalize()

	tab.tooltip_text = tab.text

	# When the taskbar button is pressed, send the window
	# associated with that button.
	tab.pressed.connect(
		_on_window_tab_pressed.bind(window)
	)

	tab_row.add_child(tab)

	# Store the relationship between the window and its button.
	window_tabs[window] = tab

	update_window_tab(window)


# ============================================================
# REMOVE WINDOW TAB
# ============================================================

func remove_window_tab(window: Node) -> void:
	var tab: Button = window_tabs.get(window)

	if tab != null:
		tab.queue_free()

	window_tabs.erase(window)


# ============================================================
# UPDATE WINDOW TAB
# ============================================================

func update_window_tab(window: CanvasItem) -> void:
	var tab: Button = window_tabs.get(window)

	if tab != null:
		# Button appears pressed while the window is visible.
		tab.button_pressed = window.visible


# ============================================================
# TASKBAR BUTTON PRESSED
# ============================================================

func _on_window_tab_pressed(window: CanvasItem) -> void:
	
	# Make sure the window still exists.
	if not is_instance_valid(window):
		return

	# If it's currently visible, minimize it.
	if window.visible:
		open_windows.minimize_window(window)

	# Otherwise restore it.
	else:
		open_windows.restore_window(window)


# ============================================================
# START BUTTON
# ============================================================

func _on_start_button_pressed() -> void:
	start_menu.visible = !start_menu.visible





# ============================================================
# PROGRAM MANAGER
# ============================================================

func _on_program_manager_pressed() -> void:
	var computer := get_tree().current_scene as Computer

	if computer == null:
		push_warning(
			"Program Manager needs the current scene to be a Computer."
		)
		return

	computer.open_program_editor()

	start_menu.hide()


# ============================================================
# SYSTEM SETTINGS
# ============================================================

func _on_system_settings_pressed() -> void:
	
	# Check if System Settings is already open.
	var existing_window := open_windows.get_node_or_null(
		"SystemSettings"
	) as Control

	if existing_window != null:
		open_windows.restore_window(existing_window)

	else:
		var settings_window := SYSTEM_SETTINGS_SCENE.instantiate() as SystemSettings

		settings_window.wallpaper_controller = wallpaper_controller

		open_windows.add_child(settings_window)

	start_menu.hide()


# ============================================================
# FILE MANAGER
# ============================================================

func _on_file_manager_start_pressed() -> void:
	var new_file_manager := FILE_MANAGER_SCENE.instantiate()

	open_windows.add_child(new_file_manager)

	start_menu.hide()
