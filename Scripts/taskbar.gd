extends PanelContainer
## Owns Start-menu actions and one taskbar button per open window. WindowManager owns visibility and window lifetime.

const SYSTEM_SETTINGS_SCENE: PackedScene = preload("res://Scenes/SystemSettings.tscn")

const FILE_MANAGER_SCENE: PackedScene = preload("res://Scenes/file_manager.tscn")

@onready var start_menu: PanelContainer = %StartMenu
@onready var open_windows: CanvasLayer = $"../../OpenWindows"
@onready var computer: Computer = Computer.find_for(self)
@onready var tab_row: HBoxContainer = $HBoxContainer
# Maps each live window to its button; the window object is the dictionary key.
var window_tabs: Dictionary = {}


func _ready() -> void:
	open_windows.taskbar = self
	for window in open_windows.get_children():
		if window is CanvasItem:
			add_window_tab(window)


func add_window_tab(window: CanvasItem) -> void:
	if window_tabs.has(window):
		return

	var tab := Button.new()

	tab.toggle_mode = true
	tab.text = window.name.capitalize()

	tab.tooltip_text = tab.text
	tab.pressed.connect(
		_on_window_tab_pressed.bind(window)
	)

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

## A visible window minimizes; a hidden one restores with its state intact.
func _on_window_tab_pressed(window: CanvasItem) -> void:
	if not is_instance_valid(window):
		return
	if window.visible:
		open_windows.minimize_window(window)
	else:
		open_windows.restore_window(window)


func _on_start_button_pressed() -> void:
	start_menu.visible = !start_menu.visible


func _on_program_manager_pressed() -> void:
	if computer == null:
		push_warning(
			"Program Manager needs an owning Computer."
		)
		return

	computer.open_program_editor()

	start_menu.hide()

## Reuse one settings window per Computer; File Manager can open multiple windows.
func _on_system_settings_pressed() -> void:
	var existing_window := open_windows.get_node_or_null(
		"SystemSettings"
	) as Control

	if existing_window != null:
		open_windows.restore_window(existing_window)

	else:
		var settings_window := SYSTEM_SETTINGS_SCENE.instantiate() as SystemSettings

		settings_window.computer = computer

		open_windows.add_child(settings_window)

	start_menu.hide()


func _on_file_manager_start_pressed() -> void:
	var new_file_manager := FILE_MANAGER_SCENE.instantiate()

	open_windows.add_child(new_file_manager)

	start_menu.hide()
