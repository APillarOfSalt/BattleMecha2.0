extends Node2D
class_name Object_Controller

signal move_phase_finished()

@onready var map : TileMap = get_parent()
var local_player : int:
	get: return get_parent().local_player
const map_obj_scene : PackedScene = preload("res://map_object.tscn")

func obj_id_exists(obj_id:int)->bool:
	return obj_id in all_objects.keys()
var all_objects : Dictionary = {} #obj_id:int : Map_Object
func get_all_combat_objs()->Array[Map_Object]:
	var objs : Array[Map_Object] = []
	for obj in all_objects.values():
		if obj.unit.state != obj.unit.STATES.roller:
			objs.append(obj)
	return objs

var local_objs : Array[Map_Object]
var remote_objs : Array[Map_Object]
func is_obj_local(obj:Map_Object)->bool:
	return is_obj_id_local(obj.id)
func is_obj_id_local(obj_id:int)->bool:
	for obj:Map_Object in local_objs:
		if obj.id == obj_id:
			return true
	return false
func get_objs_arr_for_id(obj_id:int)->Array[Map_Object]:
	return get_objs_arr(is_obj_id_local(obj_id))
func get_objs_arr(is_local:bool)->Array[Map_Object]:
	return [remote_objs, local_objs][int(is_local)]

func start_round():
	print("starting round", local_player)
	for i in 3:
		var cube : Vector3i = map.oddq_to_cubic( map.local_rollers[i] )
		var obj : Map_Object = get_first_obj_at( cube )
		if obj == null:
			local_unit_spawn(-1, i)
			await get_tree().create_timer(0.1).timeout

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
	for obj in all_objects.values():
		obj.confirm_move()
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
	is_moving = move_time_msec

@rpc("any_peer", "call_local", "reliable")
func do_local_sale():
	print("RPC:do_local_sale()):[]\n",
		"from:",multiplayer.get_remote_sender_id(),", p:",Global.server_controller.instance_id,
		", on:",multiplayer.get_unique_id(),"@:",Time.get_ticks_msec())
	var sell : Array[Unit_Node] = []
	for obj in local_objs:
		var map_at : int = map.map_at(obj.to_pos)
		if map_at == map.AT_VALS.trash:
			print(obj.to_pos)
			sell.append(obj.unit)
	for unit:Unit_Node in sell:
		unit._sell_me()
func _local_obj_removal(unit:Unit_Node, sale:bool=false):
	obj_removal.rpc(unit.map_obj.id, sale)
@rpc("any_peer", "call_local", "reliable")
func obj_removal(obj_id:int, sale:bool=false):
	print("RPC:obj_removal(obj_id:int, sale:bool=false):[",obj_id,",",sale,"]\n",
		"from:",multiplayer.get_remote_sender_id(),", on:",multiplayer.get_unique_id(),
		"p:",Global.server_controller.instance_id,"@:",Time.get_ticks_msec())
	var arr : Array = get_objs_arr_for_id(obj_id)
	var removal : Array = []
	for i in arr.size():
		if arr[i].id == obj_id:
			arr.remove_at(i)
			break
	all_objects[obj_id].do_free(sale)
	all_objects.erase(obj_id)


func local_unit_spawn(unit_id:int,r_index:int):
	var obj_cube : Vector3i = map.oddq_to_cubic(map.local_rollers[r_index])
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
















func get_obj_tiles()->Dictionary:
	var obj_tiles : Dictionary = {} #tile:Vector3i : [obj_id:int, etc...]
	for obj:Map_Object in all_objects.values():
		if obj.unit.state == Unit_Node.STATES.roller:
			continue
		if !obj.to_pos in obj_tiles.keys():
			obj_tiles[obj.to_pos] = []
		obj_tiles[obj.to_pos].append(obj.id)
	return obj_tiles

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




@export_range(250,2000) var move_time_msec : int = 1200
var is_moving : int = 0:
	set(val):
		if val <= 0:
			is_moving = 0
			_finish_phase()
		else:
			is_moving = val
func _finish_phase():
	move_phase_finished.emit()
func _physics_process(delta):
	if is_moving:
		is_moving -= floor(delta * 1000.0)
		var ratio : float = float(is_moving)/float(move_time_msec)
		for obj:Map_Object in all_objects.values():
			obj.tween_pos(1.0-ratio)


#false:melee, true:ranged
func gather_attacks(melee_ranged:bool)->Dictionary:
	var attacks : Dictionary = {} #atk_obj_id:int : { weapon_module_id:int : [def_obj_id:int, etc...] }
	var obj_tiles : Dictionary = get_obj_tiles()
	for obj:Map_Object in all_objects.values():
		for wep_id:int in obj.unit.cubic_weapons.keys():
			var subtype : String = obj.unit.unit_data.get_module(wep_id).subtype
			if subtype != "Melee" and !melee_ranged:
				continue
			elif subtype == "Melee" and melee_ranged:
				continue
			for cube:Vector3i in obj.unit.cubic_weapons[wep_id]:
				if cube in obj_tiles.keys():
					if !obj.id in attacks.keys():
						attacks[obj.id] = {}
					if !wep_id in attacks[obj.id].keys():
						attacks[obj.id][wep_id] = []
					for def_id:int in obj_tiles[cube]:
						attacks[obj.id][wep_id].append(def_id)
	return attacks

