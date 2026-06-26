class_name ChaseCameraRig
extends Node3D

## Rear-top chase camera parented to the car controller (integration checklist: pivot on controller).

@onready var camera: Camera3D = $Camera3D

const CHASE_HEIGHT := 5.0
const CHASE_DISTANCE_BEHIND := 8.0
const LOOK_AHEAD_DISTANCE := 24.0
const INTRO_HEIGHT := 28.0
const INTRO_DISTANCE := 38.0
const COLLISION_MASK := 1

var chase_enabled := false
var intro_enabled := true
var _intro_look_at := Vector3.ZERO


func _ready() -> void:
	camera.make_current()
	_intro_look_at = RaceTrackData.TRACK_CENTER
	_snap_intro()


func set_intro_mode(enabled: bool) -> void:
	intro_enabled = enabled
	if enabled:
		_snap_intro()


func set_chase_mode(enabled: bool) -> void:
	chase_enabled = enabled
	intro_enabled = not enabled
	if enabled:
		_snap_chase()


func _process(delta: float) -> void:
	if intro_enabled:
		_update_intro(delta)
	elif chase_enabled:
		_update_chase(delta)


func _update_intro(delta: float) -> void:
	var intro_offset := Vector3(-INTRO_DISTANCE * 0.6, INTRO_HEIGHT, INTRO_DISTANCE)
	var intro_pos := _intro_look_at + intro_offset
	camera.global_position = camera.global_position.lerp(intro_pos, delta * 3.0)
	camera.look_at(_intro_look_at, Vector3.UP)


func _update_chase(delta: float) -> void:
	var car := get_parent() as RaceCar
	if car == null:
		return

	var forward := car.get_forward()
	var car_pos := car.global_position
	var speed_ratio := clampf(car.get_speed() / _car_max_speed(car), 0.0, 1.0)

	var height := CHASE_HEIGHT + speed_ratio * 2.5
	var distance_behind := CHASE_DISTANCE_BEHIND + speed_ratio * 4.0
	var look_ahead := LOOK_AHEAD_DISTANCE + speed_ratio * 10.0

	var desired_pos := car_pos - forward * distance_behind + Vector3(0, height, 0)
	var look_target := car_pos + forward * look_ahead + Vector3(0, 1.2, 0)
	var safe_pos := _resolve_camera_collision(car_pos + Vector3(0, 2.0, 0), desired_pos)

	camera.global_position = camera.global_position.lerp(safe_pos, delta * 10.0)
	camera.look_at(look_target, Vector3.UP)


func _resolve_camera_collision(from: Vector3, to: Vector3) -> Vector3:
	var space_state := get_world_3d().direct_space_state
	if space_state == null:
		return to

	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = COLLISION_MASK
	var hit := space_state.intersect_ray(query)
	if hit.is_empty():
		return to
	return (hit.position as Vector3) + (hit.normal as Vector3) * 0.35


func _snap_intro() -> void:
	var intro_offset := Vector3(-INTRO_DISTANCE * 0.6, INTRO_HEIGHT, INTRO_DISTANCE)
	camera.global_position = _intro_look_at + intro_offset
	camera.look_at(_intro_look_at, Vector3.UP)


func _snap_chase() -> void:
	var car := get_parent() as RaceCar
	if car == null:
		return
	var forward := car.get_forward()
	var car_pos := car.global_position
	var desired_pos := car_pos - forward * CHASE_DISTANCE_BEHIND + Vector3(0, CHASE_HEIGHT, 0)
	var look_target := car_pos + forward * LOOK_AHEAD_DISTANCE + Vector3(0, 1.2, 0)
	camera.global_position = _resolve_camera_collision(car_pos + Vector3(0, 2.0, 0), desired_pos)
	camera.look_at(look_target, Vector3.UP)


func _car_max_speed(car: RaceCar) -> float:
	if car is PlayerCar:
		return (car as PlayerCar).max_speed
	if car is AICar:
		return (car as AICar).max_speed
	return 360.0
