extends RefCounted
class_name KenneyTrackLayout

## Modular Kenney racing-kit circuit (clockwise from start line on the north straight).
const MODEL_DIR := "res://assets/kenney_racing-kit/Models/GLTF format/"
const TILE_SIZE := 10.0

## Grid placements verified against mesh bounds in-engine (see tests/validate_track.gd).
static func get_road_placements() -> Array[Dictionary]:
	return [
		# North straight — eastbound (rot 1)
		{"mesh": "roadStartPositions", "grid": Vector2i(0, 0), "rot": 1},
		{"mesh": "roadStraightLong", "grid": Vector2i(2, 0), "rot": 1},
		{"mesh": "roadStraightLong", "grid": Vector2i(4, 0), "rot": 1},
		{"mesh": "roadStraight", "grid": Vector2i(6, 0), "rot": 1},
		{"mesh": "roadCornerLarge", "grid": Vector2i(7, 0), "rot": 1},
		# East straight — southbound (rot 2), one tile east of the corner anchor
		{"mesh": "roadStraightLong", "grid": Vector2i(8, 0), "rot": 2},
		{"mesh": "roadStraightLong", "grid": Vector2i(8, 2), "rot": 2},
		{"mesh": "roadStraightLong", "grid": Vector2i(8, 4), "rot": 2},
		{"mesh": "roadStraightLong", "grid": Vector2i(8, 6), "rot": 2},
		{"mesh": "roadCornerLarge", "grid": Vector2i(7, 7), "rot": 2},
		# South straight — westbound (rot 3), one tile south of the corner anchor
		{"mesh": "roadStraightLong", "grid": Vector2i(7, 8), "rot": 3},
		{"mesh": "roadStraightLong", "grid": Vector2i(5, 8), "rot": 3},
		{"mesh": "roadStraightLong", "grid": Vector2i(3, 8), "rot": 3},
		{"mesh": "roadStraightLong", "grid": Vector2i(1, 8), "rot": 3},
		{"mesh": "roadCornerLarge", "grid": Vector2i(0, 8), "rot": 3},
		# West straight — northbound (rot 0), flows directly into the start line
		{"mesh": "roadStraightLong", "grid": Vector2i(0, 6), "rot": 0},
		{"mesh": "roadStraightLong", "grid": Vector2i(0, 4), "rot": 0},
		{"mesh": "roadStraightLong", "grid": Vector2i(0, 2), "rot": 0},
	]


static func get_decor_placements() -> Array[Dictionary]:
	return [
		{"mesh": "grandStand", "grid": Vector2i(-1, 2), "rot": 1},
		{"mesh": "grandStand", "grid": Vector2i(-1, 5), "rot": 1},
		{"mesh": "grandStandCovered", "grid": Vector2i(9, 3), "rot": 2},
		{"mesh": "grandStandRound", "grid": Vector2i(4, 10), "rot": 3},
		{"mesh": "pitsGarage", "grid": Vector2i(2, -2), "rot": 0},
		{"mesh": "pitsGarageCorner", "grid": Vector2i(4, -2), "rot": 0},
		{"mesh": "flagCheckers", "grid": Vector2i(-1, 0), "rot": 1},
		{"mesh": "overhead", "grid": Vector2i(0, 0), "rot": 1},
		{"mesh": "lightPostModern", "grid": Vector2i(3, -1), "rot": 0},
		{"mesh": "lightPostModern", "grid": Vector2i(6, 9), "rot": 2},
		{"mesh": "grass", "grid": Vector2i(-2, 4), "rot": 0},
		{"mesh": "grass", "grid": Vector2i(10, 5), "rot": 0},
		{"mesh": "grass", "grid": Vector2i(5, -3), "rot": 0},
		{"mesh": "treeLarge", "grid": Vector2i(-2, 7), "rot": 0},
		{"mesh": "treeLarge", "grid": Vector2i(10, 0), "rot": 0},
		{"mesh": "treeSmall", "grid": Vector2i(-1, 8), "rot": 0},
		{"mesh": "treeSmall", "grid": Vector2i(9, 9), "rot": 0},
		{"mesh": "barrierRed", "grid": Vector2i(9, 0), "rot": 1},
		{"mesh": "barrierRed", "grid": Vector2i(0, 9), "rot": 2},
	]


static func grid_to_world(grid: Vector2) -> Vector3:
	return Vector3(grid.x * TILE_SIZE, 0.0, grid.y * TILE_SIZE)


static func piece_transform(grid: Vector2i, rotation_steps: int) -> Transform3D:
	var basis := Basis(Vector3.UP, deg_to_rad(float(rotation_steps) * -90.0))
	return Transform3D(basis, Vector3(grid.x, 0.0, grid.y))


static func model_path(mesh_name: String) -> String:
	return MODEL_DIR + mesh_name + ".glb"
