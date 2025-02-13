extends MarginContainer

const ui_scene : PackedScene = preload("res://main_map_player_ui.tscn")

@onready var obj_ctrl : Object_Controller = $map/obj_controller
@onready var turn_tracker : Turn_Tracker = $main_text
@onready var combat_manager : Combat_Manager = $manager
@onready var combat_display : Combat_Display = $manager/display
@onready var map : TileMap = $map
var map_tileset : TileSet = preload("res://main_map_tileset.tres")

var iid : int:
	get: return Global.server_controller.instance_id
var local_player : int = 0:
	get: return iid-1
var local_ui : Player_UI = null
@onready var player_ui_cont : Container = $manager/players
var player_uis : Dictionary #p_num : int : Player_UI
func _ready():
	map._refresh()
	map.recolor()
	if iid == 1:
		await get_tree().create_timer(0.5).timeout
		for p_num in Global.player_info_by_num.keys():
			var p_data : Player_Data = Global.player_info_by_num[p_num]
			spawn_units[p_data.peer_id] = p_data.team.starting_units
			create_ui.rpc(p_num, p_data.peer_id)
		await get_tree().create_timer(0.01).timeout
		do_starting_spawn()
var spawn_units : Dictionary = {} #player_num:int : [unit_id:int, x3]

@onready var local_cursor : Map_Cursor = $map/map_cursor
@rpc("authority", "call_local", "reliable")
func create_ui(num:int, peer_id:int):
	var ui : Player_UI = ui_scene.instantiate()
	ui.map = map
	ui.cursor = local_cursor
	player_ui_cont.add_child(ui)
	ui.out_of_actions.connect(_check_advance)
	ui.set_multiplayer_authority(peer_id)
	player_uis[num] = ui
	if num == local_player:
		local_ui = ui
		ui._on_roller_spawn_complete.connect(_on_local_complete)
	var data : Player_Data = Global.player_info_by_num[num]
	data.peer_id = peer_id
	data.ui = ui
	ui.setup( obj_ctrl, data )

@rpc("any_peer", "call_local", "reliable")
func do_starting_spawn():
	if spawn_units.keys().size() == 0:
		return
	finish_setup.rpc()
	var peer_id : int = spawn_units.keys()[0]
	var unit_id : int = spawn_units[peer_id].pop_front()
	var sz : int = spawn_units[peer_id].size()
	if sz == 0:
		spawn_units.erase(peer_id)
	do_start_spawn.rpc_id(peer_id, unit_id, 2 - sz)
@rpc("authority", "call_local", "reliable")
func do_start_spawn(unit_id:int, r_index:int):
	obj_ctrl.local_unit_spawn( unit_id, r_index )
	do_starting_spawn.rpc_id(1)

@rpc("any_peer", "call_local", "reliable")
func finish_setup():
	#multiplayer.get_remote_sender_id()
	turn_tracker.setup += 1

func _on_local_complete():
	if local_player < 2:
		var peer_id : int = Global.player_info_by_num[local_player+1].peer_id
		player_uis[local_player+1]._start_round.rpc_id(peer_id)

func _check_advance():
	if iid != 1 or turn_tracker.phase != turn_tracker.PHASES.action:
		return
	for ui:Player_UI in player_ui_cont.get_children():
		if !ui.end_turn_node.pressed:
			return
	_advance.rpc()

var is_overlap : bool = false
@rpc("authority", "call_local", "reliable")
func _advance():
	turn_tracker.advance()
	server_obj_data.clear()
	await turn_tracker.anim_complete
	if turn_tracker.phase == turn_tracker.PHASES.action:
		obj_ctrl.confirm_positions.rpc()
		if iid == 1:
			server_players_data_recieved = { 0:true, 1:true, 2:true }
			local_ui._start_round()
	elif turn_tracker.phase == turn_tracker.PHASES.move:
		server_players_data_recieved = { 0:false, 1:false, 2:false }
		var data : Dictionary = obj_ctrl.gather_move_tiles()
		_recieve_positions_server.rpc_id(1, local_player, JSON.stringify(data))
	elif iid == 1:
		is_overlap = true
		var tiles : Array = obj_ctrl.get_obj_tiles().keys()
		combat_manager.check_tiles_raw( turn_tracker.phase == turn_tracker.PHASES.melee, tiles )

var server_obj_data : Dictionary
var server_players_data_recieved : Dictionary = { 0:false, 1:false, 2:false }

@rpc("any_peer", "call_local", "reliable")
func _recieve_positions_server(p_num:int, json:String):
	if iid != 1:
		return
	var data : Dictionary = JSON.parse_string(json)
	for key:String in data.keys():
		server_obj_data[key.to_int()] = data[key]
	server_players_data_recieved[p_num] = true
	for i in 3:
		if !server_players_data_recieved[i]: return
	_recieve_positions_clients.rpc( JSON.stringify(server_obj_data) )
@rpc("authority", "call_local", "reliable")
func _recieve_positions_clients(json:String):
	obj_ctrl._on_server_positions( JSON.parse_string(json) )

func _client_on_complete():
	_server_on_data_confirmation.rpc_id(1, local_player)
@rpc("any_peer", "call_local", "reliable")
func _server_on_data_confirmation(p_num:int):
	if iid != 1:
		return
	server_players_data_recieved[p_num] = false
	for i in 3:
		if server_players_data_recieved[i]:
			return
	if turn_tracker.phase == turn_tracker.PHASES.move:
		obj_ctrl.do_local_sale.rpc()
	if turn_tracker.phase != turn_tracker.PHASES.melee or !is_overlap:
		_advance.rpc()
		return
