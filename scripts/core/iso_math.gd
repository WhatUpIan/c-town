class_name IsoMath
extends Object

## Diagnostic projection (cell centers). Runtime prefers TileMapLayer map_to_local when available.

static func cell_to_screen(cell: Vector2i) -> Vector2:
	return Vector2((cell.x - cell.y) * 32.0, (cell.x + cell.y) * 16.0)

static func screen_to_cell(screen: Vector2) -> Vector2:
	var cell_x := screen.x / 64.0 + screen.y / 32.0
	var cell_y := screen.y / 32.0 - screen.x / 64.0
	return Vector2(cell_x, cell_y)
