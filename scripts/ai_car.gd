class_name AICar
extends RaceCar

@export var max_speed := 360.0
@export var acceleration := 700.0
@export var turn_speed := 2.6
@export var color := Color.CRIMSON
@export var waypoint_tolerance := 40.0

var _velocity_vec := Vector2.ZERO
var _waypoints: Array[Vector2] = []
var _waypoint_index := 0

@onready var sprite: Polygon2D = $Sprite


func _ready() -> void:
	sprite.color = color
	sprite.scale = Vector2(1.4, 1.4)
	z_index = 10


func set_waypoints(points: Array[Vector2]) -> void:
	_waypoints = points
	_waypoint_index = 0


func _physics_process(delta: float) -> void:
	if race_finished or not can_drive or _waypoints.is_empty():
		_velocity_vec = _velocity_vec.move_toward(Vector2.ZERO, 800.0 * delta)
		velocity = _velocity_vec
		move_and_slide()
		return

	var target := _waypoints[_waypoint_index]
	var to_target := target - global_position

	if to_target.length() < waypoint_tolerance:
		_waypoint_index = (_waypoint_index + 1) % _waypoints.size()
		target = _waypoints[_waypoint_index]
		to_target = target - global_position

	var desired_dir := to_target.normalized()
	var angle_diff := wrapf(desired_dir.angle() - rotation, -PI, PI)
	var corner_scale := clampf(1.0 - absf(angle_diff) / PI, 0.5, 1.0)
	rotation += clampf(angle_diff, -turn_speed * delta, turn_speed * delta) * 1.2

	var forward := Vector2.RIGHT.rotated(rotation)
	var target_speed := max_speed * corner_scale
	_velocity_vec = _velocity_vec.move_toward(forward * target_speed, acceleration * delta)
	_velocity_vec = _velocity_vec.limit_length(target_speed)

	velocity = _velocity_vec
	move_and_slide()
	if get_slide_collision_count() > 0:
		_velocity_vec = velocity


func reset_race(start_position: Vector2, start_rotation: float) -> void:
	super.reset_race(start_position, start_rotation)
	_velocity_vec = Vector2.ZERO
	_waypoint_index = 0
