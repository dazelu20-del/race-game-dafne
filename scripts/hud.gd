extends CanvasLayer

@onready var position_label: Label = %PositionLabel
@onready var lap_label: Label = %LapLabel
@onready var time_label: Label = %TimeLabel
@onready var speed_label: Label = %SpeedLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var finish_panel: PanelContainer = %FinishPanel
@onready var finish_label: Label = %FinishLabel
@onready var controls_label: Label = %ControlsLabel


func _ready() -> void:
	hide_countdown()
	hide_finish()


func set_status(text: String) -> void:
	controls_label.text = text


func update_display(race_position: int, lap: int, total_laps: int, time: float, speed: float, off_track: bool = false) -> void:
	position_label.text = "Pos: %d" % race_position
	lap_label.text = "Lap: %d/%d" % [mini(lap + 1, total_laps), total_laps]
	time_label.text = "Time: %s" % _format_time(time)
	if off_track:
		speed_label.text = "Speed: %d  (OFF TRACK!)" % int(speed)
		speed_label.add_theme_color_override("font_color", Color(1, 0.45, 0.45))
	else:
		speed_label.text = "Speed: %d" % int(speed)
		speed_label.add_theme_color_override("font_color", Color(1, 1, 1))


func show_countdown(value: float) -> void:
	countdown_label.visible = true
	if value > 0.0:
		countdown_label.text = str(int(value))
	else:
		countdown_label.text = "GO!"


func hide_countdown() -> void:
	countdown_label.visible = false


func show_finish(order: Array[String]) -> void:
	finish_panel.visible = true
	var lines: PackedStringArray = []
	for i in order.size():
		lines.append("%d. %s" % [i + 1, order[i]])
	finish_label.text = "Race Over!\n\n" + "\n".join(lines) + "\n\nPress R to restart"


func hide_finish() -> void:
	finish_panel.visible = false


func _format_time(seconds: float) -> String:
	var mins: int = floori(seconds / 60.0)
	var secs: float = fmod(seconds, 60.0)
	return "%d:%05.2f" % [mins, secs]
