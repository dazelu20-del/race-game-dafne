extends RefCounted
class_name MonacoTrackData

## Monaco GP centerline (clockwise), scaled to the game world.
const HALF_WIDTH := 58.0
const WALL_THICKNESS := 14.0

const CENTERLINE: Array[Vector2] = [
	Vector2(210, 780),
	Vector2(210, 700),
	Vector2(210, 620),
	Vector2(210, 540),
	Vector2(215, 460),
	Vector2(245, 385),
	Vector2(320, 320),
	Vector2(450, 275),
	Vector2(600, 250),
	Vector2(760, 245),
	Vector2(920, 265),
	Vector2(1045, 310),
	Vector2(1110, 375),
	Vector2(1105, 435),
	Vector2(1060, 485),
	Vector2(985, 520),
	Vector2(945, 510),
	Vector2(955, 565),
	Vector2(1005, 610),
	Vector2(1060, 640),
	Vector2(1170, 690),
	Vector2(1280, 730),
	Vector2(1390, 750),
	Vector2(1500, 730),
	Vector2(1535, 695),
	Vector2(1490, 665),
	Vector2(1380, 655),
	Vector2(1270, 665),
	Vector2(1175, 690),
	Vector2(1090, 705),
	Vector2(1010, 720),
	Vector2(930, 738),
	Vector2(820, 752),
	Vector2(620, 772),
	Vector2(450, 778),
	Vector2(320, 780),
]

const CHECKPOINT_INDICES: Array[int] = [0, 7, 14, 20, 26, 31]

const TRACK_BOUNDS := Rect2(0, 0, 1800, 1080)
const TRACK_CENTER := Vector2(900, 520)

const LANE_COUNT := 3
const SPACE_LENGTH := 34.0
const KERB_WIDTH := 8.0
const KERB_STRIPE_LENGTH := 13.0

const TUNNEL_SEGMENT_INDICES: Array[int] = [23, 24, 25, 26]

const TURN_LABELS: Array[Dictionary] = [
	{"name": "1 St Devote", "index": 5},
	{"name": "2 Casino", "index": 10},
	{"name": "3 Mirabeau", "index": 13},
	{"name": "4 Grand Hotel", "index": 15},
	{"name": "5 Chicane", "index": 17},
	{"name": "6 Tabac", "index": 19},
	{"name": "7 Piscine", "index": 26},
	{"name": "8 Rascasse", "index": 30},
]


static func get_centerline() -> PackedVector2Array:
	return PackedVector2Array(CENTERLINE)


static func get_ai_waypoints() -> Array[Vector2]:
	return CENTERLINE.duplicate()


static func distance_to_track(point: Vector2) -> float:
	var center := get_centerline()
	var best := INF
	for i in center.size():
		var start := center[i]
		var end := center[(i + 1) % center.size()]
		best = minf(best, _point_segment_distance(point, start, end))
	return best


static func is_on_track(point: Vector2) -> bool:
	return distance_to_track(point) <= HALF_WIDTH * 0.92


static func _point_segment_distance(point: Vector2, start: Vector2, end: Vector2) -> float:
	var segment := end - start
	var length_sq := segment.length_squared()
	if length_sq < 0.001:
		return point.distance_to(start)
	var t := clampf((point - start).dot(segment) / length_sq, 0.0, 1.0)
	return point.distance_to(start + segment * t)


static func get_checkpoint_data() -> Array[Dictionary]:
	var data: Array[Dictionary] = []
	for i in CHECKPOINT_INDICES.size():
		var index := CHECKPOINT_INDICES[i]
		var point := CENTERLINE[index]
		var tangent := tangent_at(index)
		data.append({
			"index": i,
			"position": point,
			"rotation": tangent.angle(),
		})
	return data


static func get_start_grid() -> Array[Dictionary]:
	var direction := (CENTERLINE[1] - CENTERLINE[0]).normalized()
	var right := direction.orthogonal()
	var rot := direction.angle()
	var row_gap := 38.0
	var col_gap := 22.0
	var front_row := CENTERLINE[0] + direction * 25.0
	var back_row := front_row - direction * row_gap
	var grid: Array[Dictionary] = []
	grid.append({"position": front_row + right * col_gap, "rotation": rot})
	grid.append({"position": front_row - right * col_gap, "rotation": rot})
	grid.append({"position": back_row + right * col_gap, "rotation": rot})
	grid.append({"position": back_row - right * col_gap, "rotation": rot})
	return grid


static func build_segment_polygons() -> Array[PackedVector2Array]:
	var center := get_centerline()
	var count := center.size()
	var segments: Array[PackedVector2Array] = []

	for i in count:
		var start := center[i]
		var end := center[(i + 1) % count]
		var direction := (end - start).normalized()
		var normal := direction.orthogonal() * HALF_WIDTH
		segments.append(PackedVector2Array([
			start + normal,
			end + normal,
			end - normal,
			start - normal,
		]))

	return segments


static func build_edges() -> Dictionary:
	var center := get_centerline()
	var count := center.size()
	var outer: PackedVector2Array = []
	var inner: PackedVector2Array = []

	for i in count:
		var tangent := tangent_at(i)
		var normal := tangent.orthogonal()
		outer.append(center[i] + normal * HALF_WIDTH)
		inner.append(center[i] - normal * HALF_WIDTH)

	return {"outer": outer, "inner": inner}


static func tangent_at(index: int) -> Vector2:
	var count := CENTERLINE.size()
	var prev := CENTERLINE[(index - 1 + count) % count]
	var next := CENTERLINE[(index + 1) % count]
	return (next - prev).normalized()


static func lane_width() -> float:
	return (HALF_WIDTH * 2.0) / float(LANE_COUNT)


