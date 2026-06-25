extends Node3D

signal race_finished(winner_name: String)
signal race_started
signal hud_update(race_position: int, lap: int, total_laps: int, time: float, speed: float)

const TOTAL_LAPS := 3

@onready var player: PlayerCar = %Player
@onready var camera_rig: ChaseCameraRig = %CameraRig
@onready var ai_cars: Array[AICar] = [%AICar1, %AICar2, %AICar3]
@onready var checkpoints: Array[Checkpoint] = []
@onready var hud: CanvasLayer = %HUD
@onready var start_positions: Node3D = %StartPositions
@onready var track: RaceTrack = %Track

var _race_time := 0.0
var _racing := false
var _player_finished := false
var _finished_order: Array[String] = []
var _countdown := 2.0


func _ready() -> void:
	camera_rig.set_intro_mode(true)
	if not track.collision_ready.is_connected(_on_track_collision_ready):
		track.collision_ready.connect(_on_track_collision_ready)
	call_deferred("_setup_race")


func _setup_race() -> void:
	for child in get_tree().get_nodes_in_group("checkpoint"):
		checkpoints.append(child as Checkpoint)
	checkpoints.sort_custom(func(a, b): return a.checkpoint_index < b.checkpoint_index)

	for checkpoint in checkpoints:
		checkpoint.body_entered.connect(_on_checkpoint_body_entered.bind(checkpoint.checkpoint_index))

	player.lap_completed.connect(_on_player_lap_completed)

	for ai in ai_cars:
		ai.set_waypoints(track.get_ai_waypoints())

	_apply_start_grid()
	hud.show_countdown(2.0)
	hud.set_status("Get ready...")
	_update_hud()
	_snap_all_cars_to_ground()


func _on_track_collision_ready() -> void:
	_snap_all_cars_to_ground()


func _snap_all_cars_to_ground() -> void:
	player.snap_to_ground_when_ready()
	for ai in ai_cars:
		ai.snap_to_ground_when_ready()


func _process(delta: float) -> void:
	if _countdown > 0.0:
		_countdown -= delta
		var shown := maxi(int(ceil(_countdown)), 0)
		hud.show_countdown(float(shown) if shown > 0 else 0.0)
		hud.set_status("Race starts in %d... (WASD to drive)" % shown if shown > 0 else "GO!")
		if _countdown <= 0.0:
			_start_racing()
		return

	if not _racing:
		return

	if not _player_finished:
		_race_time += delta
	_check_ai_finish()
	_update_hud()


func _start_racing() -> void:
	hud.hide_countdown()
	hud.set_status("WASD / Arrows to drive  |  R to restart")
	_racing = true
	camera_rig.set_chase_mode(true)
	player.can_drive = true
	for ai in ai_cars:
		ai.can_drive = true
	race_started.emit()


func _update_hud() -> void:
	var race_position: int = _get_player_position()
	var speed: float = player.get_speed()
	hud_update.emit(race_position, player.current_lap, TOTAL_LAPS, _race_time, speed)
	hud.update_display(race_position, player.current_lap, TOTAL_LAPS, _race_time, speed, not player.is_on_track())


func _get_player_position() -> int:
	var racers: Array[RaceCar] = [player]
	racers.append_array(ai_cars)
	racers.sort_custom(func(a, b):
		if a.current_lap != b.current_lap:
			return a.current_lap > b.current_lap
		return a.next_checkpoint > b.next_checkpoint
	)
	return racers.find(player) + 1


func _on_checkpoint_body_entered(body: Node3D, index: int) -> void:
	if not _racing:
		return
	if body is RaceCar:
		body.pass_checkpoint(index, checkpoints.size())


func _check_ai_finish() -> void:
	var names: Array[String] = ["Red Bull Racing", "Green Machine", "Gold Streak"]
	for i in ai_cars.size():
		var ai := ai_cars[i]
		if ai.current_lap >= TOTAL_LAPS and not ai.race_finished:
			_finish_racer(ai, names[i])


func _on_player_lap_completed(lap_number: int) -> void:
	if lap_number >= TOTAL_LAPS:
		_finish_racer(player, "You")


func _finish_racer(racer: RaceCar, racer_name: String) -> void:
	if racer_name in _finished_order:
		return
	_finished_order.append(racer_name)
	racer.race_finished = true

	if racer == player:
		_player_finished = true
		hud.show_finish(_finished_order)
		race_finished.emit(racer_name)
	elif _player_finished:
		hud.show_finish(_finished_order)


func _apply_start_grid() -> void:
	var grid: Array[Dictionary] = RaceTrackData.get_start_grid()
	var markers: Array[Node] = start_positions.get_children()
	for i in mini(grid.size(), markers.size()):
		var marker := markers[i] as Marker3D
		marker.position = grid[i]["position"] as Vector3
		marker.rotation.y = grid[i]["rotation"] as float

	player.reset_race(grid[0]["position"] as Vector3, grid[0]["rotation"] as float)
	for i in ai_cars.size():
		var idx := mini(i + 1, grid.size() - 1)
		ai_cars[i].reset_race(grid[idx]["position"] as Vector3, grid[idx]["rotation"] as float)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		restart_race()


func restart_race() -> void:
	_race_time = 0.0
	_racing = false
	_player_finished = false
	_finished_order.clear()
	_countdown = 2.0
	camera_rig.set_intro_mode(true)

	player.can_drive = false
	for ai in ai_cars:
		ai.can_drive = false

	hud.hide_finish()
	hud.show_countdown(2.0)
	hud.set_status("Get ready...")
	_apply_start_grid()
	_update_hud()
	_snap_all_cars_to_ground()
