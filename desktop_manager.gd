extends Node2D

# ============================================================
# ASTAR GRID SETTINGS
# ============================================================

# Size of each grid cell in pixels.
# Example: 32 means each cell is 32x32 pixels.
@export var cell_size: Vector2 = Vector2(32, 32)

# The invisible AStar grid used for pathfinding.
var astar_grid: AStarGrid2D = AStarGrid2D.new()

# Size of the viewport in pixels.
var viewport_rect: Rect2


# ============================================================
# READY
# ============================================================

func _ready() -> void:
	create_astar_grid()


# ============================================================
# CREATE GRID FROM VIEWPORT
# ============================================================

func create_astar_grid() -> void:

	# Get the viewport rectangle.
	viewport_rect = get_viewport_rect()

	# Figure out how many grid cells fit inside the viewport.
	var grid_width: int = ceil(viewport_rect.size.x / cell_size.x)
	var grid_height: int = ceil(viewport_rect.size.y / cell_size.y)

	# Tell AStarGrid2D how large the grid is.
	astar_grid.region = Rect2i(
		Vector2i.ZERO,
		Vector2i(grid_width, grid_height)
	)

	# Set the physical size of each grid cell.
	astar_grid.cell_size = cell_size

	# Prevent diagonal movement.
	# This is useful for your wires because they will only
	# travel horizontally and vertically.
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER

	# Apply the settings.
	astar_grid.update()

	print("Viewport size: ", viewport_rect.size)
	print("Grid size: ", grid_width, " x ", grid_height)


# ============================================================
# WORLD POSITION -> GRID CELL
# ============================================================

func world_to_grid(world_position: Vector2) -> Vector2i:

	var local_position: Vector2 = to_local(world_position)

	var grid_position := Vector2i(
		floor(local_position.x / cell_size.x),
		floor(local_position.y / cell_size.y)
	)

	return clamp_grid_position(grid_position)


# ============================================================
# GRID CELL -> WORLD POSITION
# ============================================================

func grid_to_world(grid_position: Vector2i) -> Vector2:

	# Find center of cell.
	var local_position := Vector2(
		grid_position.x * cell_size.x + cell_size.x / 2.0,
		grid_position.y * cell_size.y + cell_size.y / 2.0
	)

	return to_global(local_position)


# ============================================================
# KEEP GRID POSITION INSIDE BUILD AREA
# ============================================================

func clamp_grid_position(grid_position: Vector2i) -> Vector2i:

	var region: Rect2i = astar_grid.region

	grid_position.x = clamp(
		grid_position.x,
		region.position.x,
		region.end.x - 1
	)

	grid_position.y = clamp(
		grid_position.y,
		region.position.y,
		region.end.y - 1
	)

	return grid_position


# ============================================================
# FIND PATH BETWEEN TWO WORLD POSITIONS
# ============================================================

func get_world_path(
	start_world: Vector2,
	end_world: Vector2
) -> PackedVector2Array:

	var start_grid: Vector2i = world_to_grid(start_world)
	var end_grid: Vector2i = world_to_grid(end_world)

	# Get the path in grid coordinates.
	var grid_path: Array[Vector2i] = astar_grid.get_id_path(
		start_grid,
		end_grid
	)

	var world_path := PackedVector2Array()

	# Convert every grid cell back into a world position.
	for grid_position: Vector2i in grid_path:
		world_path.append(
			grid_to_world(grid_position)
		)

	return world_path


# ============================================================
# BLOCK A CELL
# ============================================================

func block_cell(grid_position: Vector2i) -> void:

	if astar_grid.region.has_point(grid_position):
		astar_grid.set_point_solid(grid_position, true)


# ============================================================
# UNBLOCK A CELL
# ============================================================

func unblock_cell(grid_position: Vector2i) -> void:

	if astar_grid.region.has_point(grid_position):
		astar_grid.set_point_solid(grid_position, false)


# ============================================================
# CHECK IF CELL IS BLOCKED
# ============================================================

func is_cell_blocked(grid_position: Vector2i) -> bool:

	if not astar_grid.region.has_point(grid_position):
		return true

	return astar_grid.is_point_solid(grid_position)
