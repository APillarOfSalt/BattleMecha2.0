extends MarginContainer


@onready var obj_ctrl : Object_Controller = $map/obj_controller
@onready var turn_tracker : Turn_Tracker = $main_text
@onready var combat_manager : Combat_Manager = $manager
@onready var combat_display : Combat_Display = $manager/display
@onready var local_cursor : Map_Cursor = $map/map_cursor
@onready var player_ui_cont : Container = $manager/players
@onready var map : TileMap = $map
var map_tileset : TileSet = preload("res://main_map_tileset.tres")

var iid : int:
	get: return Global.server_controller.instance_id
var local_player : int = 0:
	get: return iid-1


func _on_local_complete():
	get_parent()._start_next()

@rpc("authority", "call_local", "reliable")
func spawn_unit(unit_id:int, p_num:int):
	pass









#func _ready():
	#map._refresh()
	#map.recolor()
	#if iid == 1:
		#await get_tree().create_timer(0.5).timeout
		#for p_num in Global.player_info_by_num.keys():
			#var p_data : Player_Data = Global.player_info_by_num[p_num]
			#spawn_units[p_data.peer_id] = p_data.team.starting_units
			#create_ui.rpc(p_num, p_data.peer_id)
		#await get_tree().create_timer(0.01).timeout
		#do_starting_spawn()
#var spawn_units : Dictionary = {} #player_num:int : [unit_id:int, x3]

#@rpc("any_peer", "call_local", "reliable")
#func do_starting_spawn():
	#if spawn_units.keys().size() == 0:
		#return
	#finish_setup.rpc()
	#var peer_id : int = spawn_units.keys()[0]
	#var unit_id : int = spawn_units[peer_id].pop_front()
	#var sz : int = spawn_units[peer_id].size()
	#if sz == 0:
		#spawn_units.erase(peer_id)
	#do_start_spawn.rpc_id(peer_id, unit_id, 2 - sz)

#@rpc("authority", "call_local", "reliable")
#func do_start_spawn(unit_id:int, r_index:int):
	#obj_ctrl.local_unit_spawn( unit_id, r_index )
	#do_starting_spawn.rpc_id(1)


#func _on_local_complete():
	#if local_player < 2:
		#var peer_id : int = Global.player_info_by_num[local_player+1].peer_id
		#player_uis[local_player+1]._start_round.rpc_id(peer_id)

#
#var is_overlap : bool = false
#@rpc("authority", "call_local", "reliable")
#func _advance():
	#turn_tracker.advance()
	#server_obj_data.clear()
	#await turn_tracker.anim_complete
	#if turn_tracker.phase == turn_tracker.PHASES.action:
		#obj_ctrl.confirm_positions.rpc()
		#if iid == 1:
			#server_players_data_recieved = { 0:true, 1:true, 2:true }
			#local_ui._start_round()
	#elif turn_tracker.phase == turn_tracker.PHASES.move:
		#server_players_data_recieved = { 0:false, 1:false, 2:false }
		#var data : Dictionary = obj_ctrl.gather_move_tiles()
		#_recieve_positions_server.rpc_id(1, local_player, JSON.stringify(data))
	#elif iid == 1:
		#is_overlap = true
		#var tiles : Array = obj_ctrl.get_obj_tiles().keys()
		#combat_manager.check_tiles_raw( turn_tracker.phase == turn_tracker.PHASES.melee, tiles )
#
#var server_obj_data : Dictionary
#var server_players_data_recieved : Dictionary = { 0:false, 1:false, 2:false }
#
#@rpc("any_peer", "call_local", "reliable")
#func _recieve_positions_server(p_num:int, json:String):
	#if iid != 1:
		#return
	
