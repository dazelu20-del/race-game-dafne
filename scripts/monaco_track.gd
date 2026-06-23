class_name MonacoTrack
extends Node2D

const ASPHALT_A := Color(0.36, 0.37, 0.39)
const ASPHALT_B := Color(0.42, 0.43, 0.45)
const LANE_YELLOW := Color(0.98, 0.86, 0.12)
const EDGE_WHITE := Color(0.95, 0.95, 0.95, 0.85)
const WATER_COLOR := Color(0.12, 0.48, 0.78)
const WATER_DEEP := Color(0.08, 0.38, 0.68)
const GRASS_COLOR := Color(0.22, 0.58, 0.26)
const SAND_COLOR := Color(0.72, 0.68, 0.52)


func _ready() -> void:
	_build_track()


func get_ai_waypoints() -> Array[Vector2]:
	return MonacoTrackData.get_ai_waypoints()


func _build_track() -> void:
	_clear_generated()

	var edges := MonacoTrackData.build_edges()
	var outer: PackedVector2Array = edges["outer"]
	var inner: PackedVector2Array = edges["inner"]

	_add_terrain()
	_add_harbor()
	_add_scenery()
	_add_trees()
	_add_board_spaces()
	_add_tunnel()
	_add_lane_dividers()
	_add_track_edges(outer, inner)
	_add_kerbs(outer, inner)
	_add_start_line()
	_add_turn_labels()
	_add_outer_walls()
	_add_checkpoints()


func _clear_generated() -> void:
	var to_remove: Array[Node] = []
	for child in get_children():
		if child.name.begins_with("Generated"):
			to_remove.append(child)
	for child in to_remove:
		remove_child(child)
		child.free()


func _add_terrain() -> void:
	var bounds := MonacoTrackData.TRACK_BOUNDS
	var pad := 200.0
	var grass := Polygon2D.new()
	grass.name = "GeneratedGrass"
	grass.color = GRASS_COLOR
	grass.polygon = PackedVector2Array([
		Vector2(bounds.position.x - pad, bounds.position.y - pad),
		Vector2(bounds.end.x + pad, bounds.position.y - pad),
		Vector2(bounds.end.x + pad, bounds.end.y + pad),
		Vector2(bounds.position.x - pad, bounds.end.y + pad),
	])
	grass.z_index = -3
	add_child(grass)

	var coast := Polygon2D.new()
	coast.name = "GeneratedCoast"
	coast.color = SAND_COLOR
	coast.polygon = PackedVector2Array([
		Vector2(1580, 820), Vector2(1800, 820), Vector2(1800, 1080), Vector2(1480, 1080),
	])
	coast.z_index = -2
	add_child(coast)


func _add_harbor() -> void:
	var harbor := Polygon2D.new()
	harbor.name = "GeneratedHarbor"
	harbor.color = WATER_COLOR
	harbor.polygon = PackedVector2Array([
		Vector2(820, 580), Vector2(1620, 580), Vector2(1680, 860), Vector2(760, 860),
	])
	harbor.z_index = -1
	add_child(harbor)

	var deep := Polygon2D.new()
	deep.name = "GeneratedHarborDeep"
	deep.color = WATER_DEEP
	deep.polygon = PackedVector2Array([
		Vector2(1100, 700), Vector2(1580, 700), Vector2(1620, 840), Vector2(1000, 840),
	])
	deep.z_index = -1
	add_child(deep)

	var dock_positions: Array[Vector2] = [
		Vector2(980, 640), Vector2(1120, 660), Vector2(1260, 680),
		Vector2(1400, 700), Vector2(1050, 760), Vector2(1200, 780),
	]
	for i in dock_positions.size():
		_add_boat(dock_positions[i], i)
		_add_dock(dock_positions[i] + Vector2(0, 28), i)


