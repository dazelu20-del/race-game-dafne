extends RefCounted
class_name RaceTrackData

## Low-poly race track layout aligned to the GLB road mesh (clockwise from start line).
const TRACK_SCALE := 15.0
const ROAD_HALF_WIDTH := 1.35
const HALF_WIDTH := ROAD_HALF_WIDTH * TRACK_SCALE
const WALL_THICKNESS := 8.0
const ROAD_SURFACE_Y := 1.35
const CAR_Y := ROAD_SURFACE_Y + 0.35

## Unscaled XZ centerline traced along the road surface in the model.
const _CENTERLINE_RAW: Array[Vector2] = [
	Vector2(0.0, -0.02),
	Vector2(0.0, -0.65),
	Vector2(0.0, -2.0),
	Vector2(0.0, -4.5),
	Vector2(0.5, -6.5),
	Vector2(1.19, -7.97),
	Vector2(1.0, -6.5),
	Vector2(0.3, -4.0),
	Vector2(-0.3, -2.0),
	Vector2(-0.7, -1.0),
	Vector2(-1.2, -0.6),
	Vector2(-1.8, -0.55),
	Vector2(-2.8, -0.5),
	Vector2(-3.07, 0.0),
	Vector2(-3.4, 0.3),
	Vector2(-2.8, 1.0),
	Vector2(-1.5, 1.8),
	Vector2(-0.5, 2.5),
	Vector2(0.0, 4.0),
	Vector2(0.0, 5.8),
	Vector2(-0.26, 5.5),
	Vector2(-0.7, 4.0),
	Vector2(-0.61, 2.0),
	Vector2(-0.5, 0.8),
	Vector2(0.0, 0.67),
	Vector2(0.66, 0.3),
	Vector2(1.8, 0.2),
	Vector2(3.0, 0.1),
	Vector2(3.8, -0.2),
	Vector2(2.5, -0.5),
	Vector2(1.2, -0.4),
	Vector2(0.3, -0.2),
]

const CHECKPOINT_INDICES: Array[int] = [0, 6, 12, 18, 24]

const TRACK_BOUNDS := Rect2(-72, -126, 144, 108)
const TRACK_CENTER := Vector3(0, ROAD_SURFACE_Y + 2.0, -52)


static func _build_centerline() -> Array[Vector3]:
	var points: Array[Vector3] = []
	for point in _CENTERLINE_RAW:
		points.append(Vector3(point.x * TRACK_SCALE, ROAD_SURFACE_Y, point.y * TRACK_SCALE))
	return points


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
		var index := CHECKPOINT_INDICES[i]
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
