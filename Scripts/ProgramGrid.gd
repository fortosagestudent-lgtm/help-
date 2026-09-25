extends Control

var grid := AStarGrid2D.new()

@export_group("Build Area")
@export var grid_size := Vector2i(10, 8)
@export var cell_size := Vector2i(64, 64)


func _ready():
	grid_size = Vector2i(maxi(grid_size.x, 1), maxi(grid_size.y, 1))
	cell_size = Vector2i(maxi(cell_size.x, 1), maxi(cell_size.y, 1))
	size = Vector2(grid_size * cell_size)
	grid.region = Rect2i(Vector2i.ZERO, grid_size)
	grid.cell_size = cell_size
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	
func mouse_to_grid() -> Vector2i:
	var mouse := get_local_mouse_position()

	return Vector2i(
		floor(mouse.x / cell_size.x),
		floor(mouse.y / cell_size.y)
	)
	
func grid_to_position(cell: Vector2i) -> Vector2:
	return Vector2(
		cell.x * cell_size.x + cell_size.x / 2.0,
		cell.y * cell_size.y + cell_size.y / 2.0
	)
	
func place_component(component):
	var cell := mouse_to_grid()
	if not Rect2i(Vector2i.ZERO, grid_size).has_point(cell):
		print("Outside the build area!")
		return

	if grid.is_point_solid(cell):
		print("Can't place here!")
		return

	component.position = grid_to_position(cell)

	grid.set_point_solid(cell, true)
