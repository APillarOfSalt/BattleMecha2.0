extends Node

signal on_search_complete()

@onready var map : TileMap = get_parent().map
@onready var obj_ctrl : Object_Controller = get_parent().obj_ctrl
@onready var turn_tracker : Turn_Tracker = get_parent().turn_tracker

func _setup(tile_arr:Array):
	check_tile_arr = tile_arr
	check_tile_arr.sort_custom(map.sort_vecs)
	#print("search_start")
	do_process = do_next_check()
	map.clear_layer(3)


var overlap_tiles : Array[Vector3i] = []
var attacks : Dictionary = {} #obj_id:
func found_attack(objs:Array[Map_Object]):
	if objs.size() == 0:
		return
	var obj_ids : Array[int] = []
	for obj:Map_Object in objs:
		obj_ids.append(obj.id)
	var oddq : Vector2i = map.cubic_to_oddq(current_check_tile)
	map.set_cell(4, oddq, 0, Vector2i(1,0))
	oddq = map.cubic_to_oddq(current_wep_tile+current_check_tile)
	map.set_cell(4, oddq, 0, Vector2i(1,0), 9)
	if !current_check_tile in attacks.keys():
		attacks[current_check_tile] = {}
	if !current_check_obj.id in attacks[current_check_tile].keys():
		attacks[current_check_tile][current_check_obj.id] = {}
	if !current_check_wep.id in attacks[current_check_tile][current_check_obj.id].keys():
		attacks[current_check_tile][current_check_obj.id][current_check_wep.id] = {}
	attacks[current_check_tile][current_check_obj.id][current_check_wep.id][current_wep_tile] = obj_ids

var check_tile_arr : Array
@export var current_check_tile : Vector3i = Vector3i(1,1,1):
	set(tile):
		current_check_tile = tile
		if tile != Vector3i(1,1,1):
			var oddq : Vector2i = map.cubic_to_oddq(tile)
			map.set_cell(3, oddq, 0, Vector2i(1,0))
			current_tile_obj_arr = obj_ctrl.get_objs_at(tile)
			if get_parent().is_overlap:
				if current_tile_obj_arr.size() > 1:
					map.set_cell(4, oddq, 0, Vector2i(1,0), 9)
					overlap_tiles.append(tile)
				current_tile_obj_arr.clear()
var current_tile_obj_arr : Array[Map_Object]

var current_check_obj : Map_Object = null:
	set(obj):
		current_check_obj = obj
		if obj != null:
			for wep_id:int in obj.unit.cubic_weapons.keys():
				var wep_mod : Module_Data.Weapon_Data = obj.unit.unit_data.get_module(wep_id)
				if wep_mod.subtype == "Melee" and turn_tracker.phase == turn_tracker.PHASES.melee:
					current_check_obj_weps.append(wep_mod)
				elif wep_mod.subtype != "Melee" and turn_tracker.phase == turn_tracker.PHASES.ranged:
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
		if tile == Vector3i(1,1,1):
			return
		map.set_cell(3, map.cubic_to_oddq(tile), 0, Vector2i(1,0))
		if current_check_obj == null:
			return
		var defenders : Array[Map_Object] = []
		var objs : Array = obj_ctrl.get_objs_at(tile)
		for obj in objs:
			if obj.unit.player_num != current_check_obj.unit.player_num:
				defenders.append(obj)
		if defenders.size():
			found_attack(defenders)
		print(objs, defenders)

var do_process : bool = false
@export var tick_speed_msec : int = 100
var tick : int = -1
func _process(delta):
	if do_process and (Input.is_action_pressed("rmb") or Input.is_action_just_pressed("lmb")):
		if Time.get_ticks_msec() - tick < tick_speed_msec:
			return
		tick = Time.get_ticks_msec()
		if !do_next_check():
			do_process = false
			on_search_complete.emit()

func do_next_check():
	if current_wep_tiles.size():
		current_wep_tile = current_wep_tiles.pop_front() + current_check_tile
		print("search_wep_tile:", current_wep_tile)
		return true
	if current_check_obj_weps.size():
		current_check_wep = current_check_obj_weps.pop_front()
		print("search_wep:", current_check_wep.name)
		return true
	elif current_tile_obj_arr.size():
		current_check_obj = current_tile_obj_arr.pop_front()
		print("search_obj:", current_check_obj.unit.unit_data.name)
		return true
	elif check_tile_arr.size():
		current_check_tile = check_tile_arr.pop_front()
		print("search_tile:", current_check_tile)
		return true
	current_check_tile = Vector3i(1,1,1)
	current_check_obj = null
	current_check_wep = null
	current_wep_tile = Vector3i(1,1,1)
	#print("search_end")
	return false
