extends Resource

class_name Unit_Data

func _init(arg=null):
	if arg is Dictionary:
		_from_dict(arg)
	elif arg is String:
		_from_json_string(arg)
	else:
		return
	_initialize()

func _from_dict(dict:Dictionary)->bool:
	if "atlas" in dict:
		atlas = Vector2i(Global.vec2_from_json(dict.atlas))
	elif "x" in dict and "y" in dict:
		atlas = Vector2i(dict.x, dict.y)
	movement.clear()
	if "movement" in dict:
		for i in dict.movement:
			movement.append(int(i))
	else:
		for i in 6:
			if str("m",i) in dict:
				movement.append(dict[str("m",i)])
	for i in cost.keys():
		if i in dict:
			cost[i] = dict[i]
		else:
			cost[i] = dict[i.substr(0,2)]
	for s in VAR_STRS:
		if s == "size" and dict.id > 20:
			print("oop")
		self[s] = dict[s]
	#if !"weapon_0" in dict:
	return true
	#if dict.weapon_0 != null:
		#modules[Vector2i(dict.w0_px, dict.w0_py)] = DataLoader.weapons_by_id[int(dict.weapon_0)]
	#if dict.weapon_1 != null:
		#modules[Vector2i(dict.w1_px, dict.w1_py)] = DataLoader.weapons_by_id[int(dict.weapon_1)]
	#return true

const DICT_KEYS : Array = ["id", "name","size","hp","armor","shield","type","atlas","movement" ]
func _from_dictionary(data:Dictionary)->bool:
	for key in DICT_KEYS:
		if !key in data:
			return false
		self[key] = data[key]
	for key in ["set_",""]:
		key = str(key,"modules")
		var mod_data = data[key]
		if mod_data is String:
			mod_data = JSON.parse_string(data[key])
		if !mod_data is Array:
			print("oop")
		for arr in mod_data:
			var mod_pos : Vector2i
			var mod : Module_Data
			if arr[0] is String:
				mod_pos = Vector2i(Global.vec2_from_json(arr[0]))
				var mod_id : int = int(arr[1])
				if abs(mod_id) > 9000:
					mod_id = 1
				mod = DataLoader.modules_by_id[ mod_id ]
			elif arr[0] is Vector2i:
				mod_pos = arr[0]
				mod = arr[1]
			else:
				print("oop")
			self[key].append( [mod_pos, mod] )
			
	for key in cost:
		if !key in data:
			return false
		cost[key] = data[key]
	return true

func _from_json_string(json:String):
	var dict : Dictionary = JSON.parse_string(json)
	if "set_mods" in dict:
		dict.set_modules = dict.set_mods
	if "atlas" in dict:
		dict.atlas = Vector2i(Global.vec2_from_json(dict.atlas))
	elif "atlas_x" in dict and "atlas_y" in dict:
		dict.atlas = Vector2i(dict.atlas_x, dict.atlas_y)
	if dict.movement[0] is String:
		var _move : Array = []
		for i in dict.movement:
			_move.append( Vector2i(Global.vec2_from_json(i)) )
		dict.movement = _move
	_from_dictionary(dict)
func _to_json_string()->String:
	var dict : Dictionary = _to_dictionary()
	var mods : Array = []
	for arr in dict.modules:
		var mod_id : int = arr[1].id
		mods.append( [arr[0], mod_id] )
	dict.modules = JSON.stringify(mods)
	mods.clear()
	for arr in dict.set_modules:
		var mod_id : int = arr[1].id
		mods.append( [arr[0], mod_id] )
	dict.set_modules = JSON.stringify(mods)
	dict.atlas_x = atlas.x
	dict.atlas_y = atlas.y
	return JSON.stringify(dict)

func _to_dictionary()->Dictionary: 
	return {
	"id" : id,
	"name" : name,
	"size" : size,
	"hp" : hp,
	"armor" : armor,
	"shield" : shield,
	"type" : type,
	"atlas" : atlas,
	"titanium" : cost.titanium,
	"gallium" : cost.gallium,
	"aluminum" : cost.aluminum,
	"cobalt" : cost.cobalt,
	"movement" : movement,
	"set_modules" : set_modules,
	"modules" : modules, #pos:Vector2i : mod:Module_Data
}


func _to_string(indent:String="\n ")->String:
	var text : String = ""
	for s in VAR_STRS:
		text += str(s,":",self[s],indent)
	text += str("Atlas:",atlas,indent)
	text += str("Cost:",cost,indent)
	text += "Set Modules"
	for arr in set_modules:
		text += str(arr[0],":",arr[1], indent)
	text += "Modules"
	for arr in modules:
		text += str(arr[0],":",arr[1], indent)
	text.trim_suffix(indent)
	return text

const VAR_STRS : Array = ["id", "size", "hp", "armor", "shield", "name", "type"]
var id : int
var name : String
var size : int

var hp : int
var armor : int
var shield : int
var shield_start : int
var shield_regen : int
var _initialized : bool = false
func _initialize(reset:bool=false):
	if _initialized and !reset:
		return
	hp = 0
	armor = 0
	shield = 0
	shield_start = 0
	shield_regen = 0
	weapons.clear()
	full_movement = movement.duplicate(true)
	for mods in [set_modules,modules]:
		for arr in mods:
			var data : Module_Data = arr[1]
			match data.id:
				1: #hull upgrade MK.I
					hp += 2
					continue
				2: #hull upgrade MK.II
					hp += 3
					continue
				3: #armor upgrade
					armor += 1
					continue
			if data is Module_Data.Shield_Data:
				shield += data.cap
				shield_start += data.start
				shield_regen += data.regen
			if data.type == "Weapon":
				weapons.append(data)
				has_melee = has_melee or data.subtype == "Melee"
			if data.type != "Module":
				continue
			full_movement.append_array(data.hex_shape)
	_initialized = true

var type : String
var atlas : Vector2i
var cost : Dictionary = {
	"titanium" : 0,
	"gallium" : 0,
	"aluminum" : 0,
	"cobalt" : 0,
}
var full_movement : Array = []
var movement : Array = []
var set_modules : Array #[ [pos:Vector2i,mod:Module_Data], [etc...] ]
var modules : Array #[ [pos:Vector2i,mod:Module_Data], [etc...] ]
var weapons : Array
var has_melee : bool = false
var sale : Dictionary:
	get:
		var d : Dictionary = {}
		for key in cost.keys():
			d[key] = 2 - cost[key]
		return d

func get_module(mod_id:int)->Module_Data:
	for arr in [set_modules, modules]:
		for mod in arr:
			if mod[1].id == mod_id:
				return mod[1]
	return null
