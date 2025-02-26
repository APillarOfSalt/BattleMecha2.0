extends VBoxContainer

func _start_the_game():
	Global.game_speed = float(16-game_speed )/16.0
	Global.turn_limit = rounds_max
	Global.points_to_win = points_max


@onready var spd_l : Label = $speed/Label
@onready var spd_slider : HSlider = $speed/HSlider
@onready var game_speed : int = spd_slider.value
func _on_h_slider_drag_ended(value_changed:bool):
	game_speed = spd_slider.value
	if Global.server_controller.instance_id != 1:
		return
	remote_spd_set.rpc(game_speed)

@rpc("authority", "call_remote", "reliable")
func remote_spd_set(val:int):
	spd_slider.value = val
	game_speed = val

func _on_conn_host_client_joined(iid):
	remote_spd_set.rpc(game_speed)
func _on_conn_host_server_started():
	spd_slider.mouse_filter = Control.MOUSE_FILTER_STOP
	spd_slider.modulate = Color.WHITE
func _on_conn_host_server_stopped():
	spd_slider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spd_slider.modulate = Color.DIM_GRAY


@onready var rounds_spin : SpinBox = $limits/rounds
@onready var rounds_max : int = rounds_spin.value
func _on_rounds_value_changed(value):
	rounds_max = value
	if Global.server_controller.instance_id != 1:
		return
	remote_rounds_set.rpc(value)
@rpc("authority", "call_remote", "reliable")
func remote_rounds_set(value:int):
	rounds_spin.value = value
	rounds_max = value

@onready var points_spin : SpinBox = $limits/points
@onready var points_max : int = points_spin.value
func _on_points_value_changed(value):
	points_max = value
	if Global.server_controller.instance_id != 1:
		return
	remote_points_set.rpc(value)
@rpc("authority", "call_remote", "reliable")
func remote_points_set(value:int):
	points_spin.value = value
	points_max = value
