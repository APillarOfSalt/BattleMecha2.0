extends MarginContainer

signal changes_made(iid:int)

var peers : Array:
	get: return multiplayer.get_peers()

##HOST SIGNALS##
func _on_conn_host_server_started():
	connection_status_label.text = str("Hosting ",peers.size()+1,"/3")
	connection_status_label.modulate = Color(0.0,0.75,0.6)
	changes_made.emit(-1)
func _on_conn_host_server_stopped():
	_reset_conn_l()
	changes_made.emit(-2)
func _on_conn_host_client_joined(iid:int):
	connection_status_label.text = str("Hosting ",peers.size()+1,"/3")
	changes_made.emit(iid)
	await Global.create_wait_timer()
	get_parent().get_parent()._send_player_info.rpc()
func _on_conn_host_client_left(iid:int):
	connection_status_label.text = str("Hosting ",peers.size()+1,"/3")
	changes_made.emit(iid)
@onready var connection_status_label : Label = $text/status

##CLIENT SIGNALS##
func _on_conn_host_server_joined():
	connection_status_label.text = "Connected"
	connection_status_label.modulate = Color(0, 0.75, 0)
	changes_made.emit(-1)
func _on_conn_host_server_left():
	_reset_conn_l()
	changes_made.emit(-2)

func _reset_conn_l():
	connection_status_label.text = "Disconnected"
	connection_status_label.modulate = Color(0.75 ,0,0)



func _on_main_menu_pressed():
	Global.to_main_menu_scene()
