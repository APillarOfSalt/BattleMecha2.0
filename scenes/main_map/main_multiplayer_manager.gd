extends Node

const ui_scene : PackedScene = preload("res://main_map_player_ui.tscn")

@onready var map = $map
@onready var map_cursor = $map/map_cursor
@onready var obj_ctrl = $map/obj_controller
@onready var player_ui_cont = $combat_manager/v/players
@onready var turn_tracker = $combat_manager/turn_tracker
@onready var combat_manager = $combat_manager
@onready var combat_queue = $combat_manager/v/m/atks/combat_queue


func is_host()->bool:
	return get_iid() == 1
func get_iid()->int:
	return Global.server_controller.instance_id
func get_player_num()->int:
	return get_iid()-1
func get_next_peer_id()->int:
	return Global.player_info_by_num[ get_iid() % 3 ].peer_id

@onready var local_cursor : Map_Cursor = $map/map_cursor
var local_ui : Player_UI = null
var player_uis : Dictionary #p_num : int : Player_UI

func _on_scoring_give_points_to(num:int, val:int):
	player_uis[num].gain_points(val)
	give_score.rpc(num, val)
@rpc("any_peer", "call_remote", "reliable")
func give_score(num,val):
	player_uis[num].gain_points(val)
	printerr(local_ui.victory_points,":",Global.points_to_win)

func _ready():
	map._refresh()
	map.recolor()
	await Global.create_wait_timer(1)
	if is_host():
		_do_scene_enter.rpc()
	else:
		entered_scene.rpc_id(1)

@rpc("authority", "call_remote", "reliable")
func _do_scene_enter():
	entered_scene.rpc_id(1)

var entered : Array[int] = []
@rpc("any_peer", "call_remote", "reliable")
func entered_scene():
	var peer_id : int = multiplayer.get_remote_sender_id()
	if !peer_id in entered:
		entered.append(peer_id)
	if entered.size() == 2:
		entered.append(1)
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
		ui.end_action_phase()
		return
	await Global.create_wait_timer(1)
	local_ui = ui
	local_cursor.local_ui = ui
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
		await Global.create_wait_timer(0.25)
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
	if !is_host():
		_check_advance.rpc_id(1)
		return
	for ui:Player_UI in player_uis.values():
		if !ui.end_turn_node.pressed:
			return
	print("advance @_check_advance()")
	_advance.rpc()

@rpc("any_peer", "call_local", "reliable")
func _advance():
	print("RPC:_advance():[], phase:",turn_tracker.phase,"\n",
		"from:",multiplayer.get_remote_sender_id(),
		", p:",Global.server_controller.instance_id,
		", on:",multiplayer.get_unique_id(),"@:",Time.get_ticks_msec())
	turn_tracker.advance()
	local_ui.end_action_phase()
	map_cursor.can_act_override = false
	await turn_tracker.anim_complete
	if turn_tracker.phase == turn_tracker.PHASES.action:
		if !is_host():
			return
		start_round()
	elif turn_tracker.phase == turn_tracker.PHASES.move:
		var data : Dictionary = obj_ctrl.confirm_positions(true)
		_recieve_data_server.rpc_id(1, get_player_num(), JSON.stringify(data) )
	elif turn_tracker.phase == turn_tracker.PHASES.end:
		obj_ctrl.confirm_positions(false)
		if is_host():
			$map/scoring._deploy_score()
	elif is_host(): #combat phases
		combat_manager._setup()

var scores : Dictionary = {}
func _on_scoring_finished():
	if !is_host():
		return
	obj_ctrl.tuck_rollers.rpc()
	await Global.create_wait_timer(0.1)
	for ui in player_uis.values():
		if ui.victory_points >= Global.points_to_win:
			turn_tracker.start_overtime.rpc()
		scores[ui.player_num] = ui.victory_points
	var has_tie : bool = false
	for score in scores.values():
		if scores.values().count(score) > 1:
			printerr("found tie")
			has_tie = true
			break
	if !turn_tracker.overtime or has_tie:
		_advance.rpc()
	else:
		$combat_manager/end_screen._setup(scores)

func _on_obj_controller_out_of_units():
	turn_tracker.start_overtime.rpc()

@rpc("any_peer", "call_local", "reliable")
func start_round(not_first:bool=false):
	print("RPC:_check_advance():[]\n",
		"from:",multiplayer.get_remote_sender_id(),
		", p:",Global.server_controller.instance_id,
		", on:",multiplayer.get_unique_id(),"@:",Time.get_ticks_msec())
	if is_host() and not_first:
		finalize_start.rpc()
		return
	if turn_tracker.round > 1:
		await obj_ctrl.start_round()
	start_round.rpc_id( get_next_peer_id(), true)
@rpc("authority", "call_local", "reliable")
func finalize_start():
	local_ui.start_round()
	map_cursor.can_act_override = true

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

var combat_complete_count : int = 0
func _on_obj_controller_combat_move_finished():
	_on_combat_complete.rpc_id(1, get_player_num())
@rpc("any_peer", "call_local", "reliable")
func _on_combat_complete(p_num:int=-1):
	print( "RPC:_on_combat_complete(p_num:int):[",p_num,"]\n",
		"from:",multiplayer.get_remote_sender_id(),
		", p:",Global.server_controller.instance_id,
		", on:",multiplayer.get_unique_id(),
		", @:",Time.get_ticks_msec() )
	if !is_host():
		return
	printerr("Count : ",combat_complete_count)
	combat_complete_count += 1
	combat_complete_count %= 3
	if combat_complete_count:
		return
	if combat_manager.last_was_overlap:
		combat_manager._setup()
		return
	print("advance @_on_combat_complete(",p_num,")",combat_complete_count)
	_advance.rpc()

func _on_obj_controller_move_phase_finished():
	_on_client_complete.rpc_id(1, get_player_num())
@rpc("any_peer", "call_local", "reliable")
func _on_client_complete(p_num:int=-1):
	print("RPC:_on_client_complete(",p_num,"):data:",server_data,"\n",
		"from:",multiplayer.get_remote_sender_id(),
		", p:",Global.server_controller.instance_id,
		", on:",multiplayer.get_unique_id(),", p_num:",get_player_num(),
		", @:",Time.get_ticks_msec())
	if !is_host():
		return
	if p_num in server_data:
		server_data.erase(p_num)
	if server_data.size():
		return
	obj_ctrl.do_local_sale.rpc()
	print("advance @_on_client_complete(",p_num,")")
	_advance.rpc()




