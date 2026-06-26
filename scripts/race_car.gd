class_name RaceCar
extends CharacterBody3D

## Reference car used to normalize all GLB model scales.
const RED_BULL_MODEL_SIZE := Vector3(255.011, 64.106, 94.556)
const RED_BULL_MODEL_SCALE := 0.022
const MERCEDES_MODEL_SIZE := Vector3(30.888, 17.232, 26.624)

## Target rendered length for all car models (matches capsule ~5 m).
const TARGET_CAR_LENGTH := 5.0

const GROUND_RAY_HEIGHT := GroundProbe.RAY_HEIGHT
const GROUND_RAY_DEPTH := GroundProbe.RAY_DEPTH

@export var ground_clearance := 0.2

var current_lap := 0
var next_checkpoint := 0
var race_finished := false
var can_drive := false


func pass_checkpoint(index: int, total_checkpoints: int) -> void:
	if index != next_checkpoint:
		return

	next_checkpoint = (index + 1) % total_checkpoints
	if next_checkpoint == 0:
		current_lap += 1
		_on_lap_completed(current_lap)


func _on_lap_completed(_lap_number: int) -> void:
	pass


func get_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()


func get_forward() -> Vector3:
	return Vector3(cos(rotation.y), 0.0, sin(rotation.y))


static func get_red_bull_rendered_size() -> Vector3:
	return RED_BULL_MODEL_SIZE * RED_BULL_MODEL_SCALE


static func scale_model_to_red_bull(model_size: Vector3) -> float:
	return scale_model_to_gameplay(model_size)


static func scale_model_to_gameplay(model_size: Vector3) -> float:
	var length := maxf(model_size.x, model_size.z)
	if length < 0.001:
		return RED_BULL_MODEL_SCALE
	return TARGET_CAR_LENGTH / length


func snap_to_ground() -> void:
	var world := get_world_3d()
	if world == null:
		return

	var hit := GroundProbe.cast_ground(world, global_position, [get_rid()])
	if hit.is_empty():
		return

	global_position.y = GroundProbe.snap_height(global_position.y, hit, ground_clearance)


func get_ground_gap() -> float:
	var world := get_world_3d()
	if world == null:
		return INF
	return GroundProbe.foot_gap(world, global_position, [get_rid()])


func snap_to_ground_when_ready(max_attempts := 12) -> void:
	for i in max_attempts:
		snap_to_ground()
		if get_ground_gap() < 0.5:
			return
		await get_tree().process_frame


func reset_race(start_position: Vector3, start_rotation: float) -> void:
	var world := get_world_3d()
	if world != null:
		global_position = GroundProbe.find_ground_position(world, start_position, ground_clearance, [get_rid()])
	else:
		global_position = start_position
	rotation.y = start_rotation
	velocity = Vector3.ZERO
	current_lap = 0
	next_checkpoint = 0
	race_finished = false
	can_drive = false
	call_deferred("snap_to_ground")
