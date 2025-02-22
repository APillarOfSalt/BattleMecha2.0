extends Control

signal finished()

var is_host : bool:
	get: return get_parent().is_host()
var player_num : int:
	get: return get_parent().get_player_num()

@export var map : TileMap = null
@export var obj_ctrl : Object_Controller = null
@onready var sniffer : Node = $combat_sniffer
@onready var queue : Combat_Display = $v/combat_queue
@onready var turn_tracker : Turn_Tracker = $turn_tracker
var phase : bool: #false:melee ; true:ranged
	get: return turn_tracker.phase == turn_tracker.PHASES.ranged
var last_was_overlap : bool = false

@rpc("authority", "call_local", "reliable")
func rpc_clear(do4:bool=false):
	map.clear_layer(3)
	if do4:
		map.clear_layer(4)

func _setup():
	sniffer.overlap_tiles.clear()
	sniffer.attacks.clear()
	rpc_clear.rpc()
	var objs : Array[Map_Object] = obj_ctrl.get_all_combat_objs()
	sniffer.setup(objs)
	print("start sniff")



#var overlap_tiles : Array[Vector3i]
#attacks[from_vec3i][obj.id][wep.id][to_vec3i] = obj_ids
func _on_combat_sniffer_on_search_complete():
	print("end sniff- Over:",sniffer.overlap_tiles,", Atks:", sniffer.attacks)
	sniffer.overlap_tiles
	last_was_overlap = bool( sniffer.overlap_tiles.size() )
	if last_was_overlap:
		_do_overlap_atks()
	elif sniffer.attacks.keys().size():
		_do_atks()
	else:
		print("no combat, advancing...")
		rpc_clear.rpc()
		get_parent()._advance.rpc()
		return
	await get_tree().create_timer(0.1).timeout
	queue._play.rpc()

func _do_overlap_atks():
	for overlap_cube:Vector3i in sniffer.overlap_tiles:
		queue.create_combat_at(overlap_cube)
		await get_tree().create_timer(0.01).timeout
func _do_atks():
	for tile:Vector2i in sniffer.attacks.keys():
		for atk_id:int in sniffer.attacks[tile].keys():
			for wep_id:int in sniffer.attacks[tile][atk_id].keys():
				var def_ids : Array = []
				for to_cube:Vector3i in sniffer.attacks[tile][atk_id][wep_id].keys():
					def_ids.append_array( sniffer.attacks[tile][atk_id][wep_id][to_cube] )
				print("creating combat-> from:",atk_id,", at:",tile,"with:",wep_id,
					"\n to:",def_ids)
				queue.create_atk_node.rpc(atk_id, wep_id, def_ids)
				await get_tree().create_timer(0.01).timeout



func _on_combat_queue_attacks_complete():
	print("attack_queue finished playing : ", player_num)
	finished.emit()
