class_name GroundBuilder
extends RefCounted

## Builds an isometric TileMapLayer (64×32 diamonds) matching IsoMath projection.

const MAP_ORIGIN := Vector2(400, 60)
const TILE_SIZE := Vector2i(64, 32)

const SOURCE_EARTH := 0
const SOURCE_PATH := 1
const SOURCE_SOIL := 2
const SOURCE_WATER := 3

static func build_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	ts.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
	ts.tile_offset_axis = TileSet.TILE_OFFSET_AXIS_HORIZONTAL
	ts.tile_size = TILE_SIZE
	_add_source(ts, SOURCE_EARTH, "res://assets/placeholders/ground_earth.png")
	_add_source(ts, SOURCE_PATH, "res://assets/placeholders/ground_path.png")
	_add_source(ts, SOURCE_SOIL, "res://assets/placeholders/ground_soil.png")
	_add_source(ts, SOURCE_WATER, "res://assets/placeholders/ground_water.png")
	return ts

static func _add_source(ts: TileSet, preferred_id: int, path: String) -> void:
	var src := TileSetAtlasSource.new()
	src.texture = load(path)
	src.texture_region_size = TILE_SIZE
	# Ensure atlas has a tile at (0,0)
	if not src.has_tile(Vector2i(0, 0)):
		src.create_tile(Vector2i(0, 0))
	var assigned: int = ts.add_source(src, preferred_id)
	if assigned != preferred_id:
		push_warning("Tile source id %d assigned as %d for %s" % [preferred_id, assigned, path])

static func fill_village(layer: TileMapLayer) -> void:
	layer.clear()
	for x in range(0, 22):
		for y in range(0, 16):
			var cell := Vector2i(x, y)
			var source_id := SOURCE_EARTH
			if x >= 18:
				source_id = SOURCE_WATER
			elif x >= 6 and x <= 8 and y >= 8 and y <= 9:
				source_id = SOURCE_SOIL
			elif (y == 6 and x < 18) or (x == 10 and y < 10):
				source_id = SOURCE_PATH
			layer.set_cell(cell, source_id, Vector2i(0, 0))

static func add_water_collision(host: Node2D, layer: TileMapLayer) -> void:
	## Footprint blockers for water cells using TileMapLayer map_to_local.
	for x in range(18, 22):
		for y in range(0, 16):
			var cell := Vector2i(x, y)
			var body := StaticBody2D.new()
			body.position = layer.to_global(layer.map_to_local(cell))
			body.collision_layer = 1
			var cs := CollisionShape2D.new()
			var shape := RectangleShape2D.new()
			shape.size = Vector2(40, 20)
			cs.shape = shape
			body.add_child(cs)
			host.add_child(body)

static func cell_world_pos(layer: TileMapLayer, cell: Vector2i) -> Vector2:
	return layer.to_global(layer.map_to_local(cell))
