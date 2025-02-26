extends TileMap
class_name Combat_Sniffer

signal on_search_complete()

func c2o(cube:Vector3i)->Vector2i:
	return get_parent().cubic_to_oddq(cube)
#func o2c(oddq:Vector2i)->Vector3i:
	#return get_parent().oddq_to_cubic(oddq)

@rpc("authority", "call_local", "reliable")
func rpc_clear_layer(layer:int):
	clear_layer(layer)
@rpc("authority", "call_local", "reliable")
func rpc_set_cell(layer:int, cube:Vector3i, index:int, from:int=2, alternative:int=0):
	set_cell(layer, c2o(cube), from, Vector2i(index,0), alternative)


func update_tiles(atks:Array):
	rpc_clear_layer.rpc(1)
	for nd in atks:
		var from_cube : Vector3i = nd.get_atk_cube()
		var aims : Array[Vector3i] = nd.get_aim_cubes()
		#if !aims.size(): use index 2; if aims.size(): using index 0
		var index : int = 2 * int(!aims.size()) 
		rpc_set_cell.rpc(1, from_cube, index)
		index = 1
		for to_cube:Vector3i in aims:
			rpc_set_cell.rpc(1, to_cube, index)



@export var obj_ctrl : Object_Controller = null
@export var turn_tracker : Turn_Tracker = null

var overlap_tiles : Array[Vector3i] = []
func setup(objs:Array[Map_Object]):
	rpc_clear_layer.rpc(0)
	rpc_clear_layer.rpc(1)
	do_process = false
	overlap_tiles.clear()
	var by_pos : Dictionary = {} #cube:Vector3i : [obj_id:int,etc...]
	for obj:Map_Object in objs:
		var cube : Vector3i = obj.to_pos
		if !cube in by_pos.keys(): #fill out by_pos
			by_pos[cube] = []
		by_pos[cube].append(obj.id)
		if by_pos[cube].size() > 1 and !cube in overlap_tiles: #overlap found
			rpc_set_cell.rpc(1, cube, 2)
			overlap_tiles.append(cube)
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
	rpc_set_cell.rpc(1, objs[0].to_pos, 1, 0)
	rpc_set_cell.rpc(1, current_wep_tile + objs[0].to_pos, 1, 0, 9)
	if !objs[0].to_pos in attacks.keys():
		attacks[objs[0].to_pos] = {}
	if !current_check_obj.id in attacks[objs[0].to_pos].keys():
		attacks[objs[0].to_pos][current_check_obj.id] = {}
	if !current_check_wep.id in attacks[objs[0].to_pos][current_check_obj.id].keys():
		attacks[objs[0].to_pos][current_check_obj.id][current_check_wep.id] = {}
	attacks[objs[0].to_pos][current_check_obj.id][current_check_wep.id][current_wep_tile] = obj_ids


var search_objs : Array[Map_Object]
var current_check_obj : Map_Object = null:
	set(obj):
		current_check_obj = obj
		rpc_clear_layer.rpc(0)
		if obj != null:
			for wep_id:int in obj.unit.cubic_weapons.keys():
				var wep_mod : Module_Data.Weapon_Data = obj.unit.unit_data.get_module(wep_id)
				var is_valid_melee : bool = wep_mod.subtype == "Melee" and turn_tracker.phase == turn_tracker.PHASES.melee
				var is_valid_ranged : bool = wep_mod.subtype != "Melee" and turn_tracker.phase == turn_tracker.PHASES.ranged
				if is_valid_melee or is_valid_ranged:
					current_check_obj_weps.append(wep_mod)
			if current_check_obj_weps.size():
				rpc_set_cell.rpc(0, obj.to_pos, 1)
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
		rpc_set_cell.rpc(0, current_wep_tile, 0)
		var defenders : Array[Map_Object] = []
		var objs : Array = obj_ctrl.get_objs_at(current_wep_tile)
		for obj in objs:
			if obj.unit.state != obj.unit.STATES.roller:
				defenders.append(obj)
		if defenders.size():
			found_attack(defenders)
		#print(objs, defenders)

var do_process : bool = false
#@export var tick_speed_msec : int = 100
@onready var tick_speed_msec : int = Global.get_wait_msec(0.25)
var tick : int = -1
func _process(delta):
	if !do_process or (Time.get_ticks_msec() - tick) < tick_speed_msec:
		return
	tick = Time.get_ticks_msec()
	if !do_next_check():
		do_process = false
		await Global.create_wait_timer(0.25)
		on_search_complete.emit()
		rpc_clear_layer.rpc(0)

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
