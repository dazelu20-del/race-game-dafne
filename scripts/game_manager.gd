extends Node2D

signal race_finished(winner_name: String)
signal race_started
signal hud_update(race_position: int, lap: int, total_laps: int, time: float, speed: float)

const TOTAL_LAPS := 3

@onready var player: PlayerCar = %Player
@onready var ai_cars: Array[AICar] = [%AICar1, %AICar2, %AICar3]
@onready var checkpoints: Array[Checkpoint] = []
@onready var hud: CanvasLayer = %HUD
@onready var start_positions: Node2D = %StartPositions
@onready var track: MonacoTrack = %Track
@onready var camera: Camera2D = $Camera2D

const BASE_ZOOM := Vector2(0.48, 0.48)
const INTRO_ZOOM := Vector2(0.42, 0.42)

var _race_time := 0.0
var _racing := false
var _player_finished := false
var _finished_order: Array[String] = []
var _countdown := 2.0
var _using_intro_camera := true


func _ready() -> void:
	camera.make_current()
	camera.zoom = INTRO_ZOOM
	camera.global_position = MonacoTrackData.TRACK_CENTER
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


func _process(delta: float) -> void:
	var target_zoom := INTRO_ZOOM if _using_intro_camera else BASE_ZOOM
	var speed_ratio := clampf(player.get_speed() / player.max_speed, 0.0, 1.0)
	if _racing and not _using_intro_camera:
		target_zoom = BASE_ZOOM * (1.0 - speed_ratio * 0.06)

	var camera_target := MonacoTrackData.TRACK_CENTER if _using_intro_camera else player.global_position
	camera_target = _clamp_camera_position(camera_target)
	camera.global_position = camera.global_position.lerp(camera_target, delta * 8.0)
	camera.zoom = camera.zoom.lerp(target_zoom, delta * 4.0)

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
	_using_intro_camera = false
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


func _on_checkpoint_body_entered(body: Node2D, index: int) -> void:
	if not _racing:
		return
	if body is RaceCar:
		body.pass_checkpoint(index, checkpoints.size())


func _check_ai_finish() -> void:
	var names: Array[String] = ["Red Racer", "Green Machine", "Gold Streak"]
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
	var grid: Array[Dictionary] = MonacoTrackData.get_start_grid()
	var markers: Array[Node] = start_positions.get_children()
	for i in mini(grid.size(), markers.size()):
		var marker := markers[i] as Marker2D
		marker.position = grid[i]["position"] as Vector2
		marker.rotation = grid[i]["rotation"] as float

	player.reset_race(grid[0]["position"] as Vector2, grid[0]["rotation"] as float)
	for i in ai_cars.size():
		var idx := mini(i + 1, grid.size() - 1)
		ai_cars[i].reset_race(grid[idx]["position"] as Vector2, grid[idx]["rotation"] as float)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		restart_race()


func restart_race() -> void:
	_race_time = 0.0
	_racing = false
	_player_finished = false
	_finished_order.clear()
	_countdown = 2.0
	_using_intro_camera = true
	camera.zoom = INTRO_ZOOM
	camera.global_position = MonacoTrackData.TRACK_CENTER

	player.can_drive = false
	for ai in ai_cars:
		ai.can_drive = false

	hud.hide_finish()
	hud.show_countdown(2.0)
	hud.set_status("Get ready...")
	_apply_start_grid()
	_update_hud()


func _clamp_camera_position(target: Vector2) -> Vector2:
	var half_view := get_viewport().get_visible_rect().size * 0.5 / camera.zoom
	var bounds := MonacoTrackData.TRACK_BOUNDS
	return Vector2(
		clampf(target.x, bounds.position.x + half_view.x, bounds.end.x - half_view.x),
		clampf(target.y, bounds.position.y + half_view.y, bounds.end.y - half_view.y)
	)
