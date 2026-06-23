class_name PlayerCar
extends RaceCar

signal lap_completed(lap_number: int)

@export var max_speed := 380.0
@export var acceleration := 850.0
@export var brake_force := 1300.0
@export var turn_speed := 3.6
@export var drift_factor := 0.92
@export var color := Color(0.35, 0.65, 1.0)

var _velocity_vec := Vector2.ZERO

@onready var sprite: Polygon2D = $Sprite
@onready var collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	sprite.color = color
	sprite.scale = Vector2(1.4, 1.4)
	collision.disabled = false
	z_index = 10


func _physics_process(delta: float) -> void:
	if race_finished or not can_drive:
		_velocity_vec = _velocity_vec.move_toward(Vector2.ZERO, brake_force * delta)
		velocity = _velocity_vec
		move_and_slide()
		return

	var throttle := Input.get_action_strength("accelerate") - Input.get_action_strength("brake")
	var steer := Input.get_action_strength("turn_right") - Input.get_action_strength("turn_left")
	var on_track := MonacoTrackData.is_on_track(global_position)
	var grip := 1.0 if on_track else 0.55
	var speed_cap := max_speed if on_track else max_speed * 0.65

	if absf(steer) > 0.01 and _velocity_vec.length() > 30.0:
		var turn_amount := steer * turn_speed * delta * grip
		var speed_ratio := clampf(_velocity_vec.length() / max_speed, 0.3, 1.0)
		rotation += turn_amount * speed_ratio

	var forward := Vector2.RIGHT.rotated(rotation)
	var target_speed := throttle * speed_cap

	if throttle > 0.0:
		_velocity_vec = _velocity_vec.move_toward(forward * target_speed, acceleration * grip * delta)
	elif throttle < 0.0:
		_velocity_vec = _velocity_vec.move_toward(Vector2.ZERO, brake_force * delta)
	else:
		var coast_drag := brake_force * (0.35 if on_track else 0.8)
		_velocity_vec = _velocity_vec.move_toward(Vector2.ZERO, coast_drag * delta)

	if absf(steer) > 0.01 and _velocity_vec.length() > 80.0:
		var lateral := forward.orthogonal() * forward.orthogonal().dot(_velocity_vec)
		_velocity_vec -= lateral * (1.0 - drift_factor) * grip

	_velocity_vec = _velocity_vec.limit_length(speed_cap)
	velocity = _velocity_vec
	move_and_slide()
	if get_slide_collision_count() > 0:
		_velocity_vec = velocity


func pass_checkpoint(index: int, total_checkpoints: int) -> void:
	super.pass_checkpoint(index, total_checkpoints)


func _on_lap_completed(lap_number: int) -> void:
	lap_completed.emit(lap_number)


func is_on_track() -> bool:
	return MonacoTrackData.is_on_track(global_position)


func get_speed() -> float:
	return _velocity_vec.length()


func reset_race(start_position: Vector2, start_rotation: float) -> void:
	super.reset_race(start_position, start_rotation)
	_velocity_vec = Vector2.ZERO
