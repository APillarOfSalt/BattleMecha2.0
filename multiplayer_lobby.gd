extends Container

const player_disp_scene : PackedScene = preload("res://lobby_display.tscn")
@onready var player_cont : Container = $v/main/left/players

@onready var netcode : Container = $v/main/left/top/conn_host

var peers : Array:
	get: return multiplayer.get_peers()
func get_id_dict()->Dictionary:
	return Global.server_controller.host.iid_uid
func get_iid()->int:
	return Global.server_controller.instance_id -1
func get_status()->int:
	return netcode.status
func is_host()->bool:
	return get_status() == netcode.STATUS.hosting

func _on_title_changes_made(iid:int=-1):
	#HOST ONLY : client_joined(client_instance_id==iid)
	if is_host():
		await Global.create_wait_timer()
		if peers.size():
			player_cont._sync_player_num.rpc()
		else:
			player_cont._sync_player_num()

var all_data : Array[Player_Data] = [null,null,null]
func _on_players_local_player_readied(data:Player_Data=null):
	var p_num : int = get_iid()
	if all_data[p_num] != null and data == null:
		_clear_player_info.rpc(p_num)
	else:
		all_data[p_num] = data
		if data != null:
			_send_player_info()


@rpc("authority", "call_remote", "reliable")
func _send_player_info():
	var data : Player_Data = player_cont.local_player.get_player_data()
	if data == null:
		return
	all_data[data.num] = data
	player_cont.set_player_data(data)
	_receive_player_info.rpc(data._to_json_string())

var recieved_from : Dictionary = {} #peer_id:int : Player_Data

@rpc("any_peer", "call_remote", "reliable")
func _receive_player_info(json:String):
	var data := Player_Data.new(json)
	all_data[data.num] = data
	player_cont.set_player_data(data)
	recieved_from[ multiplayer.get_remote_sender_id() ] = data
	if is_host() and recieved_from.keys().size() >= 2:
		check_go()

@rpc("any_peer", "call_local", "reliable")
func _clear_player_info(iid:int):
	var peer_id : int = multiplayer.get_remote_sender_id()
	if peer_id in recieved_from:
		recieved_from.erase( peer_id )
	all_data[iid] = null


@onready var player_module : Container = $v/main/left/players
func check_go()->bool:
	if !player_module.check_ready():
		return false
	countdown._start()
	return true

@onready var countdown : Container = $center
func _process(delta):
	if !check_go():
		countdown._stop()

func _on_center_countdown_complete():
	if multiplayer.get_unique_id() != 1:
		return
	start_the_game()

@onready var game_settings : Container = $v/main/left/top/game_settings

@rpc("authority", "call_remote", "reliable")
func start_the_game():
	game_settings._start_the_game()
	print(Global.game_speed)
	Global.local_player = get_iid()
	for p_data:Player_Data in all_data:
		Global.player_info_by_num[int(p_data.num)] = p_data
	if is_host():
		Global.server_controller.host.server_save_lobby()
		start_the_game.rpc()
		await Global.create_wait_timer()
	get_tree().change_scene_to_file("res://main_map.tscn")





