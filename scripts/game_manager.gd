extends Node3D

@onready var track: RaceTrack = %Track
@onready var overview_camera: Camera3D = $OverviewCamera
@onready var hud: CanvasLayer = %HUD


func _ready() -> void:
	overview_camera.current = true
	overview_camera.look_at(RaceTrackData.TRACK_CENTER, Vector3.UP)
	hud.hide_countdown()
	hud.set_status("Track view")
	_hide_checkpoint_gates()


func _hide_checkpoint_gates() -> void:
	for checkpoint in track.find_children("*", "Checkpoint", true, false):
		var gate := checkpoint.get_node_or_null("Gate")
		if gate != null:
			gate.visible = false
