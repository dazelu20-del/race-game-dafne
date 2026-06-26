extends SceneTree

const GAP_TOLERANCE := 0.6


func _initialize() -> void:
	var track_root := Node3D.new()
	track_root.scale = Vector3(10, 1, 10)
	get_root().add_child(track_root)
	await process_frame

	var pieces: Array[Dictionary] = []
	for placement in KenneyTrackLayout.get_road_placements():
		var piece: Node3D = load(KenneyTrackLayout.model_path(placement["mesh"])).instantiate()
		piece.transform = KenneyTrackLayout.piece_transform(placement["grid"], placement["rot"])
		track_root.add_child(piece)
		await process_frame
		pieces.append({
			"mesh": placement["mesh"],
			"grid": placement["grid"],
			"aabb": _mesh_aabb(piece),
		})

	var errors: Array[String] = []
	for i in range(pieces.size()):
		var a: Dictionary = pieces[i]
		var b: Dictionary = pieces[(i + 1) % pieces.size()]
		var gap := _connection_gap(a["aabb"], b["aabb"])
		if gap.x > GAP_TOLERANCE or gap.y > GAP_TOLERANCE:
			errors.append("%s@%s -> %s@%s gap=(%.2f, %.2f)" % [
				a["mesh"], a["grid"], b["mesh"], b["grid"], gap.x, gap.y
			])

	if errors.is_empty():
		print("TRACK VALIDATION: PASS (%d pieces)" % pieces.size())
	else:
		print("TRACK VALIDATION: FAIL")
		for err in errors:
			push_error(err)
	quit(1 if not errors.is_empty() else 0)


func _connection_gap(a: AABB, b: AABB) -> Vector2:
	var gap_x := maxf(0.0, maxf(b.position.x - (a.position.x + a.size.x), a.position.x - (b.position.x + b.size.x)))
	var gap_z := maxf(0.0, maxf(b.position.z - (a.position.z + a.size.z), a.position.z - (b.position.z + b.size.z)))
	var overlap_x := minf(a.position.x + a.size.x, b.position.x + b.size.x) - maxf(a.position.x, b.position.x)
	var overlap_z := minf(a.position.z + a.size.z, b.position.z + b.size.z) - maxf(a.position.z, b.position.z)
	if overlap_x > GAP_TOLERANCE and gap_z > GAP_TOLERANCE:
		gap_z = gap_z
	else:
		gap_z = 0.0
	if overlap_z > GAP_TOLERANCE and gap_x > GAP_TOLERANCE:
		gap_x = gap_x
	else:
		gap_x = 0.0
	return Vector2(gap_x, gap_z)


func _mesh_aabb(node: Node3D) -> AABB:
	var combined := AABB()
	var first := true
	for mesh in node.find_children("*", "MeshInstance3D", true, false):
		var mi := mesh as MeshInstance3D
		if mi.mesh == null:
			continue
		var g := mi.global_transform * mi.mesh.get_aabb()
		combined = g if first else combined.merge(g)
		first = false
	return combined
