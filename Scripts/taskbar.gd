extends PanelContainer

const SYSTEM_SETTINGS_SCENE: PackedScene = preload("res://SystemSettings.tscn")

@onready var start_menu: PanelContainer = %StartMenu
@onready var open_windows: CanvasLayer = $"../../OpenWindows"
@onready var wallpaper_controller: WallpaperController = $"../Wallpaper"
@onready var tab_row: HBoxContainer = $HBoxContainer

var window_tabs: Dictionary = {}


func _ready() -> void:
	open_windows.taskbar = self
	for window in open_windows.get_children():
		add_window_tab(window)


func add_window_tab(window: CanvasItem) -> void:
	if window_tabs.has(window):
		return
	var tab := Button.new()
	tab.toggle_mode = true
	tab.text = _window_title(window)
	tab.tooltip_text = tab.text
	tab.pressed.connect(_on_window_tab_pressed.bind(window))
	tab_row.add_child(tab)
	window_tabs[window] = tab
	update_window_tab(window)


func remove_window_tab(window: Node) -> void:
	var tab: Button = window_tabs.get(window)
	if tab != null:
		tab.queue_free()
	window_tabs.erase(window)


func update_window_tab(window: CanvasItem) -> void:
	var tab: Button = window_tabs.get(window)
	if tab != null:
		tab.button_pressed = window.visible


func _on_window_tab_pressed(window: CanvasItem) -> void:
	if not is_instance_valid(window):
		return
	if window.visible:
		open_windows.minimize_window(window)
	else:
		open_windows.restore_window(window)


func _window_title(window: Node) -> String:
	if window is SystemSettings:
		return "Settings"
	if window is PanelContainer:
		return "System Manager"
	return "Program Manager"


func _on_start_button_pressed() -> void:
	start_menu.visible =!start_menu.visible


func _on_system_manager_start_pressed() -> void:
	var system_manager = preload("res://SystemManagerWindow.tscn")
	var new_system_manager = system_manager.instantiate()
	open_windows.add_child(new_system_manager)
	start_menu.hide()


func _on_program_manager_pressed() -> void:
	var computer := get_tree().current_scene as Computer
	if computer == null:
		push_warning("Program Manager needs the current scene to be a Computer.")
		return

	computer.open_program_editor()
	start_menu.hide()


func _on_system_settings_pressed() -> void:
	var existing_window := open_windows.get_node_or_null("SystemSettings") as Control
	if existing_window != null:
		open_windows.restore_window(existing_window)
	else:
		var settings_window := SYSTEM_SETTINGS_SCENE.instantiate() as SystemSettings
		settings_window.wallpaper_controller = wallpaper_controller
		open_windows.add_child(settings_window)
	start_menu.hide()
