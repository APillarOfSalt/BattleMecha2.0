extends Node2D

class_name Object_Controller

@onready var map : TileMap = get_parent()
var local_player : int:
	get: return map.local_player
const map_obj_scene : PackedScene = preload("res://map_object.tscn")
var obj_id_count : int = 0


var all_objects : Dictionary = {} #obj_id:int : Map_Object
var local_objs : Array[Map_Object]
var remote_objs : Array[Map_Object]

@rpc("any_peer", "call_local", "reliable")
func confirm_positions():
	for obj in all_objects.values():
		obj.confirm_move()

@rpc("authority", "call_local", "reliable")
func do_local_sale():
	var sell_ids : Array[int] = []
	for obj in local_objs:
		var map_at : int = map.map_at(obj.to_pos)
		if map_at == map.AT_VALS.trash:
			sell_ids.append(obj.id)
	for id in sell_ids:
		obj_removal.rpc(id, true)
	

@rpc("any_peer", "call_local", "reliable")
func obj_removal(obj_id:int, sale:bool=false):
	all_objects[obj_id].do_free(sale)
	all_objects.erase(obj_id)
	for arr in [local_objs, remote_objs]:
		for i in arr.size():
			if arr[i].id == obj_id:
				arr.remove_at(i)
				return

func local_unit_spawn(unit_id:int,r_index:int):
	var obj_id : int = obj_id_count
	var obj_cube : Vector3i = map.oddq_to_cubic(map.local_rollers[r_index])
	var obj_name : String = str(obj_id,"_",unit_id)
	var obj : Map_Object = map_obj_scene.instantiate()
	obj_id_count += 1
	add_child(obj)
	all_objects[obj_id] = obj
	local_objs.append(obj)
	obj.setup(obj_id, obj_cube, local_player, unit_id, true)
	obj.unit.name = obj_name
	_remote_unit_spawn.rpc(obj_id, obj_cube, local_player, obj.unit.unit_data.id, obj_name)

@rpc("any_peer", "call_remote", "reliable")
func _remote_unit_spawn(obj_id:int,cube:Vector3i,p_num:int,unit_id:int, unit_name:String):
	var obj : Map_Object = map_obj_scene.instantiate()
	if obj_id != obj_id_count:
		print("oop")
	obj_id_count += 1
	add_child(obj)
	all_objects[obj_id] = obj
	remote_objs.append(obj)
	obj.setup(obj_id, cube, p_num, unit_id, false)
	obj.unit.name = unit_name

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
func get_occupied_tiles(tiles:Array[Vector3i])->Array[Vector3i]:
	var occupied_tiles : Array[Vector3i] = []
	for obj:Map_Object in all_objects.values():
		if obj.cubic in tiles:
			occupied_tiles.append(obj.cubic)
		if obj.cubic != obj.to_pos and obj.to_pos in tiles:
			occupied_tiles.append(obj.to_pos)
	return occupied_tiles


func gather_move_tiles()->Dictionary:
	var data : Dictionary = {}
	for obj in local_objs:
		if obj.cubic == obj.to_pos:
			continue
		data[obj.id] = {"cube":obj.cubic, "to":obj.to_pos}
	return data

func _on_server_positions(data:Dictionary):
	for key:String in data.keys():
		var obj_id : int = key.to_int()
		if !obj_id in all_objects:
			print("oop")
			return
		all_objects[obj_id].cubic = Global.vec3_from_json(data[key].cube)
		all_objects[obj_id].to_pos = Global.vec3_from_json(data[key].to)
	is_moving = move_time_msec

@export_range(250,2000) var move_time_msec : int = 1200
var is_moving : int = 0:
	set(val):
		if val <= 0:
			is_moving = 0
			_finish_phase()
		else:
			is_moving = val
func _finish_phase():
	get_parent().get_parent()._client_on_complete()
func _physics_process(delta):
	if is_moving:
		is_moving -= floor(delta * 1000.0)
		var ratio : float = float(is_moving)/float(move_time_msec)
		for obj:Map_Object in all_objects.values():
			obj.tween_pos(1.0-ratio)


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

##false:melee, true:ranged
#func gather_attack_tiles(melee_ranged:bool)->Array[Vector3i]:
	#var obj_tiles : Dictionary = get_obj_tiles()
	#var attack_tiles : Array[Vector3i] = []
	#if melee_ranged:
		#pass
	#else:
		#pass


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

