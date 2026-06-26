class_name MonacoTrack
extends Node3D

const ASPHALT_A := Color(0.36, 0.37, 0.39)
const ASPHALT_B := Color(0.42, 0.43, 0.45)
const LANE_YELLOW := Color(0.98, 0.86, 0.12)
const EDGE_WHITE := Color(0.95, 0.95, 0.95)
const WATER_COLOR := Color(0.12, 0.48, 0.78)
const WATER_DEEP := Color(0.08, 0.38, 0.68)
const GRASS_COLOR := Color(0.22, 0.58, 0.26)
const SAND_COLOR := Color(0.72, 0.68, 0.52)

const ROAD_HEIGHT := 0.15
const ROAD_Y := ROAD_HEIGHT * 0.5

var _materials: Dictionary = {}


func _ready() -> void:
	_init_materials()
	_build_track()


func get_ai_waypoints() -> Array[Vector3]:
	return MonacoTrackData.get_ai_waypoints()


func _init_materials() -> void:
	_materials["grass"] = _make_material(GRASS_COLOR)
	_materials["sand"] = _make_material(SAND_COLOR)
	_materials["water"] = _make_material(WATER_COLOR, 0.85, 0.2)
	_materials["water_deep"] = _make_material(WATER_DEEP, 0.9, 0.15)
	_materials["asphalt_a"] = _make_material(ASPHALT_A, 1.0, 0.1)
	_materials["asphalt_b"] = _make_material(ASPHALT_B, 1.0, 0.1)
	_materials["white"] = _make_material(EDGE_WHITE)
	_materials["yellow"] = _make_material(LANE_YELLOW)
	_materials["building"] = _make_material(Color(0.82, 0.78, 0.72))
	_materials["roof"] = _make_material(Color(0.72, 0.28, 0.2))
	_materials["tree_trunk"] = _make_material(Color(0.4, 0.28, 0.16))
	_materials["tree_crown"] = _make_material(Color(0.15, 0.52, 0.2))
	_materials["dock"] = _make_material(Color(0.45, 0.38, 0.3))
	_materials["boat"] = _make_material(Color(0.94, 0.95, 0.97))
	_materials["tunnel"] = _make_material(Color(0.12, 0.08, 0.06))
	_materials["wall"] = _make_material(Color(0.55, 0.55, 0.58))


func _make_material(color: Color, metallic: float = 0.0, roughness: float = 0.8) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = roughness
	return mat


func _build_track() -> void:
	_clear_generated()
	_add_terrain()
	_add_harbor()
	_add_scenery()
	_add_trees()
	_add_board_spaces()
	_add_tunnel()
	_add_lane_dividers()
	_add_track_edges()
	_add_kerbs()
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
	var grass_size := Vector2(bounds.size.x + pad * 2.0, bounds.size.y + pad * 2.0)
	var grass := _make_box(
		Vector3(grass_size.x, 0.5, grass_size.y),
		MonacoTrackData.to_vec3(bounds.get_center(), -0.25),
		_materials["grass"],
		"GeneratedGrass"
	)
	add_child(grass)

	var coast := _make_box(
		Vector3(220, 0.3, 260),
		MonacoTrackData.to_vec3(Vector2(1640, 950), -0.1),
		_materials["sand"],
		"GeneratedCoast"
	)
	add_child(coast)


func _add_harbor() -> void:
	var harbor := _make_box(
		Vector3(860, 0.2, 280),
		MonacoTrackData.to_vec3(Vector2(1220, 720), -0.35),
		_materials["water"],
		"GeneratedHarbor"
	)
	add_child(harbor)

	var deep := _make_box(
		Vector3(620, 0.15, 140),
		MonacoTrackData.to_vec3(Vector2(1310, 770), -0.4),
		_materials["water_deep"],
		"GeneratedHarborDeep"
	)
	add_child(deep)

	var dock_positions: Array[Vector2] = [
		Vector2(980, 640), Vector2(1120, 660), Vector2(1260, 680),
		Vector2(1400, 700), Vector2(1050, 760), Vector2(1200, 780),
	]
	for i in dock_positions.size():
		_add_boat(dock_positions[i], i)
		_add_dock(dock_positions[i] + Vector2(0, 28), i)