func _add_boat(pos: Vector2, index: int) -> void:
	var hull := Polygon2D.new()
	hull.name = "GeneratedBoat%d" % index
	var w := 28.0 + float(index % 3) * 8.0
	var h := 12.0 + float(index % 2) * 4.0
	hull.polygon = PackedVector2Array([
		Vector2(-w, -h * 0.3), Vector2(w * 0.7, -h), Vector2(w, 0),
		Vector2(w * 0.7, h), Vector2(-w, h * 0.3),
	])
	hull.color = Color(0.94, 0.95, 0.97)
	hull.position = pos
	hull.z_index = 0
	add_child(hull)

	var cabin := Polygon2D.new()
	cabin.polygon = PackedVector2Array([
		Vector2(-4, -6), Vector2(8, -6), Vector2(8, 4), Vector2(-4, 4),
	])
	cabin.color = Color(0.75, 0.78, 0.82)
	cabin.position = pos + Vector2(-6, -2)
	cabin.z_index = 1
	cabin.name = "GeneratedBoatCabin%d" % index
	add_child(cabin)


func _add_dock(pos: Vector2, index: int) -> void:
	var dock := Line2D.new()
	dock.name = "GeneratedDock%d" % index
	dock.points = PackedVector2Array([Vector2(-18, 0), Vector2(18, 0)])
	dock.width = 5.0
	dock.default_color = Color(0.45, 0.38, 0.3)
	dock.position = pos
	dock.z_index = 0
	add_child(dock)


func _add_scenery() -> void:
	var buildings: Array[Dictionary] = [
		{"poly": PackedVector2Array([Vector2(340, 90), Vector2(540, 90), Vector2(540, 240), Vector2(340, 240)]), "fill": Color(0.82, 0.78, 0.72), "roof": Color(0.72, 0.28, 0.2)},
		{"poly": PackedVector2Array([Vector2(680, 70), Vector2(920, 70), Vector2(920, 220), Vector2(680, 220)]), "fill": Color(0.9, 0.88, 0.84), "roof": Color(0.65, 0.22, 0.18)},
		{"poly": PackedVector2Array([Vector2(1160, 110), Vector2(1340, 110), Vector2(1340, 270), Vector2(1160, 270)]), "fill": Color(0.78, 0.8, 0.85), "roof": Color(0.7, 0.25, 0.2)},
		{"poly": PackedVector2Array([Vector2(360, 820), Vector2(560, 820), Vector2(560, 1000), Vector2(360, 1000)]), "fill": Color(0.85, 0.82, 0.76), "roof": Color(0.68, 0.24, 0.18)},
		{"poly": PackedVector2Array([Vector2(60, 480), Vector2(180, 480), Vector2(180, 700), Vector2(60, 700)]), "fill": Color(0.8, 0.83, 0.88), "roof": Color(0.62, 0.2, 0.16)},
		{"poly": PackedVector2Array([Vector2(1480, 120), Vector2(1680, 120), Vector2(1680, 300), Vector2(1480, 300)]), "fill": Color(0.88, 0.85, 0.8), "roof": Color(0.74, 0.26, 0.2)},
	]
	for i in buildings.size():
		var data: Dictionary = buildings[i]
		var poly: PackedVector2Array = data["poly"]
		var building := Polygon2D.new()
		building.name = "GeneratedBuilding%d" % i
		building.polygon = poly
		building.color = data["fill"]
		building.z_index = -1
		add_child(building)

		var roof_top := _polygon_top(poly)
		var roof := Polygon2D.new()
		roof.name = "GeneratedRoof%d" % i
		roof.polygon = PackedVector2Array([
			Vector2(poly[0].x, roof_top), Vector2(poly[1].x, roof_top),
			Vector2(poly[1].x, roof_top + 18), Vector2(poly[0].x, roof_top + 18),
		])
		roof.color = data["roof"]
		roof.z_index = 0
		add_child(roof)


func _polygon_top(poly: PackedVector2Array) -> float:
	var top := poly[0].y
	for p in poly:
		top = minf(top, p.y)
	return top


