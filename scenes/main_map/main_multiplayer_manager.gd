extends Node

const ui_scene : PackedScene = preload("res://main_map_player_ui.tscn")

@onready var map = $map
@onready var map_cursor = $map/map_cursor
@onready var obj_ctrl = $map/obj_controller
@onready var player_ui_cont = $combat_manager/v/players
@onready var turn_tracker = $combat_manager/turn_tracker
@onready var combat_manager = $combat_manager
@onready var combat_queue = $combat_manager/v/combat_queue


func is_host()->bool:
	return get_iid() == 1
func get_iid()->int:
	return Global.server_controller.instance_id
func get_player_num()->int:
	return get_iid()-1
func get_next_peer_id()->int:
	return Global.player_info_by_num[ get_iid() % 3 ].peer_id


var local_ui : Player_UI = null
var player_uis : Dictionary #p_num : int : Player_UI

func _ready():
	map._refresh()
	map.recolor()
	if !is_host():
		return
	await get_tree().create_timer(0.25).timeout
	create_ui.rpc(0, 1)

@rpc("any_peer", "call_local", "reliable")
func create_ui(num:int, peer_id:int):
	print("RPC:create_ui(num:int,peer_id:int):[",num,",",peer_id,"]\n",
		"from:",multiplayer.get_remote_sender_id(),
		", p:",Global.server_controller.instance_id,
		", on:",multiplayer.get_unique_id(),"@:",Time.get_ticks_msec())
	var ui : Player_UI = ui_scene.instantiate()
	ui.map = map
	ui.cursor = map_cursor
	player_ui_cont.add_child(ui)
	ui.set_multiplayer_authority(peer_id)
	player_uis[num] = ui
	var data : Player_Data = Global.player_info_by_num[num]
	data.peer_id = peer_id
	data.ui = ui
	ui.setup( obj_ctrl, data )
	if num != get_player_num():
		return
	await get_tree().create_timer(0.25).timeout
	local_ui = ui
	ui.out_of_actions.connect(_check_advance)
	if num < 2:
		create_ui.rpc(num+1, get_next_peer_id() )
	else:
		do_starting_spawn.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func do_starting_spawn():
	print("RPC:do_starting_spawn():[]\n",
		"from:",multiplayer.get_remote_sender_id(),
		", p:",Global.server_controller.instance_id,
		", on:",multiplayer.get_unique_id(),"@:",Time.get_ticks_msec())
	var data : Array = Global.player_info_by_num[get_player_num()].team.starting_units
	for i in data.size():
		var unit_id : int = data[i]
		obj_ctrl.local_unit_spawn(unit_id, i)
		await get_tree().create_timer(0.1).timeout
	if get_player_num() < 2:
		do_starting_spawn.rpc_id( get_next_peer_id() )
	else:
		_on_client_complete.rpc_id(1)


@rpc("any_peer", "call_remote", "reliable")
func _check_advance():
	print("RPC:_check_advance():[]\n",
		"from:",multiplayer.get_remote_sender_id(),
		", p:",Global.server_controller.instance_id,
		", on:",multiplayer.get_unique_id(),"@:",Time.get_ticks_msec())
	if turn_tracker.phase != turn_tracker.PHASES.action:
		return
	if get_iid() != 1:
		_check_advance.rpc_id(1)
		return
	for ui:Player_UI in player_uis.values():
		if !ui.end_turn_node.pressed:
			return
	_advance.rpc()

@rpc("any_peer", "call_local", "reliable")
func _advance():
	print("RPC:_advance():[]\n",
		"from:",multiplayer.get_remote_sender_id(),
		", p:",Global.server_controller.instance_id,
		", on:",multiplayer.get_unique_id(),"@:",Time.get_ticks_msec())
	turn_tracker.advance()
	await turn_tracker.anim_complete
	if turn_tracker.phase == turn_tracker.PHASES.action:
		obj_ctrl.confirm_positions.rpc(false)
		if get_iid() == 1:
			start_round(true)
	elif turn_tracker.phase == turn_tracker.PHASES.move:
		var data : Dictionary = obj_ctrl.confirm_positions(true)
		_recieve_data_server.rpc_id(1, get_player_num(), JSON.stringify(data) )
	elif is_host(): #combat phases
		combat_manager._setup()

@rpc("any_peer", "call_local", "reliable")
func start_round(first:bool=false):
	print("RPC:_check_advance():[]\n",
		"from:",multiplayer.get_remote_sender_id(),
		", p:",Global.server_controller.instance_id,
		", on:",multiplayer.get_unique_id(),"@:",Time.get_ticks_msec())
	if get_iid() == 1 and !first:
		return
	await obj_ctrl.start_round()
	local_ui.start_round()
	await get_tree().create_timer(0.25).timeout
	start_round.rpc_id( get_next_peer_id() )

var server_data : Dictionary = {}
@rpc("any_peer", "call_local", "reliable")
func _recieve_data_server(p_num:int, json:String):
	print("RPC:_recieve_data_server(p_num:int, json:String):[",p_num,",",json,"]\n",
		"from:",multiplayer.get_remote_sender_id(),
		", p:",Global.server_controller.instance_id,
		", on:",multiplayer.get_unique_id(),"@:",Time.get_ticks_msec())
	var data : Dictionary = JSON.parse_string(json)
	server_data[p_num] = {}
	for obj_id:String in data.keys():
		server_data[p_num][obj_id.to_int()] = {
			"cube" : Vector3i( Global.vec3_from_json( data[obj_id].cube )),
			"to" : Vector3i( Global.vec3_from_json( data[obj_id].to )),
		}
	print(server_data)
	if server_data.keys().size() != 3:
		return
	json = JSON.stringify(server_data)
	_recieve_positions_clients.rpc( json )
@rpc("authority", "call_local", "reliable")
func _recieve_positions_clients(json:String):
	print("RPC:_recieve_positions_clients(json:String):[",json,"]\n",
		"from:",multiplayer.get_remote_sender_id(),
		", p:",Global.server_controller.instance_id,
		", on:",multiplayer.get_unique_id(),"@:",Time.get_ticks_msec())
	obj_ctrl._on_server_positions( JSON.parse_string(json) )

func _on_combat_queue_attacks_complete():
	_on_client_complete.rpc_id(1, get_player_num())
func _on_obj_controller_move_phase_finished():
	_on_client_complete.rpc_id(1, get_player_num())
@rpc("any_peer", "call_local", "reliable")
func _on_client_complete(p_num:int=-1):
	print("RPC:_on_client_complete(p_num:int=-1):[",p_num,"]\n",
		"from:",multiplayer.get_remote_sender_id(),
		", p:",Global.server_controller.instance_id,
		", on:",multiplayer.get_unique_id(),"@:",Time.get_ticks_msec())
	if !is_host():
		return
	if p_num in server_data:
		server_data.erase(p_num)
	if server_data.size():
		return
	obj_ctrl.do_local_sale.rpc()
	_advance.rpc()