func _add_boat(pos: Vector2, index: int) -> void:
	var w := 28.0 + float(index % 3) * 8.0
	var h := 12.0 + float(index % 2) * 4.0
	var boat := _make_box(
		Vector3(w * 2.0, 4.0, h * 2.0),
		MonacoTrackData.to_vec3(pos, 0.5),
		_materials["boat"],
		"GeneratedBoat%d" % index
	)
	add_child(boat)


func _add_dock(pos: Vector2, index: int) -> void:
	var dock := _make_box(
		Vector3(36, 1.5, 6),
		MonacoTrackData.to_vec3(pos, 0.2),
		_materials["dock"],
		"GeneratedDock%d" % index
	)
	add_child(dock)


func _add_scenery() -> void:
	var buildings: Array[Dictionary] = [
		{"rect": Rect2(340, 90, 200, 150), "fill": Color(0.82, 0.78, 0.72), "roof": Color(0.72, 0.28, 0.2), "height": 35.0},
		{"rect": Rect2(680, 70, 240, 150), "fill": Color(0.9, 0.88, 0.84), "roof": Color(0.65, 0.22, 0.18), "height": 42.0},
		{"rect": Rect2(1160, 110, 180, 160), "fill": Color(0.78, 0.8, 0.85), "roof": Color(0.7, 0.25, 0.2), "height": 38.0},
		{"rect": Rect2(360, 820, 200, 180), "fill": Color(0.85, 0.82, 0.76), "roof": Color(0.68, 0.24, 0.18), "height": 30.0},
		{"rect": Rect2(60, 480, 120, 220), "fill": Color(0.8, 0.83, 0.88), "roof": Color(0.62, 0.2, 0.16), "height": 45.0},
		{"rect": Rect2(1480, 120, 200, 180), "fill": Color(0.88, 0.85, 0.8), "roof": Color(0.74, 0.26, 0.2), "height": 40.0},
	]
	for i in buildings.size():
		var data: Dictionary = buildings[i]
		var rect: Rect2 = data["rect"]
		var h: float = data["height"]
		var body := _make_box(
			Vector3(rect.size.x, h, rect.size.y),
			MonacoTrackData.to_vec3(rect.get_center(), h * 0.5),
			_make_material(data["fill"]),
			"GeneratedBuilding%d" % i
		)
		add_child(body)

		var roof := _make_box(
			Vector3(rect.size.x + 8, 4, rect.size.y + 8),
			MonacoTrackData.to_vec3(rect.get_center(), h + 2.0),
			_make_material(data["roof"]),
			"GeneratedRoof%d" % i
		)
		add_child(roof)


func _add_trees() -> void:
	var tree_positions: Array[Vector2] = [
		Vector2(300, 280), Vector2(420, 320), Vector2(580, 180), Vector2(750, 150),
		Vector2(1000, 200), Vector2(1250, 320), Vector2(1420, 380), Vector2(280, 600),
		Vector2(150, 380), Vector2(1650, 400), Vector2(500, 900), Vector2(700, 950),
	]
	for i in tree_positions.size():
		var pos := tree_positions[i]
		var trunk := _make_cylinder(1.5, 8.0, MonacoTrackData.to_vec3(pos, 4.0), _materials["tree_trunk"], "GeneratedTreeTrunk%d" % i)
		add_child(trunk)

		var r := 14.0 + float(i % 4) * 3.0
		var crown_color := Color(0.15, 0.52, 0.2) if i % 2 == 0 else Color(0.18, 0.58, 0.22)
		var crown := _make_sphere(r, MonacoTrackData.to_vec3(pos + Vector2(0, -8), 14.0), _make_material(crown_color), "GeneratedTree%d" % i)
		add_child(crown)


func _add_board_spaces() -> void:
	var spaces := MonacoTrackData.build_board_spaces()
	for i in spaces.size():
		var data: Dictionary = spaces[i]
		var space_index: int = data["index"]
		var lane: int = data["lane"]
		var poly: PackedVector2Array = data["polygon"]
		var center := _polygon_center(poly)
		var size := _polygon_size(poly)
		var rot := _polygon_rotation(poly)
		var mat_key := "asphalt_a" if (space_index + lane) % 2 == 0 else "asphalt_b"
		var patch := _make_oriented_box(
			Vector3(size.x, ROAD_HEIGHT, size.y),
			MonacoTrackData.to_vec3(center, ROAD_Y),
			rot,
			_materials[mat_key],
			"GeneratedSpace%d" % i
		)
		add_child(patch)


