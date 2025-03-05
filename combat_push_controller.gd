extends Node
class_name Combat_Push_Controller

@export var map : TileMap = null
@export var obj_ctrl : Object_Controller = null

func resolve_overlap_abc( a_id:int,a_wep_id:int, b_id:int,b_wep_id:int, c_id:int=-1,c_wep_id:int=-1 ):
	var data : Dictionary = {
		a_id : a_wep_id,
		b_id : b_wep_id,
	}
	if c_id > -1:
		data[c_id] = c_wep_id
	resolve_overlap(data)

#data = { obj_id:int : weapon_id:int }
func resolve_overlap(data:Dictionary):
	if data.size() == 0:
		return {}
	var objects : Array[Map_Object] = []
	for oid:int in data.keys():
		if oid < 0:
			continue
		var obj : Map_Object = obj_ctrl.all_objects[oid]
		objects.append(obj)
	var handler := Cube_Option_Handler.new(data, objects)
	var cube_oid : Dictionary = handler.get_overlaps()
	var bump_ids : Array = []
	for cube:Vector3i in cube_oid.keys():
		bump_ids.append_array(cube_oid[cube])
	var oid_cube : Dictionary = handler.gather_data()
	for oid:int in oid_cube.keys():
		var obj : Map_Object = obj_ctrl.all_objects[oid]
		if !oid in bump_ids: #move to push spot
			obj.push_cube = oid_cube[oid]
		else: #getting bumped
			print(obj.id,":",obj.push_cube)
			obj.push_cube = obj.cubic - obj.to_pos
			print(obj.id,":",obj.push_cube)

class Cube_Option_Handler:
	var cube_options : Array[Cube_Options] = []
	func gather_data()->Dictionary:
		var data : Dictionary = {}
		for op in cube_options:
			data[op.oid] = op.active_cube
		return data
	func get_overlaps()->Dictionary: #cube:Vector3i : [oid:int, etc...],
		var cube_oid : Dictionary = {}
		for op in cube_options:
			var cube : Vector3i = op.active_cube
			if !cube in cube_oid.keys():
				cube_oid[cube] = []
			cube_oid[cube].append(op.oid)
		var overlaps : Dictionary = {} 
		for cube:Vector3i in cube_oid.keys():
			if cube_oid[cube].size() > 1:
				overlaps[cube] = cube_oid[cube]
		return overlaps
	var oid_po_index : Dictionary = {} #oid:int : index:int ; where: cube_options[index].oid == oid
	func get_op(oid:int)->Cube_Options:
		if !oid in oid_po_index:
			return null
		return cube_options[oid_po_index[oid]]
	var data : Dictionary # obj_id:int : weapon_id:int,
	var objects : Array[Map_Object] = []
	func _init(dict:Dictionary, objs:Array[Map_Object]):
		data = dict
		objects = objs
		_setup()
		#gather all of the pushes
		for i in cube_options.size():
			var a_op : Cube_Options = cube_options[i]
			for j in cube_options.size():
				var b_op : Cube_Options = cube_options[j]
				b_op.add_cube(a_op.w_s, a_op.oid)
		#resolve all overlaps possible
		var overlaps : Dictionary = get_overlaps()
		var _moved : bool = true
		while overlaps.size() and _moved:
			_moved = false
			for cube:Vector3i in overlaps.keys():
				for op:Cube_Options in get_ops_with_smallest_wep(overlaps[cube]):
					_moved = _moved or next_cube(op)
				overlaps = get_overlaps()
				if overlaps.size() == 0:
					break
			overlaps = get_overlaps()
	func get_ops_with_smallest_wep(oids:Array)->Array[Cube_Options]:
		var ws_oid : Dictionary = {} #weapon_size:int : [object_ids:int, etc...]
		var smallest : int = 99
		for oid in oids:
			var ws : int = get_op(oid).w_s
			smallest = min(ws,smallest)
			if !ws in ws_oid.keys():
				ws_oid[ws] = []
			ws_oid[ws].append(oid)
		var ops : Array[Cube_Options] = []
		for oid in ws_oid[smallest]:
			ops.append( get_op(oid) )
		return ops
	func _setup():
		for i in objects.size():
			var oid : int = objects[i].id
			var unit : Unit_Node = objects[i].unit
			var wid : int = data[oid]
			var size : int = 0
			if wid > -1:
				size = unit.unit_data.get_module(wid).size
			var cube := Vector3i(0,0,0)
			if wid in unit.cubic_weapons_push:
				cube = unit.cubic_weapons_push[wid]
			var op := Cube_Options.new(oid, wid, size, cube)
			oid_po_index[oid] = cube_options.size()
			cube_options.append(op)
	
	class Cube_Options:
		var active_cube := Vector3i(0,0,0)
		var from_id : int = -1
		var oid : int #to be cubed obj_id
		var wid : int = -1 #unit's weapon_id
		var w_s : int = 1 #unit's weapon.size
		var w_p := Vector3i(0,0,0) #unit's weapon's cube
		var cubes : Dictionary# = {wep_size:int : [from_oid:int], }
		func _init( u_id:int, w_id:int=-1, _ws:int=1, _wp:=Vector3i(0,0,0) ):
			oid = u_id
			wid = w_id
			w_s = _ws
			w_p = _wp
		func add_cube(size:int, id:int):
			if !size in cubes:
				cubes[size] = []
			cubes[size].append(id)
		func _get_biggest_cube_size()->int:
			var biggest : int = -1
			for size in cubes.keys():
				biggest = max(size, biggest)
			return biggest
	func next_cube(op:Cube_Options)->bool:
		var next_size : int = op._get_biggest_cube_size()
		if next_size == -1:
			return false
		var oids : Array = op.cubes[next_size]
		if oids.size() == 0:
			op.cubes.erase(next_size)
			return next_cube(op)
		op.from_id = op.cubes[next_size].pop_front()
		op.active_cube = get_op( op.from_id ).w_p
		return true