static func lane_center_offset(lane: int) -> float:
	return -HALF_WIDTH + lane_width() * (float(lane) + 0.5)


static func lane_boundary_offsets() -> Array[float]:
	var w := lane_width()
	return [-HALF_WIDTH + w, -HALF_WIDTH + w * 2.0]


static func sample_closed_path(spacing: float) -> PackedVector2Array:
	var samples := PackedVector2Array()
	var count := CENTERLINE.size()
	for i in count:
		var start := CENTERLINE[i]
		var end := CENTERLINE[(i + 1) % count]
		var segment := end - start
		var seg_len := segment.length()
		if seg_len < 0.001:
			continue
		var direction := segment / seg_len
		var traveled := 0.0
		while traveled < seg_len - 0.001:
			samples.append(start + direction * traveled)
			traveled += spacing
	if samples.is_empty():
		samples.append(CENTERLINE[0])
	return samples


static func build_board_spaces() -> Array[Dictionary]:
	var samples := sample_closed_path(SPACE_LENGTH)
	var spaces: Array[Dictionary] = []
	var lane_w := lane_width()
	var count := samples.size()

	for i in count:
		var p0 := samples[i]
		var p1 := samples[(i + 1) % count]
		var tangent := (p1 - p0).normalized()
		if tangent.length_squared() < 0.001:
			continue
		var normal := tangent.orthogonal()

		for lane in LANE_COUNT:
			var inner := -HALF_WIDTH + lane_w * float(lane)
			var outer := inner + lane_w
			spaces.append({
				"polygon": PackedVector2Array([
					p0 + normal * inner,
					p0 + normal * outer,
					p1 + normal * outer,
					p1 + normal * inner,
				]),
				"lane": lane,
				"index": i,
				"center": (p0 + p1) * 0.5 + normal * (inner + outer) * 0.5,
			})

	return spaces


static func build_segment_polygon_at(index: int) -> PackedVector2Array:
	var start := CENTERLINE[index]
	var end := CENTERLINE[(index + 1) % CENTERLINE.size()]
	var direction := (end - start).normalized()
	var normal := direction.orthogonal() * HALF_WIDTH
	return PackedVector2Array([
		start + normal,
		end + normal,
		end - normal,
		start - normal,
	])


static func build_kerb_stripes(edge: PackedVector2Array, outward_sign: float) -> Array[Dictionary]:
	var stripes: Array[Dictionary] = []
	for i in edge.size():
		var start := edge[i]
		var end := edge[(i + 1) % edge.size()]
		var segment := end - start
		var seg_len := segment.length()
		if seg_len < 1.0:
			continue
		var tangent := segment / seg_len
		var outward := tangent.orthogonal() * outward_sign
		var pos := 0.0
		var stripe_idx := 0
		while pos < seg_len:
			var stripe_end := minf(pos + KERB_STRIPE_LENGTH, seg_len)
			var a := start + tangent * pos
			var b := start + tangent * stripe_end
			var color := Color(0.92, 0.14, 0.14) if stripe_idx % 2 == 0 else Color(0.96, 0.96, 0.96)
			stripes.append({
				"polygon": PackedVector2Array([
					a - outward * KERB_WIDTH * 0.3,
					b - outward * KERB_WIDTH * 0.3,
					b + outward * KERB_WIDTH * 0.7,
					a + outward * KERB_WIDTH * 0.7,
				]),
				"color": color,
			})
			pos += KERB_STRIPE_LENGTH
			stripe_idx += 1
	return stripes


static func build_dashed_offset_path(offset: float, dash_len: float, gap_len: float) -> Array[PackedVector2Array]:
	var dashes: Array[PackedVector2Array] = []
	var count := CENTERLINE.size()
	for i in count:
		var start := CENTERLINE[i]
		var end := CENTERLINE[(i + 1) % count]
		var segment := end - start
		var seg_len := segment.length()
		if seg_len < 0.001:
			continue
		var tangent := segment / seg_len
		var normal := tangent.orthogonal() * offset
		var pos := 0.0
		var drawing := true
		while pos < seg_len:
			var step := dash_len if drawing else gap_len
			var next_pos := minf(pos + step, seg_len)
			if drawing:
				dashes.append(PackedVector2Array([
					start + tangent * pos + normal,
					start + tangent * next_pos + normal,
				]))
			pos = next_pos
			drawing = not drawing
	return dashes


static func get_turn_label_positions() -> Array[Dictionary]:
	var labels: Array[Dictionary] = []
	for data in TURN_LABELS:
		var idx: int = data["index"]
		var point := CENTERLINE[idx]
		var tangent := tangent_at(idx)
		var normal := tangent.orthogonal()
		labels.append({
			"name": data["name"],
			"position": point + normal * (HALF_WIDTH + 28.0),
			"rotation": tangent.angle(),
		})
	return labels


static func build_outer_wall_segments() -> Array[PackedVector2Array]:
	var center := get_centerline()
	var count := center.size()
	var centroid := Vector2.ZERO
	for point in center:
		centroid += point
	centroid /= float(count)

	var segments: Array[PackedVector2Array] = []
	for i in count:
		var start := center[i]
		var end := center[(i + 1) % count]
		var segment := end - start
		var seg_len := segment.length()
		if seg_len < 1.0:
			continue
		var tangent := segment / seg_len
		var normal_a := tangent.orthogonal()
		var normal_b := -normal_a
		var mid := (start + end) * 0.5
		var outward := normal_a
		if (mid + normal_a * HALF_WIDTH).distance_to(centroid) < (mid + normal_b * HALF_WIDTH).distance_to(centroid):
			outward = normal_b
		var offset := HALF_WIDTH + 4.0
		segments.append(PackedVector2Array([
			start + outward * offset,
			end + outward * offset,
		]))
	return segments