func _add_trees() -> void:
	var tree_positions: Array[Vector2] = [
		Vector2(300, 280), Vector2(420, 320), Vector2(580, 180), Vector2(750, 150),
		Vector2(1000, 200), Vector2(1250, 320), Vector2(1420, 380), Vector2(280, 600),
		Vector2(150, 380), Vector2(1650, 400), Vector2(500, 900), Vector2(700, 950),
	]
	for i in tree_positions.size():
		var pos := tree_positions[i]
		var trunk := Polygon2D.new()
		trunk.name = "GeneratedTreeTrunk%d" % i
		trunk.polygon = PackedVector2Array([
			Vector2(-3, 0), Vector2(3, 0), Vector2(3, 10), Vector2(-3, 10),
		])
		trunk.color = Color(0.4, 0.28, 0.16)
		trunk.position = pos
		trunk.z_index = 0
		add_child(trunk)

		var crown := Polygon2D.new()
		crown.name = "GeneratedTree%d" % i
		var r := 14.0 + float(i % 4) * 3.0
		crown.polygon = _circle_polygon(r, 10)
		crown.color = Color(0.15, 0.52, 0.2) if i % 2 == 0 else Color(0.18, 0.58, 0.22)
		crown.position = pos + Vector2(0, -8)
		crown.z_index = 1
		add_child(crown)


