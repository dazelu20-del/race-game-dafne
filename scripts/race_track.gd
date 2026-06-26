class_name RaceTrack
extends Node3D

signal collision_ready

const ROAD_MESH_KEYWORDS: Array[String] = [
	"road", "bridge", "starting", "finish", "crooked", "springboard",
	"track", "plane", "floor", "ground", "asphalt", "path", "pit",
]

const DECOR_MESH_KEYWORDS: Array[String] = [
	"grass", "tree", "flag", "light", "billboard", "banner", "barrier",
	"grand", "stand", "pits", "overhead", "fence", "tent", "camera",
]


func _ready() -> void:
	_build_track()


func get_ai_waypoints() -> Array[Vector3]:
	return RaceTrackData.get_ai_waypoints()


func _build_track() -> void:
	_clear_generated()
	_add_kenney_track()
	_add_checkpoints()


func _clear_generated() -> void:
	var to_remove: Array[Node] = []
	for child in get_children():
		if child.name.begins_with("Generated"):
			to_remove.append(child)
	for child in to_remove:
		remove_child(child)
		child.free()


func _add_kenney_track() -> void:
	var track_root := Node3D.new()
	track_root.name = "GeneratedTrackModel"
	track_root.scale = Vector3(KenneyTrackLayout.TILE_SIZE, 1.0, KenneyTrackLayout.TILE_SIZE)
	add_child(track_root)

	for placement in KenneyTrackLayout.get_road_placements():
		_spawn_piece(track_root, placement, true)
	for placement in KenneyTrackLayout.get_decor_placements():
		_spawn_piece(track_root, placement, false)

	call_deferred("_add_track_collision", track_root)


func _spawn_piece(parent: Node3D, placement: Dictionary, drivable: bool) -> void:
	var mesh_name: String = placement["mesh"]
	var path := KenneyTrackLayout.model_path(mesh_name)
	var piece_scene: PackedScene = load(path)
	if piece_scene == null:
		push_warning("RaceTrack: failed to load Kenney piece %s" % path)
		return

	var piece := piece_scene.instantiate()
	piece.name = "%s_%d_%d" % [mesh_name, placement["grid"].x, placement["grid"].y]
	piece.transform = KenneyTrackLayout.piece_transform(placement["grid"], placement["rot"])
	if drivable:
		piece.add_to_group("kenney_road_piece")
	parent.add_child(piece)


func _add_track_collision(track_root: Node3D) -> void:
	var static_body := StaticBody3D.new()
	static_body.name = "GeneratedTrackCollision"
	static_body.collision_layer = 1
	static_body.collision_mask = 0
	static_body.add_to_group("track_static")
	track_root.add_child(static_body)

	var shape_count := 0
	for mesh_instance in track_root.find_children("*", "MeshInstance3D", true, false):
		if _is_decor_mesh(mesh_instance):
			continue
		if not _is_road_piece_mesh(mesh_instance):
			continue
		if not _is_collision_worthy(mesh_instance as MeshInstance3D, track_root):
			continue
		_add_trimesh_collision(track_root, static_body, mesh_instance as MeshInstance3D)
		shape_count += 1

	if shape_count == 0:
		push_warning("RaceTrack: no road meshes matched; using all non-decor track meshes for collision")
		for mesh_instance in track_root.find_children("*", "MeshInstance3D", true, false):
			if _is_decor_mesh(mesh_instance):
				continue
			if not _is_collision_worthy(mesh_instance as MeshInstance3D, track_root):
				continue
			_add_trimesh_collision(track_root, static_body, mesh_instance as MeshInstance3D)

	collision_ready.emit()


func _is_road_piece_mesh(node: Node) -> bool:
	var current := node
	while current != null:
		if current.is_in_group("kenney_road_piece"):
			return true
		if current.name.begins_with("Generated"):
			break
		current = current.get_parent()
	return _is_drivable_mesh(node)


func _is_decor_mesh(node: Node) -> bool:
	var mesh_instance := node as MeshInstance3D
	if mesh_instance == null:
		return false
	var label := "%s %s" % [node.get_parent().name if node.get_parent() else "", node.name]
	label = label.to_lower()
	for keyword in DECOR_MESH_KEYWORDS:
		if keyword in label:
			return true
	return false


func _is_drivable_mesh(node: Node) -> bool:
	var mesh_instance := node as MeshInstance3D
	if mesh_instance == null or mesh_instance.mesh == null:
		return false

	var label := "%s %s" % [node.get_parent().name if node.get_parent() else "", node.name]
	label = label.to_lower()
	for keyword in ROAD_MESH_KEYWORDS:
		if keyword in label:
			return true
	return false


func _is_collision_worthy(mesh_instance: MeshInstance3D, track_root: Node3D) -> bool:
	if mesh_instance.mesh == null:
		return false
	var mesh_aabb := mesh_instance.mesh.get_aabb()
	var scale := track_root.scale * mesh_instance.scale
	var size := Vector3(
		mesh_aabb.size.x * scale.x,
		mesh_aabb.size.y * scale.y,
		mesh_aabb.size.z * scale.z
	)
	var footprint := maxf(size.x, size.z)
	if footprint < 1.5:
		return false
	if size.y < 0.15 and footprint < 4.0:
		return false
	return true


func _add_trimesh_collision(track_root: Node3D, static_body: StaticBody3D, mesh_instance: MeshInstance3D) -> void:
	var shape := mesh_instance.mesh.create_trimesh_shape()
	if shape == null:
		return

	var collision := CollisionShape3D.new()
	collision.name = "Collision_%s" % mesh_instance.name
	collision.shape = shape
	collision.transform = _path_from_ancestor(static_body, track_root).affine_inverse() * _path_from_ancestor(mesh_instance, track_root)
	static_body.add_child(collision)


func _path_from_ancestor(node: Node3D, ancestor: Node3D) -> Transform3D:
	if node == ancestor:
		return Transform3D.IDENTITY
	var parent := node.get_parent() as Node3D
	return _path_from_ancestor(parent, ancestor) * node.transform


func _add_checkpoints() -> void:
	var container := Node3D.new()
	container.name = "GeneratedCheckpoints"
	add_child(container)

	var checkpoint_scene: PackedScene = load("res://scenes/checkpoint.tscn")
	for data in RaceTrackData.get_checkpoint_data():
		var checkpoint: Checkpoint = checkpoint_scene.instantiate()
		checkpoint.checkpoint_index = data["index"]
		checkpoint.position = data["position"]
		checkpoint.rotation.y = data["rotation"] + PI * 0.5
		checkpoint.name = "Checkpoint%d" % data["index"]
		container.add_child(checkpoint)
