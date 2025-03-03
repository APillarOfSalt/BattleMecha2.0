extends Node2D
class_name Object_Controller

signal out_of_units()
signal move_phase_finished()
signal combat_move_finished()

@export var turn_tracker : Turn_Tracker = null

@onready var map : TileMap = get_parent()
var local_player : int:
	get: return get_parent().local_player
const map_obj_scene : PackedScene = preload("res://map_object.tscn")

func start_round():
	print("starting round; p_num:", local_player)
	for i in 3:
		if !local_unit_spawn(-1, i):
			out_of_units.emit()
			return
		await Global.create_wait_timer(0.5)

@rpc("authority", "call_local", "reliable")
func tuck_rollers():
	print("tucking rollers; p_num:", local_player)
	for obj in all_objects.values():
		obj.confirm_move()
	var removal : Array[Map_Object] = []
	for obj in local_objs:
		if map.is_roller(obj.to_pos):
			removal.append(obj)
	for obj in removal:
		_local_obj_removal(obj.unit, 0)
		await Global.create_wait_timer(0.5)


#false: start of turn, true: move phase
@rpc("any_peer", "call_local", "reliable")
func confirm_positions(start_move:bool)->Dictionary:
	print("RPC:confirm_positions(start_move:bool):[",start_move,"]\n",
		"from:",multiplayer.get_remote_sender_id(),
		", p:",Global.server_controller.instance_id,
		", on:",multiplayer.get_unique_id(),"\n","@:",Time.get_ticks_msec())
	if start_move: #move phase
		var data : Dictionary = {}
		for obj in local_objs:
			if obj.cubic == obj.to_pos:
				continue
			data[obj.id] = {"cube":obj.cubic, "to":obj.to_pos}
		return data
	#start phase
	return {}

func _on_server_positions(data:Dictionary):
	print(all_objects)
	for key in data.keys():
		var p_num : int
		if key is String:
			p_num = key.to_int()
		elif key is int:
			p_num = key
		for key2 in data[key].keys():
			var obj_id : int
			if key2 is String:
				obj_id = key2.to_int()
			elif key2 is int:
				obj_id = key2
			if !obj_id in all_objects:
				print("object_not_found:", obj_id, ", on:", local_player)
				return
			if key is String:
				all_objects[obj_id].cubic = Global.vec3_from_json(data[key][key2].cube)
			elif key is int:
				all_objects[obj_id].cubic = data[key][key2].cube
			if key2 is String:
				all_objects[obj_id].to_pos = Global.vec3_from_json(data[key][key2].to)
			elif key2 is int:
				all_objects[obj_id].to_pos = data[key][key2].to
	do_move()

@rpc("any_peer", "call_local", "reliable")
func do_local_sale():
	print("RPC:do_local_sale()):[]\n",
		"from:",multiplayer.get_remote_sender_id(),", p:",Global.server_controller.instance_id,
		", on:",multiplayer.get_unique_id(),"@:",Time.get_ticks_msec())
	var sell : Array[Map_Object] = []
	for obj in local_objs:
		if map.is_trash(obj.to_pos):
			sell.append(obj)
	for obj:Map_Object in sell:
		obj.do_free(1)
func _local_obj_removal(unit:Unit_Node, death_return_sale:int=-1):
	unit.is_now_dead.disconnect(_local_obj_removal)
	var obj_id : int = unit.map_obj.id
	obj_removal(obj_id, death_return_sale, true)
	obj_removal.rpc(obj_id, death_return_sale)
@rpc("any_peer", "call_remote", "reliable")
func obj_removal(obj_id:int, death_return_sale:int=-1, local:bool=false):
	print("RPC:obj_removal(obj_id:int, sale:bool=false):[",obj_id,",",death_return_sale,"]\n",
		"from:",multiplayer.get_remote_sender_id(),", on:",multiplayer.get_unique_id(),
		"p:",Global.server_controller.instance_id,"@:",Time.get_ticks_msec())
	if local:
		local_obj_removal(obj_id)
	else:
		remote_obj_removal(obj_id)
	if obj_id in all_objects.keys():
		if all_objects[obj_id] != null:
			if !all_objects[obj_id].dying:
				all_objects[obj_id].do_free(death_return_sale)
		all_objects.erase(obj_id)
func local_obj_removal(obj_id:int):
	for i in local_objs.size():
		if local_objs[i] == null:
			local_objs.remove_at(i)
			break
		if local_objs[i].id == obj_id:
			local_objs.remove_at(i)
			break
func remote_obj_removal(obj_id:int):
	for i in remote_objs.size():
		if remote_objs[i] == null:
			remote_objs.remove_at(i)
			break
		if remote_objs[i].id == obj_id:
			remote_objs.remove_at(i)
			break