func _circle_polygon(radius: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in segments:
		var angle := TAU * float(i) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points


func _add_board_spaces() -> void:
	var spaces := MonacoTrackData.build_board_spaces()
	for i in spaces.size():
		var data: Dictionary = spaces[i]
		var space_index: int = data["index"]
		var lane: int = data["lane"]
		var patch := Polygon2D.new()
		patch.name = "GeneratedSpace%d" % i
		patch.polygon = data["polygon"]
		var base := ASPHALT_A if (space_index + lane) % 2 == 0 else ASPHALT_B
		patch.color = base
		patch.z_index = 2
		add_child(patch)


func _add_tunnel() -> void:
	for idx in MonacoTrackData.TUNNEL_SEGMENT_INDICES:
		var poly := MonacoTrackData.build_segment_polygon_at(idx)
		var overlay := Polygon2D.new()
		overlay.name = "GeneratedTunnel%d" % idx
		overlay.polygon = poly
		overlay.color = Color(0.12, 0.08, 0.06, 0.62)
		overlay.z_index = 4
		add_child(overlay)

		var start := MonacoTrackData.CENTERLINE[idx]
		var end := MonacoTrackData.CENTERLINE[(idx + 1) % MonacoTrackData.CENTERLINE.size()]
		var tangent := (end - start).normalized()
		var normal := tangent.orthogonal()
		for light_i in 4:
			var t := float(light_i + 1) / 5.0
			var light_pos := start.lerp(end, t) - normal * (MonacoTrackData.HALF_WIDTH - 12.0)
			var light := Polygon2D.new()
			light.name = "GeneratedTunnelLight%d_%d" % [idx, light_i]
			light.polygon = _circle_polygon(5.0, 8)
			light.color = Color(1.0, 0.55, 0.12, 0.9)
			light.position = light_pos
			light.z_index = 5
			add_child(light)


func _add_lane_dividers() -> void:
	for offset in MonacoTrackData.lane_boundary_offsets():
		var dashes := MonacoTrackData.build_dashed_offset_path(offset, 14.0, 10.0)
		for dash_i in dashes.size():
			var dash := Line2D.new()
			dash.name = "GeneratedLaneDash_%d_%d" % [int(offset), dash_i]
			dash.points = dashes[dash_i]
			dash.width = 2.5
			dash.default_color = LANE_YELLOW
			dash.antialiased = true
			dash.z_index = 3
			add_child(dash)


func _add_track_edges(outer: PackedVector2Array, inner: PackedVector2Array) -> void:
	var outer_line := Line2D.new()
	outer_line.name = "GeneratedOuterEdge"
	outer_line.points = outer
	outer_line.closed = true
	outer_line.width = 2.0
	outer_line.default_color = EDGE_WHITE
	outer_line.joint_mode = Line2D.LINE_JOINT_ROUND
	outer_line.antialiased = true
	outer_line.z_index = 3
	add_child(outer_line)

	var inner_line := Line2D.new()
	inner_line.name = "GeneratedInnerEdge"
	inner_line.points = inner
	inner_line.closed = true
	inner_line.width = 2.0
	inner_line.default_color = EDGE_WHITE
	inner_line.joint_mode = Line2D.LINE_JOINT_ROUND
	inner_line.antialiased = true
	inner_line.z_index = 3
	add_child(inner_line)


func _add_kerbs(outer: PackedVector2Array, inner: PackedVector2Array) -> void:
	var outer_stripes := MonacoTrackData.build_kerb_stripes(outer, 1.0)
	for i in outer_stripes.size():
		var stripe := Polygon2D.new()
		stripe.name = "GeneratedOuterKerb%d" % i
		stripe.polygon = outer_stripes[i]["polygon"]
		stripe.color = outer_stripes[i]["color"]
		stripe.z_index = 3
		add_child(stripe)

	var inner_stripes := MonacoTrackData.build_kerb_stripes(inner, -1.0)
	for i in inner_stripes.size():
		var stripe := Polygon2D.new()
		stripe.name = "GeneratedInnerKerb%d" % i
		stripe.polygon = inner_stripes[i]["polygon"]
		stripe.color = inner_stripes[i]["color"]
		stripe.z_index = 3
		add_child(stripe)


func _add_start_line() -> void:
	var centerline := MonacoTrackData.get_centerline()
	var point := centerline[0]
	var tangent := MonacoTrackData.tangent_at(0)
	var normal := tangent.orthogonal()
	var square_size := 9.0
	var squares_across := int((MonacoTrackData.HALF_WIDTH * 2.0) / square_size)

	for row in 2:
		for col in squares_across:
			var offset := -MonacoTrackData.HALF_WIDTH + square_size * (float(col) + 0.5)
			var along := square_size * (float(row) - 0.5)
			var center := point + normal * offset + tangent * along
			var square := Polygon2D.new()
			square.name = "GeneratedStartSq_%d_%d" % [row, col]
			square.polygon = PackedVector2Array([
				center + tangent * square_size * 0.5 + normal * square_size * 0.5,
				center + tangent * square_size * 0.5 - normal * square_size * 0.5,
				center - tangent * square_size * 0.5 - normal * square_size * 0.5,
				center - tangent * square_size * 0.5 + normal * square_size * 0.5,
			])
			square.color = Color(0.08, 0.08, 0.08) if (row + col) % 2 == 0 else Color(0.96, 0.96, 0.96)
			square.z_index = 5
			add_child(square)


func _add_turn_labels() -> void:
	for data in MonacoTrackData.get_turn_label_positions():
		var container := Node2D.new()
		container.name = "GeneratedTurnLabel_%s" % data["name"]
		container.position = data["position"]
		container.rotation = data["rotation"]
		container.z_index = 6

		var badge := Polygon2D.new()
		badge.polygon = PackedVector2Array([
			Vector2(-52, -14), Vector2(52, -14), Vector2(52, 14), Vector2(-52, 14),
		])
		badge.color = Color(0.72, 0.1, 0.1, 0.88)
		badge.z_index = -1
		container.add_child(badge)

		var label := Label.new()
		label.text = data["name"]
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_color_override("font_outline_color", Color(0.55, 0.05, 0.05))
		label.add_theme_constant_override("outline_size", 4)
		label.position = Vector2(-48, -10)
		container.add_child(label)

		add_child(container)


func _add_outer_walls() -> void:
	var container := StaticBody2D.new()
	container.name = "GeneratedOuterWall"
	container.collision_layer = 1
	container.collision_mask = 0
	add_child(container)

	for segment in MonacoTrackData.build_outer_wall_segments():
		var start := segment[0]
		var end := segment[1]
		var wall_segment := end - start
		var length := wall_segment.length()
		if length < 1.0:
			continue

		var shape := RectangleShape2D.new()
		shape.size = Vector2(length + 2.0, MonacoTrackData.WALL_THICKNESS)

		var wall := CollisionShape2D.new()
		wall.shape = shape
		wall.position = start + wall_segment * 0.5
		wall.rotation = wall_segment.angle()
		container.add_child(wall)


func _add_checkpoints() -> void:
	var container := Node2D.new()
	container.name = "GeneratedCheckpoints"
	add_child(container)

	var checkpoint_scene: PackedScene = load("res://scenes/checkpoint.tscn")
	for data in MonacoTrackData.get_checkpoint_data():
		var checkpoint: Checkpoint = checkpoint_scene.instantiate()
		checkpoint.checkpoint_index = data["index"]
		checkpoint.position = data["position"]
		checkpoint.rotation = data["rotation"] + PI * 0.5
		checkpoint.name = "Checkpoint%d" % data["index"]
		container.add_child(checkpoint)
