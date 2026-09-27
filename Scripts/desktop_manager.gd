extends Node2D
## Viewport-sized pathfinding grid. Converts world positions to cells, clamps
## endpoints to the desktop, and returns paths through cell centers.
@export var cell_size: Vector2 = Vector2(32, 32)
var astar_grid: AStarGrid2D = AStarGrid2D.new()
var viewport_rect: Rect2


func _ready() -> void:
	create_astar_grid()

## Build once from the current viewport. update() resets AStar cell data.
func create_astar_grid() -> void:
	viewport_rect = get_viewport_rect()
	var grid_width: int = ceil(viewport_rect.size.x / cell_size.x)
	var grid_height: int = ceil(viewport_rect.size.y / cell_size.y)
	astar_grid.region = Rect2i(
		Vector2i.ZERO,
		Vector2i(grid_width, grid_height)
	)
	astar_grid.cell_size = cell_size
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()


## to_local accounts for this node's transform before dividing by cell size.
func world_to_grid(world_position: Vector2) -> Vector2i:

	var local_position: Vector2 = to_local(world_position)

	var grid_position := Vector2i(
		floor(local_position.x / cell_size.x),
		floor(local_position.y / cell_size.y)
	)

	return clamp_grid_position(grid_position)


func grid_to_world(grid_position: Vector2i) -> Vector2:
	var local_position := Vector2(
		grid_position.x * cell_size.x + cell_size.x / 2.0,
		grid_position.y * cell_size.y + cell_size.y / 2.0
	)

	return to_global(local_position)


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

## AStar returns cell IDs; callers need world positions for drawing or movement.
func get_world_path(
	start_world: Vector2,
	end_world: Vector2
) -> PackedVector2Array:

	var start_grid: Vector2i = world_to_grid(start_world)
	var end_grid: Vector2i = world_to_grid(end_world)
	var grid_path: Array[Vector2i] = astar_grid.get_id_path(
		start_grid,
		end_grid
	)

	var world_path := PackedVector2Array()
	for grid_position: Vector2i in grid_path:
		world_path.append(
			grid_to_world(grid_position)
		)

	return world_path


func block_cell(grid_position: Vector2i) -> void:

	if astar_grid.region.has_point(grid_position):
		astar_grid.set_point_solid(grid_position, true)


func unblock_cell(grid_position: Vector2i) -> void:

	if astar_grid.region.has_point(grid_position):
		astar_grid.set_point_solid(grid_position, false)


func is_cell_blocked(grid_position: Vector2i) -> bool:

	if not astar_grid.region.has_point(grid_position):
		return true

	return astar_grid.is_point_solid(grid_position)
