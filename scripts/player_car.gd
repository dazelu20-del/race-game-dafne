class_name PlayerCar
extends RaceCar

signal lap_completed(lap_number: int)

@export var max_speed := 380.0
@export var acceleration := 850.0
@export var brake_force := 1300.0
@export var turn_speed := 3.6
@export var drift_factor := 0.92
@export var color := Color(0.35, 0.65, 1.0)
@export_file("*.glb") var car_model_path: String = "res://assets/cars/f1_mercedes_w13_concept.glb"

var _velocity_vec := Vector3.ZERO

@onready var visual_root: Node3D = $VisualRoot
@onready var collision: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	floor_snap_length = 0.4
	floor_max_angle = deg_to_rad(50.0)
	safe_margin = 0.08

	if car_model_path.is_empty():
		_apply_placeholder_color(color)
	else:
		_setup_imported_model()
	collision.disabled = false


func _setup_imported_model() -> void:
	CarModelSetup.hide_placeholder_meshes(visual_root)
	var model := CarModelSetup.attach_model(visual_root, car_model_path)
	if model == null:
		_apply_placeholder_color(color)
		for child in visual_root.get_children():
			if child is MeshInstance3D:
				child.visible = true


func _apply_placeholder_color(car_color: Color) -> void:
	for child in visual_root.get_children():
		if child is MeshInstance3D:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = car_color
			child.material_override = mat


func _physics_process(delta: float) -> void:
	if race_finished or not can_drive:
		_velocity_vec = _velocity_vec.move_toward(Vector3.ZERO, brake_force * delta)
		velocity = _velocity_vec
		move_and_slide()
		snap_to_ground()
		return

	var throttle := Input.get_action_strength("accelerate") - Input.get_action_strength("brake")
	var steer := Input.get_action_strength("turn_right") - Input.get_action_strength("turn_left")
	var on_track := RaceTrackData.is_on_track_3d(global_position)
	var grip := 1.0 if on_track else 0.75
	var speed_cap := max_speed if on_track else max_speed * 0.8

	if absf(steer) > 0.01:
		var speed := maxf(_velocity_vec.length(), 8.0)
		var turn_amount := steer * turn_speed * delta * grip
		var speed_ratio := clampf(speed / max_speed, 0.35, 1.0)
		rotation.y += turn_amount * speed_ratio

	var forward := get_forward()
	var target_speed := throttle * speed_cap

	if throttle > 0.0:
		_velocity_vec = _velocity_vec.move_toward(forward * target_speed, acceleration * grip * delta)
	elif throttle < 0.0:
		_velocity_vec = _velocity_vec.move_toward(Vector3.ZERO, brake_force * delta)
	else:
		var coast_drag := brake_force * (0.35 if on_track else 0.8)
		_velocity_vec = _velocity_vec.move_toward(Vector3.ZERO, coast_drag * delta)

	if absf(steer) > 0.01 and _velocity_vec.length() > 80.0:
		var right := forward.cross(Vector3.UP)
		var lateral := right * right.dot(_velocity_vec)
		_velocity_vec -= lateral * (1.0 - drift_factor) * grip

	_velocity_vec.y = 0.0
	_velocity_vec = _velocity_vec.limit_length(speed_cap)
	velocity = _velocity_vec
	move_and_slide()
	snap_to_ground()

	if get_slide_collision_count() > 0:
		_velocity_vec = velocity
		_velocity_vec.y = 0.0


func pass_checkpoint(index: int, total_checkpoints: int) -> void:
	super.pass_checkpoint(index, total_checkpoints)


func _on_lap_completed(lap_number: int) -> void:
	lap_completed.emit(lap_number)


func is_on_track() -> bool:
	return RaceTrackData.is_on_track_3d(global_position)


func get_speed() -> float:
	return Vector2(_velocity_vec.x, _velocity_vec.z).length()


func reset_race(start_position: Vector3, start_rotation: float) -> void:
	super.reset_race(start_position, start_rotation)
	_velocity_vec = Vector3.ZERO
