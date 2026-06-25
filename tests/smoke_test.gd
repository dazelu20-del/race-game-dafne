extends SceneTree

## Headless integration smoke test (see references/integration-checklist.md).
const MAIN_SCENE := "res://scenes/main.tscn"
const FRAMES_TO_RUN := 180
const MAX_GROUND_GAP := 0.6


func _initialize() -> void:
	print("=== Race Game Integration Smoke Test ===")
	var errors: Array[String] = []

	var main_scene: PackedScene = load(MAIN_SCENE)
	if main_scene == null:
		errors.append("Failed to load main scene")
		_finish(errors)
		return

	var main := main_scene.instantiate()
	if main == null:
		errors.append("Failed to instantiate main scene")
		_finish(errors)
		return

	root.add_child(main)
	await process_frame
	await process_frame

	var player: PlayerCar = main.get_node_or_null("%Player")
	if player == null:
		errors.append("Player node missing")
	elif not player.has_node("VisualRoot"):
		errors.append("Player missing VisualRoot")
	elif main.get_node_or_null("%CameraRig") == null:
		errors.append("Player missing CameraRig on controller root")

	var track: RaceTrack = main.get_node_or_null("%Track")
	if track == null:
		errors.append("Track node missing")
	elif track.get_ai_waypoints().is_empty():
		errors.append("Track has no AI waypoints")

	for i in FRAMES_TO_RUN:
		await process_frame

	var track_collision := main.find_child("GeneratedTrackCollision", true, false)
	if track_collision == null:
		errors.append("Track collision never generated")
	else:
		var shapes := track_collision.get_children().filter(func(c): return c is CollisionShape3D)
		print("Track collision shapes: ", shapes.size())
		if shapes.is_empty():
			errors.append("Track collision has no shapes")
		if not track_collision.is_in_group("track_static"):
			errors.append("Track collision not in track_static group")

	if player != null:
		var gap := player.get_ground_gap()
		print("Player ground gap: ", gap)
		print("Player position: ", player.global_position)
		if gap > MAX_GROUND_GAP:
			errors.append("Player floating above ground (gap=%.2f)" % gap)
		if not RaceTrackData.is_on_track_3d(player.global_position):
			errors.append("Player spawn is off track centerline")

	_finish(errors)


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("RESULT: PASS")
	else:
		print("RESULT: FAIL")
		for err in errors:
			push_error(err)
	quit(1 if not errors.is_empty() else 0)