func _add_tunnel() -> void:
	for idx in MonacoTrackData.TUNNEL_SEGMENT_INDICES:
		var start := MonacoTrackData.CENTERLINE[idx]
		var end := MonacoTrackData.CENTERLINE[(idx + 1) % MonacoTrackData.CENTERLINE.size()]
		var dir := end - start
		var length := dir.length()
		if length < 1.0:
			continue

		var overlay := _make_oriented_box(
			Vector3(MonacoTrackData.HALF_WIDTH * 2.0, ROAD_HEIGHT + 0.05, length),
			MonacoTrackData.to_vec3((start + end) * 0.5, ROAD_Y),
			atan2(dir.x, dir.y),
			_materials["tunnel"],
			"GeneratedTunnel%d" % idx
		)
		add_child(overlay)

		var tangent := dir.normalized()
		var normal := tangent.orthogonal()
		for light_i in 4:
			var t := float(light_i + 1) / 5.0
			var light_pos := start.lerp(end, t) - normal * (MonacoTrackData.HALF_WIDTH - 12.0)
			var light := OmniLight3D.new()
			light.name = "GeneratedTunnelLight%d_%d" % [idx, light_i]
			light.position = MonacoTrackData.to_vec3(light_pos, 6.0)
			light.light_color = Color(1.0, 0.55, 0.12)
			light.light_energy = 1.2
			light.omni_range = 40.0
			add_child(light)


func _add_lane_dividers() -> void:
	for offset in MonacoTrackData.lane_boundary_offsets():
		var dashes := MonacoTrackData.build_dashed_offset_path(offset, 14.0, 10.0)
		for dash_i in dashes.size():
			var dash_points: PackedVector2Array = dashes[dash_i]
			if dash_points.size() < 2:
				continue
			var start := dash_points[0]
			var end := dash_points[1]
			var dir := end - start
			var length := dir.length()
			if length < 0.5:
				continue
			var dash := _make_oriented_box(
				Vector3(2.5, 0.08, length),
				MonacoTrackData.to_vec3((start + end) * 0.5, ROAD_Y + 0.05),
				atan2(dir.x, dir.y),
				_materials["yellow"],
				"GeneratedLaneDash_%d_%d" % [int(offset), dash_i]
			)
			add_child(dash)


func _add_track_edges() -> void:
	var edges := MonacoTrackData.build_edges()
	_add_edge_line(edges["outer"], "GeneratedOuterEdge")
	_add_edge_line(edges["inner"], "GeneratedInnerEdge")


func _add_edge_line(points: PackedVector2Array, node_name: String) -> void:
	for i in points.size():
		var start := points[i]
		var end := points[(i + 1) % points.size()]
		var dir := end - start
		var length := dir.length()
		if length < 1.0:
			continue
		var edge := _make_oriented_box(
			Vector3(2.0, 0.1, length),
			MonacoTrackData.to_vec3((start + end) * 0.5, ROAD_Y + 0.06),
			atan2(dir.x, dir.y),
			_materials["white"],
			"%s_%d" % [node_name, i]
		)
		add_child(edge)


func _add_kerbs() -> void:
	var edges := MonacoTrackData.build_edges()
	_add_kerb_stripes(edges["outer"], 1.0, "Outer")
	_add_kerb_stripes(edges["inner"], -1.0, "Inner")


func _add_kerb_stripes(edge: PackedVector2Array, outward_sign: float, prefix: String) -> void:
	var stripes := MonacoTrackData.build_kerb_stripes(edge, outward_sign)
	for i in stripes.size():
		var poly: PackedVector2Array = stripes[i]["polygon"]
		var color: Color = stripes[i]["color"]
		var center := _polygon_center(poly)
		var size := _polygon_size(poly)
		var rot := _polygon_rotation(poly)
		var stripe := _make_oriented_box(
			Vector3(size.x, 0.12, size.y),
			MonacoTrackData.to_vec3(center, ROAD_Y + 0.04),
			rot,
			_make_material(color),
			"Generated%sKerb%d" % [prefix, i]
		)
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
			var color := Color(0.08, 0.08, 0.08) if (row + col) % 2 == 0 else Color(0.96, 0.96, 0.96)
			var square := _make_oriented_box(
				Vector3(square_size, 0.1, square_size),
				MonacoTrackData.to_vec3(center, ROAD_Y + 0.07),
				atan2(tangent.x, tangent.y),
				_make_material(color),
				"GeneratedStartSq_%d_%d" % [row, col]
			)
			add_child(square)


