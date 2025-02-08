extends Node
class_name Host_Controller

@onready var client : Server_Controller = get_parent()

@rpc("any_peer", "reliable")
func check_my_password(word:String):
	print("checking password :", word)
	var uid : int = multiplayer.get_remote_sender_id()
	if word != password:
		print("password_fail")
		client.server_wrong_password.rpc_id(uid)
		return
	iid_counter += 1
	iid_uid[iid_counter] = uid
	client.server_handshake.rpc_id(uid, iid_counter)
	joined_server.emit(iid_counter)
	print("password_success")

signal joined_server(iid:int)
signal port_forwarded(port:int)
signal port_backwarded(port:int)
signal left_server(iid:int)

var upnp : UPNP = null
var peer = ENetMultiplayerPeer.new()
func refresh_gateway()->bool:
	upnp = UPNP.new()
	var result = upnp.discover()
	if result == UPNP.UPNP_RESULT_SUCCESS:
		if upnp.get_gateway() and upnp.get_gateway().is_valid_gateway():
			return true
	return false

func forward_port(port:int)->bool:
	if !refresh_gateway():
		return false
	for p:String in ["tcp","udp"]:
		var proto : String = p.to_upper()
		var map_result = upnp.add_port_mapping(port,port,"godot_"+p, proto, 0)
		if map_result != UPNP.UPNP_RESULT_SUCCESS:
			map_result = upnp.add_port_mapping(port,port,"", proto)
			if map_result != UPNP.UPNP_RESULT_SUCCESS:
				return false
		port_forwarded.emit(port)
	return true

signal server_started()
var connect_ip : String = "localhost"
var current_port : int = 1024
var password : String = ""
var instance_id : int = -1 #should always be 1 when hosting
signal server_stopped()

func server_save_lobby():
	client.client_save_lobby.rpc()
	DataLoader.save_game_start({
		"iid" : 1,
		"ip" : connect_ip,
		"port" : current_port,
		"word" : password,
	})


var server_running : bool:
	set(val):
		if !server_running and val:
			client.instance_id = 1
			server_started.emit()
		elif server_running and !val:
			client.instance_id = 0
			server_stopped.emit()
const max_players : int = 3
var iid_counter : int = 1
var iid_uid : Dictionary = {} #instance_id:int : peer_id:int
func get_iid(uid:int):
	for iid:int in iid_uid.keys():
		if iid_uid[iid] == uid:
			return iid
	return -1
func get_iids(include1:bool=true):
	var iids : Array = iid_uid.keys()
	if !include1:
		var found : int = iids.find(1)
		if found >= 0:
			iids.remove_at(found)
	return iids

func start_server(port:int, address:String="localhost")->int:
	if !refresh_gateway():
		return false
	if address != "localhost":
		if forward_port(port):
			connect_ip = upnp.query_external_address()
		else:
			close_server()
			return -1
	return open_server(port)

func open_server(port)->int:
	var error = peer.create_server(port, 2)
	if error != OK:
		close_server()
		return error
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_disconnected.connect(_on_peer_disconnect)
	iid_counter = 1
	instance_id = 1
	iid_uid = {1:1}
	print("upnp:",upnp.get_instance_id())
	print("peer:",peer.get_instance_id())
	server_running = true ## SIGNAL EMIT
	return OK

func _on_peer_disconnect(uid:int):
	for iid:int in iid_uid.keys():
		if iid_uid[iid] == uid:
			iid_uid.erase(iid)
			left_server.emit(iid)
			return

func close_server():
	server_running = false ## SIGNAL EMIT
	iid_uid.clear()
	iid_counter = 0
	client.left_server.emit(instance_id)
	instance_id = -1
	if connect_ip != "localhost":
		upnp.delete_port_mapping(current_port, "UDP")
		upnp.delete_port_mapping(current_port, "TCP")
		port_backwarded.emit(current_port)
