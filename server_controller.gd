extends Node
class_name Server_Controller

var this_computer_ip:
	get:
		if OS.has_feature("windows"):
			if OS.has_environment("COMPUTERNAME"):
				return IP.resolve_hostname(str(OS.get_environment("COMPUTERNAME")),IP.TYPE_IPV4)
		elif OS.has_feature("x11"):
			if OS.has_environment("HOSTNAME"):
				return IP.resolve_hostname(str(OS.get_environment("HOSTNAME")),IP.TYPE_IPV4)
		elif OS.has_feature("OSX"):
			if OS.has_environment("HOSTNAME"):
				return IP.resolve_hostname(str(OS.get_environment("HOSTNAME")),IP.TYPE_IPV4)
		return ""

signal joined_server(iid:int)
signal left_server(iid:int)
signal wrong_password()
signal join_timeout()

@onready var host : Host_Controller = $Host_Controller
@onready var chat : Chat_Controller = $Chat_Controller

func _reset():
	instance_id = -1
	connect_ip = "localhost"
	current_port = 1024
	password = ""

var instance_id : int = -1
var connect_ip : String = "localhost"
var current_port : int = 1024
var password : String = ""

var upnp : UPNP = null
var peer = ENetMultiplayerPeer.new()
func refresh_gateway()->bool:
	upnp = UPNP.new()
	var result = upnp.discover()
	if result == UPNP.UPNP_RESULT_SUCCESS:
		if upnp.get_gateway() and upnp.get_gateway().is_valid_gateway():
			return true
	return false

@export var timeout_wait_sec : float = 3.0
func join_server()->int:
	var err : int = peer.create_client(connect_ip, current_port)
	if err == OK: #join
		multiplayer.multiplayer_peer = peer
		if !multiplayer.connected_to_server.is_connected(_on_connected_to_a_server):
			multiplayer.connected_to_server.connect(_on_connected_to_a_server)
		await get_tree().create_timer(timeout_wait_sec).timeout
		if instance_id == -1:
			leave_server()
			join_timeout.emit()
	return err
func leave_server():
	if multiplayer.connected_to_server.is_connected(_on_connected_to_a_server):
		multiplayer.connected_to_server.disconnect(_on_connected_to_a_server)
	multiplayer.multiplayer_peer.close()
	left_server.emit()

func _on_connected_to_a_server():
	print("connected ",multiplayer.get_unique_id()," : ",Time.get_ticks_msec())
	host.rpc_id(1, "check_my_password", password)
@rpc("authority", "reliable")
func server_wrong_password():
	print("final bad ",multiplayer.get_unique_id()," : ",Time.get_ticks_msec())
	leave_server()
	wrong_password.emit()
@rpc("authority", "call_local", "reliable")
func server_handshake(iid:int):
	print("final good ",multiplayer.get_unique_id()," : ",Time.get_ticks_msec())
	joined_server.emit(iid)
	print(iid)
	instance_id = iid

@rpc("authority", "call_remote", "reliable")
func client_save_lobby():
	DataLoader.save_game_start({
		"iid" : instance_id,
		"ip" : connect_ip,
		"port" : current_port,
		"word" : password,
	})

func check_lobby_still_exists(iid:int, ip:String, port:int, word:String):
	instance_id = iid
	connect_ip = ip
	current_port = port
	password = word
	if refresh_gateway():
		join_server()



