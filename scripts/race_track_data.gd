extends RefCounted
class_name RaceTrackData

## Kenney modular racing-kit closed loop (clockwise from the start line on the north straight).
const TILE_SIZE := 10.0
const ROAD_HALF_WIDTH := 0.45
const HALF_WIDTH := ROAD_HALF_WIDTH * TILE_SIZE
const WALL_THICKNESS := 8.0
const ROAD_SURFACE_Y := 0.01
const CAR_Y := ROAD_SURFACE_Y + 0.35

const NORTH_Z := -1.15
const EAST_X := 7.15
const SOUTH_Z := 7.85
const WEST_X := -0.85

const CHECKPOINT_INDICES: Array[int] = [0, 9, 18, 27, 36]

const TRACK_BOUNDS := Rect2(-25, -30, 95, 115)
const TRACK_CENTER := Vector3(35.0, ROAD_SURFACE_Y + 2.0, 28.5)


static func _build_centerline() -> Array[Vector3]:
	var points: Array[Vector3] = []
	# North straight (eastbound)
	for i in range(9):
		points.append(_grid_to_world(Vector2(-1.85 + float(i), NORTH_Z)))
	# NE corner
	_append_corner_arc(points, Vector2(6.15, NORTH_Z), Vector2(EAST_X, -0.65), Vector2(6.15, -1.15))
	# East straight (southbound)
	for i in range(4):
		points.append(_grid_to_world(Vector2(EAST_X, -0.65 + float(i) * 2.0)))
	# SE corner
	_append_corner_arc(points, Vector2(EAST_X, 6.35), Vector2(6.15, SOUTH_Z), Vector2(6.15, 6.35))
	# South straight (westbound)
	for i in range(4):
		points.append(_grid_to_world(Vector2(6.15 - float(i) * 2.0, SOUTH_Z)))
	# SW corner
	_append_corner_arc(points, Vector2(0.65, SOUTH_Z), Vector2(WEST_X, 6.35), Vector2(0.65, 6.35))
	# West straight (northbound)
	for i in range(3):
		points.append(_grid_to_world(Vector2(WEST_X, 2.35 - float(i) * 2.0)))
	# West end meets the start straight (no separate NW corner tile)
	return points


static func _grid_to_world(grid: Vector2) -> Vector3:
	return Vector3(grid.x * TILE_SIZE, ROAD_SURFACE_Y, grid.y * TILE_SIZE)


static func _append_corner_arc(
	points: Array[Vector3],
	start: Vector2,
	end: Vector2,
	center: Vector2,
	steps: int = 4
) -> void:
	var start_angle := atan2(start.y - center.y, start.x - center.x)
	var end_angle := atan2(end.y - center.y, end.x - center.x)
	if end_angle < start_angle:
		end_angle += TAU
	for i in range(1, steps):
		var t := float(i) / float(steps)
		var angle := lerpf(start_angle, end_angle, t)
		var point := center + Vector2(cos(angle), sin(angle))
		points.append(_grid_to_world(point))


static func get_centerline() -> Array[Vector3]:
	return _build_centerline()


static func get_ai_waypoints() -> Array[Vector3]:
	return _build_centerline()


static func to_vec2(point: Vector3) -> Vector2:
	return Vector2(point.x, point.z)


static func distance_to_track(point: Vector3) -> float:
	var flat := to_vec2(point)
	var centerline := _build_centerline()
	var best := INF
	for i in centerline.size():
		var start := centerline[i]
		var end := centerline[(i + 1) % centerline.size()]
		best = minf(best, _point_segment_distance(flat, to_vec2(start), to_vec2(end)))
	return best


static func is_on_track_3d(point: Vector3) -> bool:
	return distance_to_track(point) <= HALF_WIDTH * 1.1


static func _point_segment_distance(point: Vector2, start: Vector2, end: Vector2) -> float:
	var segment := end - start
	var length_sq := segment.length_squared()
	if length_sq < 0.001:
		return point.distance_to(start)
	var t := clampf((point - start).dot(segment) / length_sq, 0.0, 1.0)
	return point.distance_to(start + segment * t)


static func tangent_at(index: int) -> Vector3:
	var centerline := _build_centerline()
	var count := centerline.size()
	var prev := centerline[(index - 1 + count) % count]
	var next := centerline[(index + 1) % count]
	var dir := next - prev
	dir.y = 0.0
	return dir.normalized()


static func get_checkpoint_data() -> Array[Dictionary]:
	var centerline := _build_centerline()
	var data: Array[Dictionary] = []
	for i in CHECKPOINT_INDICES.size():
		var index: int = CHECKPOINT_INDICES[i]
		if index >= centerline.size():
			index = index % centerline.size()
		var point := centerline[index]
		var tangent := tangent_at(index)
		data.append({
			"index": i,
			"position": point,
			"rotation": atan2(tangent.z, tangent.x),
		})
	return data


static func get_start_grid() -> Array[Dictionary]:
	var centerline := _build_centerline()
	var direction := centerline[1] - centerline[0]
	direction.y = 0.0
	direction = direction.normalized()
	var right := Vector3(direction.z, 0.0, -direction.x)
	var rot := atan2(direction.z, direction.x)
	var row_gap := 4.0
	var col_gap := 2.5
	var front_row := centerline[0] + direction * 3.0
	var back_row := front_row - direction * row_gap
	var grid: Array[Dictionary] = []
	grid.append({"position": front_row + right * col_gap, "rotation": rot})
	grid.append({"position": front_row - right * col_gap, "rotation": rot})
	grid.append({"position": back_row + right * col_gap, "rotation": rot})
	grid.append({"position": back_row - right * col_gap, "rotation": rot})
	return grid


static func build_outer_wall_segments() -> Array[PackedVector2Array]:
	var centerline := _build_centerline()
	var segments: Array[PackedVector2Array] = []
	for i in centerline.size():
		var start := to_vec2(centerline[i])
		var end := to_vec2(centerline[(i + 1) % centerline.size()])
		var segment := end - start
		var seg_len := segment.length()
		if seg_len < 1.0:
			continue
		var tangent := segment / seg_len
		var normal := Vector2(-tangent.y, tangent.x)
		var offset := HALF_WIDTH + 4.0
		segments.append(PackedVector2Array([
			start + normal * offset,
			end + normal * offset,
		]))
		segments.append(PackedVector2Array([
			start - normal * offset,
			end - normal * offset,
		]))
	return segments
