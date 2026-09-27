# Reading the scripts

Start with `Scripts/Computer.gd`. Each Computer owns its hardware, wallpaper,
current activity reports, and saved program dictionaries. UI scripts read from
their owning Computer rather than assuming the main scene is a Computer.

## Desktop and settings

| Script | Responsibility |
| --- | --- |
| `Scripts/Computer.gd` | Hardware settings, resource timers, activity totals, wallpaper, and in-memory program saves. `find_for()` locates the Computer above a UI node. |
| `Scripts/taskbar.gd` | Start-menu actions and the relationship between windows and taskbar buttons. |
| `Scripts/WindowManager.gd` | Window visibility, maximizing/restoring bounds, and taskbar cleanup. |
| `Scripts/PanelControls/WindowButton.gd` | Common button hookup and locating the containing window. Close/Minimize/Maximize scripts supply the action. |
| `Scripts/PanelControls/ManagerDrag.gd` | Moving/resizing windows while leaving interactive controls usable. |
| `Scripts/SystemManager.gd` | Live Summary labels, grouped to match the six hardware tabs. |
| `Scripts/Wallpaper/SystemSettings.gd` | Wallpaper previews, button events, and import dialog. |
| `Scripts/Wallpaper/WallpaperController.gd` | Displays `Computer.wallpaper` and listens for changes. |
| `Scripts/Wallpaper/WallpaperStorage.gd` | Loads and saves each computer's selection, including copies of imported images. |
| `Time.gd` | Active desktop clock button; click to toggle 12/24-hour time. |
| `Scripts/ClockFormat.gd` | Shared time formatting for the active clock and legacy clock scripts. |
| `file_manager.gd` | File Manager scene root; file operations are not implemented in this script yet. |

Wallpaper files are saved separately for each Computer. `wallpaper_save_id` can
provide stable identity when a computer is renamed or spawned dynamically;
otherwise the scene-tree path supplies its identity. The optional ID must be
different for each computer.

Set `default_wallpaper_folder` and `default_wallpaper` at the top of
`Scripts/WorldConstants.gd`. The grid discovers images in that folder automatically.
New computers use the shared default unless their Inspector wallpaper is set;
a saved selection takes priority over both. Use `Computer.set_wallpaper()` to
save and display a selection; assigning `wallpaper` directly only updates the view.

## Program execution

`Scripts/program_editor.gd` owns one graph and its run timer. Each tick:

1. It follows input wires back to their source components.
2. A cache lets shared sources run once per tick; a separate visiting set detects loops.
3. Components exchange named rates through `evaluate()` dictionaries.
4. The editor reports its consumed network/CPU/GPU rates to its Computer.

`Scripts/Components/ProgramComponent.gd` defines the shared port/UI and save hooks.
Server, Power, CPU, and GPU supply capacity. Router splits network capacity.
File Selector requires **download only** and produces a file rate. File Uploader
consumes files and upload capacity, and accumulates its completed-file count.
Unused capacity does not count as activity. Stopping or closing a program removes
its activity report. CPU/GPU sources currently have no consuming processing node
in the download-only file flow, so that flow leaves their usage at zero.

Network startup charges power once. Network/CPU/GPU usage is a current rate;
RAM output still accumulates. `stop_network()` retains its existing broader role:
it stops all four resource timers. Saved graphs are detached dictionaries in
`Computer.programs`, not disk persistence.

## Grids, game time, and older scripts

- `desktop_manager.gd` builds a viewport-sized AStar grid and converts between
  world coordinates and cells. It clamps path endpoints into that grid.
- `Scripts/ProgramGrid.gd` handles a fixed build area. It rejects placement
  outside the area and tracks occupied cells.
- `Scripts/WorldConstants.gd` is the game-time autoload. Its seconds, minutes,
  hours, and days are elapsed totals, independent of the OS clock.
- `Scripts/PlayerStats.gd` is legacy money/experience UI logic; it is not attached
  to the current Computer scene.
- `TimeClock.gd` and `Time_Clock.gd` retain their old click-anywhere behavior.
  `system_time.gd`, `system_time_2.gd`, and `label.gd` retain their original clock
  formats. `12Hour.gd`, `SwitchTime.gd`, and `button_Time.gd` preserve old file
  paths by inheriting the shared implementation. Despite its name, `12Hour.gd`
  has always displayed 24-hour time.
- `Switch_Time.gd` switches processing between two child labels. `24_hour.gd`
  is an unused two-state prototype with empty behavior hooks.

## Validation

The scripts under `tests/` cover resource activity, settings/window controls,
per-computer wallpaper persistence, and cleanup compatibility. Wallpaper tests
need an isolated `APPDATA` directory because they intentionally save selections.
Third-party scripts under `addons/` are outside this cleanup.
