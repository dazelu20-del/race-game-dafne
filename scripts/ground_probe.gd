extends RefCounted
class_name GroundProbe

## Grounding helpers aligned with integration-checklist.md step limits.

const RAY_HEIGHT := 6.0
const RAY_DEPTH := 16.0
const MAX_SLOPE := deg_to_rad(58.0)
const MAX_STEP_UP := 1.25
const MAX_STEP_DOWN := 4.0
const COLLISION_MASK := 1


static func cast_ground(
	world: World3D,
	origin: Vector3,
	exclude: Array[RID] = []
) -> Dictionary:
	var space_state := world.direct_space_state
	if space_state == null:
		return {}

	var from := origin + Vector3(0, RAY_HEIGHT, 0)
	var to := origin - Vector3(0, RAY_DEPTH, 0)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = COLLISION_MASK
	query.exclude = exclude

	var hit := space_state.intersect_ray(query)
	if hit.is_empty():
		return {}

	if hit.normal.dot(Vector3.UP) < cos(MAX_SLOPE):
		return {}

	return hit


static func snap_height(
	current_y: float,
	hit: Dictionary,
	clearance: float
) -> float:
	if hit.is_empty():
		return current_y

	var target_y := (hit.position as Vector3).y + clearance
	var delta_y := target_y - current_y
	if delta_y > MAX_STEP_UP or delta_y < -MAX_STEP_DOWN:
		return current_y
	return target_y


static func foot_gap(world: World3D, origin: Vector3, exclude: Array[RID] = []) -> float:
	var hit := cast_ground(world, origin, exclude)
	if hit.is_empty():
		return INF
	return origin.y - ((hit.position as Vector3).y)


static func find_ground_position(
	world: World3D,
	xz: Vector3,
	clearance: float,
	exclude: Array[RID] = []
) -> Vector3:
	var probe := Vector3(xz.x, RaceTrackData.CAR_Y + 4.0, xz.z)
	var hit := cast_ground(world, probe, exclude)
	if hit.is_empty():
		return Vector3(xz.x, RaceTrackData.CAR_Y, xz.z)
	return Vector3(xz.x, (hit.position as Vector3).y + clearance, xz.z)
