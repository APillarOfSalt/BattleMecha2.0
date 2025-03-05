extends Control

#signal finished()

var is_host : bool:
	get: return get_parent().is_host()
var player_num : int:
	get: return get_parent().get_player_num()

@export var map : TileMap = null
@export var obj_ctrl : Object_Controller = null
#@export var sniffer : Combat_Sniffer = null
@onready var queue : Combat_Display = $h/right/m/atks/combat_queue
@onready var turn_tracker : Turn_Tracker = $h/left/turn_tracker
var phase : bool: #false:melee ; true:ranged
	get: return turn_tracker.phase == turn_tracker.PHASES.ranged
var last_was_overlap : bool = false

@rpc("authority", "call_local", "reliable")
func rpc_clear(do4:bool=false):
	map.clear_layer(3)
	if do4:
		map.clear_layer(4)

var prio_step : int = 0
func _on_combat_queue_attacks_complete():
	print("attack_queue finished playing : ", player_num)
	obj_ctrl.do_move()

func _setup():
	if !is_host:
		return
	prio_step += 1
	if prio_step > obj_ctrl.get_highest_wep_prio():
		prio_step = 0
		get_parent()._advance.rpc()
		return
	rpc_clear.rpc()
	print("gathering overlaps, step:", prio_step)
	var overlaps : Array[Array] = obj_ctrl.gather_all_overlaps() #[ [obj:Map_Object,etc...], [overlap2]... ]
	last_was_overlap = overlaps.size()
	if last_was_overlap:
		for combat:Array in overlaps:
			queue.create_combat_with(combat)
			await Global.create_wait_timer()
	else:
		print("no overlaps found")
		var attackers : Dictionary = obj_ctrl.gather_attacks(phase, prio_step) #atk_obj_id:int : { weapon_module_id:int : [def_obj_id:int, etc...] }
		print("number of attacks found :",attackers.size())
		queue_from_data(attackers)
		var healers : Dictionary = obj_ctrl.gather_heals(phase, prio_step)
		print("number of heals found :",healers.size())
		queue_from_data(healers)
	if queue.attacks.size():
		queue._play.rpc()
	elif prio_step:
		_setup()

func queue_from_data(data:Dictionary):
	for atk_id:int in data.keys():
		for wep_id:int in data[atk_id].keys():
			var def_ids : Array = data[atk_id][wep_id]
			print("creating combat-> from:",atk_id,"with:",wep_id,
				"\n to:",def_ids)
			queue.create_atk_node.rpc(atk_id, wep_id, def_ids)
			await Global.create_wait_timer()


#var overlap_tiles : Array[Vector3i]
#attacks[from_vec3i][obj.id][wep.id][to_vec3i] = obj_ids
#func _on_sniffer_on_search_complete():
	#print("end sniff- Over:",sniffer.overlap_tiles,", Atks:", sniffer.attacks)
	#last_was_overlap = bool( sniffer.overlap_tiles.size() )
	#if last_was_overlap:
		#for overlap_cube:Vector3i in sniffer.overlap_tiles:
			#queue.create_combat_at(overlap_cube)
			#await Global.create_wait_timer()
	#elif sniffer.attacks.keys().size():
		#_do_atks()
	#else:
		#print('advance @_on_combat_sniffer_on_search_complete()-> "no combat, advancing"')
		#rpc_clear.rpc()
		#get_parent()._advance.rpc()
		#return
	#await Global.create_wait_timer(0.5)
	#queue._play.rpc()
#
#func _do_atks():
	#for from_cube:Vector3i in sniffer.attacks.keys():
		#for atk_id:int in sniffer.attacks[from_cube].keys():
			#for wep_id:int in sniffer.attacks[from_cube][atk_id].keys():
				#var def_ids : Array = []
				#for to_cube:Vector3i in sniffer.attacks[from_cube][atk_id][wep_id].keys():
					#def_ids.append_array( sniffer.attacks[from_cube][atk_id][wep_id][to_cube] )
				#print("creating combat-> from:",atk_id,", at:",from_cube,"with:",wep_id,
					#"\n to:",def_ids)
				#queue.create_atk_node.rpc(atk_id, wep_id, def_ids)
				#await Global.create_wait_timer()





