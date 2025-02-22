extends Node

signal on_search_complete()

@export var map : TileMap = null
@export var obj_ctrl : Object_Controller = null
@export var turn_tracker : Turn_Tracker = null

var overlap_tiles : Array[Vector3i] = []
func setup(objs:Array[Map_Object]):
	map.clear_layer(3)
	map.clear_layer(4)
	do_process = false
	overlap_tiles.clear()
	var by_pos : Dictionary = {} #cube:Vector3i : [obj_id:int,etc...]
	for obj:Map_Object in objs:
		var cube : Vector3i = obj.to_pos
		var oddq : Vector2i = map.cubic_to_oddq(cube)
		if !cube in by_pos.keys():
			map.clear_layer(3)
			map.set_cell(3, oddq, 0, Vector2i(1,0))
			by_pos[cube] = []
		by_pos[cube].append(obj.id)
		if by_pos[cube].size() > 1 and !cube in overlap_tiles:
			map.set_cell(4, oddq, 0, Vector2i(1,0))
			overlap_tiles.append(cube)
	map.clear_layer(3)
	if overlap_tiles.size(): #skip second search
		search_objs.clear()
		on_search_complete.emit()
	else: #do main search
		search_objs = objs
		do_process = do_next_check()


var attacks : Dictionary = {} #obj_id:int : {tile_cube:Vector3i
func found_attack(objs:Array[Map_Object]):
	if objs.size() == 0:
		return
	var obj_ids : Array[int] = []
	for obj:Map_Object in objs:
		obj_ids.append(obj.id)
	print("found attack : ", obj_ids)
	var current_check_tile = map.cubic_to_oddq(objs[0].to_pos)
	map.set_cell(4, current_check_tile, 0, Vector2i(1,0))
	current_check_tile = map.cubic_to_oddq(current_wep_tile + objs[0].to_pos)
	map.set_cell(4, current_check_tile, 0, Vector2i(1,0), 9)
	if !current_check_tile in attacks.keys():
		attacks[current_check_tile] = {}
	if !current_check_obj.id in attacks[current_check_tile].keys():
		attacks[current_check_tile][current_check_obj.id] = {}
	if !current_check_wep.id in attacks[current_check_tile][current_check_obj.id].keys():
		attacks[current_check_tile][current_check_obj.id][current_check_wep.id] = {}
	attacks[current_check_tile][current_check_obj.id][current_check_wep.id][current_wep_tile] = obj_ids


var search_objs : Array[Map_Object]
var current_check_obj : Map_Object = null:
	set(obj):
		current_check_obj = obj
		if obj != null:
			for wep_id:int in obj.unit.cubic_weapons.keys():
				var wep_mod : Module_Data.Weapon_Data = obj.unit.unit_data.get_module(wep_id)
				if wep_mod.subtype == "Melee" and turn_tracker.phase == turn_tracker.PHASES.melee:
					print(wep_mod.subtype,":", turn_tracker.phase)
					current_check_obj_weps.append(wep_mod)
				elif wep_mod.subtype != "Melee" and turn_tracker.phase == turn_tracker.PHASES.ranged:
					print(wep_mod.subtype,":", turn_tracker.phase)
					current_check_obj_weps.append(wep_mod)
var current_check_obj_weps : Array[Module_Data.Weapon_Data]
var current_check_wep : Module_Data.Weapon_Data = null:
	set(wep):
		current_check_wep = wep
		if wep != null:
			current_wep_tiles = current_check_obj.unit.cubic_weapons[wep.id].duplicate(true)

var current_wep_tiles : Array = []
@export var current_wep_tile : Vector3i = Vector3i(1,1,1):
	set(tile):
		current_wep_tile = tile
		if tile == Vector3i(1,1,1) or current_check_obj == null:
			return
		current_wep_tile += current_check_obj.to_pos
		map.set_cell(3, map.cubic_to_oddq(current_wep_tile), 0, Vector2i(1,0))
		var defenders : Array[Map_Object] = []
		var objs : Array = obj_ctrl.get_objs_at(current_wep_tile)
		for obj in objs:
			if obj.unit.state != obj.unit.STATES.roller:
				defenders.append(obj)
		if defenders.size():
			found_attack(defenders)
		#print(objs, defenders)

var do_process : bool = false
@export var tick_speed_msec : int = 100
var tick : int = -1
func _process(delta):
	if !do_process or (Time.get_ticks_msec() - tick) < tick_speed_msec:
		return
	tick = Time.get_ticks_msec()
	if !do_next_check():
		do_process = false
		on_search_complete.emit()
		map.clear_layer(3)

func do_next_check():
	if current_wep_tiles.size():
		current_wep_tile = current_wep_tiles.pop_front()
		return true
	if current_check_obj_weps.size():
		current_check_wep = current_check_obj_weps.pop_front()
		return true
	elif search_objs.size():
		current_check_obj = search_objs.pop_front()
		return true
	current_check_obj = null
	current_check_wep = null
	current_wep_tile = Vector3i(1,1,1)
	#print("search_end")
	return false
