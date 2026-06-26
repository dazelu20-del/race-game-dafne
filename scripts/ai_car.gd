class_name AICar
extends RaceCar

@export var max_speed := 360.0
@export var acceleration := 700.0
@export var turn_speed := 2.6
@export var color := Color.CRIMSON
@export var waypoint_tolerance := 12.0
@export_file("*.glb") var car_model_path: String = ""

var _velocity_vec := Vector3.ZERO
var _waypoints: Array[Vector3] = []
var _waypoint_index := 0

@onready var visual_root: Node3D = $VisualRoot


func _ready() -> void:
	floor_snap_length = 0.4
	floor_max_angle = deg_to_rad(50.0)
	safe_margin = 0.08

	if car_model_path.is_empty():
		_apply_placeholder_color(color)
	else:
		_setup_imported_model()


func _apply_placeholder_color(car_color: Color) -> void:
	for child in visual_root.get_children():
		if child is MeshInstance3D:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = car_color
			child.material_override = mat


func _setup_imported_model() -> void:
	CarModelSetup.hide_placeholder_meshes(visual_root)
	var model := CarModelSetup.attach_model(visual_root, car_model_path)
	if model == null:
		_apply_placeholder_color(color)
		for child in visual_root.get_children():
			if child is MeshInstance3D:
				child.visible = true


func set_waypoints(points: Array[Vector3]) -> void:
	_waypoints = points
	_waypoint_index = 0


func _physics_process(delta: float) -> void:
	if race_finished or not can_drive or _waypoints.is_empty():
		_velocity_vec = _velocity_vec.move_toward(Vector3.ZERO, 800.0 * delta)
		velocity = _velocity_vec
		move_and_slide()
		snap_to_ground()
		return

	var target := _waypoints[_waypoint_index]
	var to_target := target - global_position
	to_target.y = 0.0

	if to_target.length() < waypoint_tolerance:
		_waypoint_index = (_waypoint_index + 1) % _waypoints.size()
		target = _waypoints[_waypoint_index]
		to_target = target - global_position
		to_target.y = 0.0

	var desired_dir := to_target.normalized()
	var current_forward := get_forward()
	var angle_diff := atan2(
		current_forward.x * desired_dir.z - current_forward.z * desired_dir.x,
		current_forward.dot(desired_dir)
	)
	var corner_scale := clampf(1.0 - absf(angle_diff) / PI, 0.5, 1.0)
	rotation.y += clampf(angle_diff, -turn_speed * delta, turn_speed * delta) * 1.2

	var forward := get_forward()
	var target_speed := max_speed * corner_scale
	_velocity_vec = _velocity_vec.move_toward(forward * target_speed, acceleration * delta)
	_velocity_vec.y = 0.0
	_velocity_vec = _velocity_vec.limit_length(target_speed)

	velocity = _velocity_vec
	move_and_slide()
	snap_to_ground()

	if get_slide_collision_count() > 0:
		_velocity_vec = velocity
		_velocity_vec.y = 0.0


func reset_race(start_position: Vector3, start_rotation: float) -> void:
	super.reset_race(start_position, start_rotation)
	_velocity_vec = Vector3.ZERO
	_waypoint_index = 0