func local_unit_spawn(unit_id:int,r_index:int)->bool:
	var obj_cube : Vector3i = map.oddq_to_cubic(map.local_rollers[r_index])
	if Global.player_info_by_num[local_player].ui.deck.has_ran_out():
		return false
	var obj : Map_Object = map_obj_scene.instantiate()
	if unit_id == -1:
		unit_id = Global.player_info_by_num[local_player].ui.deck.rand_unit_id()
	add_child(obj)
	var count : int = 0
	var obj_id = (local_player * 1000) + (unit_id*10) + count
	while obj_id_exists(obj_id):
		count += 1
		obj_id = (local_player * 1000) + (unit_id*10) + count
	obj.setup(obj_id, obj_cube, local_player, unit_id, true)
	all_objects[obj.id] = obj
	local_objs.append(obj)
	obj.unit.name = str(obj.unit.unit_data.name)
	print("spawning unit from:", local_player, ", id:",unit_id,", obj:",obj.id)
	obj.unit.is_now_dead.connect(_local_obj_removal)
	_remote_unit_spawn.rpc(obj_id, obj_cube, local_player, obj.unit.unit_data.id)
	print("local OBJ:",obj.name,"UNIT:",obj.unit.name)
	return true

func obj_id_exists(obj_id:int)->bool:
	return obj_id in all_objects.keys()

@rpc("any_peer", "call_remote", "reliable")
func _remote_unit_spawn(obj_id:int, cube:Vector3i,p_num:int,unit_id:int):
	print("RPC:_remote_unit_spawn(cube:Vector3i,p_num:int,unit_id:int):[",cube,",",p_num,",",unit_id,"]\n",
		"from:",multiplayer.get_remote_sender_id(),
		", p:",Global.server_controller.instance_id,
		", on:",multiplayer.get_unique_id(),"@:",Time.get_ticks_msec())
	var obj : Map_Object = map_obj_scene.instantiate()
	add_child(obj)
	all_objects[obj_id] = obj
	remote_objs.append(obj)
	obj.setup(obj_id, cube, p_num, unit_id, false)
	print("remote OBJ:",obj.name,"UNIT:",obj.unit.name)


var signal_count : int = 0
func check_unit_deaths():
	signal_count = 0
	for obj:Map_Object in local_objs:
		if obj.unit.stats.hp <= 0:
			obj.play_death().connect(_on_unit_death)
			signal_count += 1
func _on_unit_death():
	signal_count -= 1
	if signal_count == 0:
		confirm_push()
		combat_move_finished.emit()

func confirm_push():
	for obj:Map_Object in all_objects.values():
		obj.confirm_combat_move()

func do_move():
	is_moving = move_time_msec
	for obj:Map_Object in all_objects.values():
		obj.start_tween()
	if turn_tracker.phase != turn_tracker.PHASES.move:
		check_unit_deaths()
#@export_range(250,2000) var move_time_msec : int = 1200
@onready var move_time_msec : int = Global.get_wait_msec(3.0)
var is_moving : int = 0:
	set(val):
		if val <= 0:
			is_moving = 0
			_finish_phase()
		else:
			is_moving = val
func _finish_phase():
	if turn_tracker.phase == turn_tracker.PHASES.move:
		move_phase_finished.emit()
	elif signal_count == 0:
		confirm_push()
		combat_move_finished.emit()
func _physics_process(delta):
	if is_moving:
		is_moving -= floor(delta * 1000.0)
		var ratio : float = float(is_moving)/float(move_time_msec)
		var to_remove : Array = []
		for obj_id:int in all_objects.keys():
			var obj = all_objects[obj_id]
			if obj == null:
				to_remove.append(obj_id)
			else:
				obj.tween_pos(1.0 - ratio, turn_tracker.phase == turn_tracker.PHASES.move)
		for obj_id:int in to_remove:
			all_objects.erase(obj_id)

#called by combat_manager
func gather_all_overlaps()->Array[Array]: #[ [obj:Map_Object,etc...], [overlap2]... ]
	var tile_objs : Dictionary = {}
	for obj in all_objects.values():
		if !obj.to_pos in tile_objs.keys():
			tile_objs[obj.to_pos] = []
		tile_objs[obj.to_pos].append(obj)
	var overlaps : Array[Array]
	for tile in tile_objs:
		if tile_objs[tile].size() > 1:
			overlaps.append(tile_objs[tile])
	return overlaps

func get_highest_wep_prio()->int:
	var highest : int = 0
	for obj in all_objects.values():
		if !obj.get_state_is_roller():
			highest = max( highest, obj.get_highest_wep_prio() )
	return highest

