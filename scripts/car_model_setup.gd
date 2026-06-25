extends RefCounted
class_name CarModelSetup

## Presets derived from IntegrationAssets (scale computed from mesh bounds at runtime).
const PRESETS: Dictionary = IntegrationAssets.CARS


static func attach_model(visual_root: Node3D, model_path: String) -> Node3D:
	if model_path.is_empty():
		return null

	var model_scene: PackedScene = load(model_path)
	if model_scene == null:
		push_warning("CarModelSetup: failed to load %s" % model_path)
		return null

	var model := model_scene.instantiate()
	model.name = "CarModel"

	var preset: Dictionary = PRESETS.get(model_path, {})
	var rotation: Vector3 = preset.get("forward_fix_degrees", Vector3(0, 90, 0))
	model.rotation_degrees = rotation

	var bounds := _combined_mesh_aabb(model)
	var length := maxf(bounds.size.x, bounds.size.z)
	var scale := RaceCar.scale_model_to_gameplay(Vector3(length, bounds.size.y, length))
	model.scale = Vector3.ONE * scale

	visual_root.add_child(model)
	_align_bottom_to_origin(model)

	var extra_offset: Vector3 = preset.get("extra_offset", Vector3.ZERO)
	model.position += extra_offset

	return model


static func _align_bottom_to_origin(model: Node3D) -> void:
	var bounds := _combined_mesh_aabb(model)
	if bounds.size == Vector3.ZERO:
		return
	model.position.y -= bounds.position.y


static func _combined_mesh_aabb(root: Node3D) -> AABB:
	var combined := AABB()
	var has_bounds := false
	var root_scale := root.scale
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		var mesh_aabb := mesh_instance.mesh.get_aabb()
		var scaled_origin := Vector3(
			mesh_instance.transform.origin.x * root_scale.x,
			mesh_instance.transform.origin.y * root_scale.y,
			mesh_instance.transform.origin.z * root_scale.z
		)
		var scaled_basis := mesh_instance.transform.basis * Basis.from_scale(root_scale)
		var local := Transform3D(scaled_basis, scaled_origin) * mesh_aabb
		if not has_bounds:
			combined = local
			has_bounds = true
		else:
			combined = combined.merge(local)
	return combined


static func hide_placeholder_meshes(visual_root: Node3D) -> void:
	for child in visual_root.get_children():
		if child is MeshInstance3D:
			child.visible = false
