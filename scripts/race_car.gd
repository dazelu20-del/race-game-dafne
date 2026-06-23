class_name RaceCar
extends CharacterBody2D

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
	return velocity.length()


func reset_race(start_position: Vector2, start_rotation: float) -> void:
	global_position = start_position
	rotation = start_rotation
	velocity = Vector2.ZERO
	current_lap = 0
	next_checkpoint = 0
	race_finished = false
	can_drive = false