#false:melee, true:ranged
func gather_attacks(melee_ranged:bool, prio_step:int)->Dictionary:
	var attacks : Dictionary = {} #atk_obj_id:int : { weapon_module_id:int : [def_obj_id:int, etc...] }
	var obj_tiles : Dictionary = get_obj_tiles()
	for obj:Map_Object in all_objects.values():
		if obj.unit.state == Unit_Node.STATES.roller:
			continue
		var wep_tiles : Dictionary = obj.get_weapon_tiles(true)
		for wep_id:int in wep_tiles.keys():
			var weapon : Module_Data.Weapon_Data = obj.unit.unit_data.get_module(wep_id)
			if weapon.priority != prio_step:
				continue
			var subtype : String = weapon.subtype
			if subtype != "Melee" and !melee_ranged:
				continue
			elif subtype == "Melee" and melee_ranged:
				continue
			for cube:Vector3i in wep_tiles[wep_id]:
				if cube in obj_tiles.keys():
					for def_id:int in obj_tiles[cube]:
						if all_objects[def_id].player_num != obj.player_num:
							if !obj.id in attacks.keys():
								attacks[obj.id] = {}
							if !wep_id in attacks[obj.id].keys():
								attacks[obj.id][wep_id] = []
							attacks[obj.id][wep_id].append(def_id)
	return attacks

func get_obj_tiles()->Dictionary:
	var obj_tiles : Dictionary = {} #tile:Vector3i : [obj_id:int, etc...]
	for obj:Map_Object in all_objects.values():
		if obj.unit.state == Unit_Node.STATES.roller:
			continue
		if !obj.to_pos in obj_tiles.keys():
			obj_tiles[obj.to_pos] = []
		obj_tiles[obj.to_pos].append(obj.id)
	return obj_tiles

func get_all_local_roller_objs()->Array[Map_Object]:
	var objs : Array[Map_Object] = []
	for obj in local_objs:
		if obj.unit.state == obj.unit.STATES.roller:
			objs.append(obj)
	return objs

func get_all_roller_objs()->Array[Map_Object]:
	var objs : Array[Map_Object] = []
	for obj in all_objects.values():
		if obj.unit.state == obj.unit.STATES.roller:
			objs.append(obj)
	return objs








#func get_all_combat_objs()->Array[Map_Object]:
	#var objs : Array[Map_Object] = []
	#for obj in all_objects.values():
		#if obj.unit.state != obj.unit.STATES.roller:
			#objs.append(obj)
	#return objs



var all_objects : Dictionary = {} #obj_id:int : Map_Object
var local_objs : Array[Map_Object]
var remote_objs : Array[Map_Object]
#func is_obj_local(obj:Map_Object)->bool:
	#return is_obj_id_local(obj.id)
func is_obj_id_local(obj_id:int)->bool:
	for obj:Map_Object in local_objs:
		if obj.id == obj_id:
			return true
	return false
func get_objs_arr_for_id(obj_id:int)->Array[Map_Object]:
	return get_objs_arr(is_obj_id_local(obj_id))
func get_objs_arr(is_local:bool)->Array[Map_Object]:
	return [remote_objs, local_objs][int(is_local)]


func gather_melee_overlap()->Array[Vector3i]:
	var obj_tiles : Dictionary = get_obj_tiles()
	var overlap_melee_tiles : Array[Vector3i] = []
	for cube:Vector3i in obj_tiles.keys():
		if obj_tiles[cube].size() > 1:
			overlap_melee_tiles.append(cube)
	return overlap_melee_tiles


func get_occupied_tiles(tiles:Array[Vector3i])->Array[Vector3i]:
	var occupied_tiles : Array[Vector3i] = []
	for obj:Map_Object in all_objects.values():
		if obj.cubic in tiles:
			occupied_tiles.append(obj.cubic)
		if obj.cubic != obj.to_pos and obj.to_pos in tiles:
			occupied_tiles.append(obj.to_pos)
	return occupied_tiles


func get_obj_id_by_node(node:Node)->int:
	for obj in all_objects.values():
		if node is Map_Object:
			if obj == node:
				return obj.id
		elif node is Unit_Node:
			if obj.unit == node:
				return obj.id
	return -1
func get_obj_by_node(node:Node)->Map_Object:
	for obj in all_objects.values():
		if node is Map_Object:
			if obj == node:
				return obj
		elif node is Unit_Node:
			if obj.unit == node:
				return obj
	return null
func get_first_obj_at(cubic:Vector3i)->Map_Object:
	var objs : Array[Map_Object] = get_objs_at(cubic)
	if objs.size():
		return objs.pop_front()
	return null
func get_objs_at(cubic:Vector3i)->Array[Map_Object]:
	var objs: Array[Map_Object] = []
	for obj:Map_Object in all_objects.values():
		if obj.to_pos == cubic:
			objs.append(obj)
	return objs