func _add_turn_labels() -> void:
	for data in MonacoTrackData.get_turn_label_positions():
		var container := Node3D.new()
		container.name = "GeneratedTurnLabel_%s" % data["name"]
		container.position = data["position"]
		container.rotation.y = data["rotation"]

		var badge := _make_box(
			Vector3(104, 6, 28),
			Vector3.ZERO,
			_make_material(Color(0.72, 0.1, 0.1, 0.88)),
			"Badge"
		)
		container.add_child(badge)

		var label := Label3D.new()
		label.text = data["name"]
		label.font_size = 48
		label.modulate = Color.WHITE
		label.outline_modulate = Color(0.55, 0.05, 0.05)
		label.outline_size = 8
		label.position = Vector3(-48, 4, 0)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		container.add_child(label)

		add_child(container)


func _add_outer_walls() -> void:
	var container := StaticBody3D.new()
	container.name = "GeneratedOuterWall"
	container.collision_layer = 1
	container.collision_mask = 0
	add_child(container)

	for segment in MonacoTrackData.build_outer_wall_segments():
		var start := segment[0]
		var end := segment[1]
		var dir := end - start
		var length := dir.length()
		if length < 1.0:
			continue

		var shape := BoxShape3D.new()
		shape.size = Vector3(length + 2.0, 8.0, MonacoTrackData.WALL_THICKNESS)

		var wall := CollisionShape3D.new()
		wall.shape = shape
		wall.position = MonacoTrackData.to_vec3((start + end) * 0.5, 4.0)
		wall.rotation.y = atan2(dir.x, dir.y)
		container.add_child(wall)

		var visual := _make_oriented_box(
			Vector3(length + 2.0, 8.0, MonacoTrackData.WALL_THICKNESS),
			MonacoTrackData.to_vec3((start + end) * 0.5, 4.0),
			atan2(dir.x, dir.y),
			_materials["wall"],
			"WallVisual"
		)
		container.add_child(visual)


func _add_checkpoints() -> void:
	var container := Node3D.new()
	container.name = "GeneratedCheckpoints"
	add_child(container)

	var checkpoint_scene: PackedScene = load("res://scenes/checkpoint.tscn")
	for data in MonacoTrackData.get_checkpoint_data():
		var checkpoint: Checkpoint = checkpoint_scene.instantiate()
		checkpoint.checkpoint_index = data["index"]
		checkpoint.position = data["position"]
		checkpoint.rotation.y = data["rotation"] + PI * 0.5
		checkpoint.name = "Checkpoint%d" % data["index"]
		container.add_child(checkpoint)


func _make_box(size: Vector3, pos: Vector3, material: StandardMaterial3D, node_name: String) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.position = pos
	mesh_instance.material_override = material
	return mesh_instance


func _make_oriented_box(size: Vector3, pos: Vector3, rot_y: float, material: StandardMaterial3D, node_name: String) -> MeshInstance3D:
	var mesh_instance := _make_box(size, pos, material, node_name)
	mesh_instance.rotation.y = rot_y
	return mesh_instance


func _make_cylinder(radius: float, height: float, pos: Vector3, material: StandardMaterial3D, node_name: String) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = height
	mesh_instance.mesh = cylinder
	mesh_instance.position = pos
	mesh_instance.material_override = material
	return mesh_instance


func _make_sphere(radius: float, pos: Vector3, material: StandardMaterial3D, node_name: String) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	mesh_instance.mesh = sphere
	mesh_instance.position = pos
	mesh_instance.material_override = material
	return mesh_instance


func _polygon_center(poly: PackedVector2Array) -> Vector2:
	var sum := Vector2.ZERO
	for p in poly:
		sum += p
	return sum / float(poly.size())


func _polygon_size(poly: PackedVector2Array) -> Vector2:
	if poly.size() < 2:
		return Vector2.ONE
	var edge_a := poly[1] - poly[0]
	var edge_b := poly[2] - poly[1] if poly.size() > 2 else edge_a.orthogonal()
	return Vector2(edge_a.length(), edge_b.length())


func _polygon_rotation(poly: PackedVector2Array) -> float:
	if poly.size() < 2:
		return 0.0
	var edge := poly[1] - poly[0]
	return atan2(edge.x, edge.y)
