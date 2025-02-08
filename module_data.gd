extends Resource
class_name Module_Data

enum DMG_TYPES{percussive=0, voltaic=1, concussive=2}

var id : int
var size : int
var name : String
var type : String
var subtype : String
var shape : String
var hex_shape : Array = []
var variables : Array = ["id", "name", "type", "subtype", "size", "shape", "hex_shape"]
func _init(data:Dictionary):
	_from_dict(data)

func _from_dict(data:Dictionary):
	id = data.id
	size = data.size
	name = data.name
	type = data.type
	subtype = data.subtype
	shape = data.shape
	if "hex_shape" in data:
		for i in data.hex_shape:
			if i is String:
				var arr : Array = i.replace("(","").replace(")","").strip_edges().split(",")
				var x : int = arr[0].to_int()
				var y : int = arr[1].to_int()
				hex_shape.append(Vector2i(x,y))
			elif i is Vector2i:
				hex_shape.append(i)
func _to_dictionary()->Dictionary:
	var dict : Dictionary = {}
	for i in variables:
		dict[i] = self[i]
	return dict
func _to_string(indent:String="\n")->String:
	var text : String = ""
	for i in variables:
		text += str(i,":",self[i],indent)
	text.trim_suffix(indent)
	return text
func _duplicate()->Module_Data:
	return Module_Data.new(_to_dictionary())
func check_duplicate(mod:Module_Data)->bool:
	for i in variables:
		if !i in mod:
			return false
		if mod[i] != self[i]:
			return false
	return true

class Weapon_Data:
	extends Module_Data
	var abilities : Array
	var radius : int = 0
	var ap : bool = false
	var sp : bool = false
	func _init(data:Dictionary):
		variables.append_array(["abilities", "radius", "ap", "sp"])
		_from_dict(data)
		radius = data.radius
		ap = data.ap
		if !"abilities" in data:
			return
		if data.abilities == null:
			return
		for i in data.abilities:
			abilities.append(i.strip_edges())
	func _duplicate()->Weapon_Data:
		return Weapon_Data.new(_to_dictionary())
class Shield_Data:
	extends Module_Data
	var start : int
	var cap : int
	var regen : int
	func _init(data:Dictionary):
		variables.append_array(["start", "cap", "regen"])
		_from_dict(data)
		start = data.start
		cap = data.cap
		regen = data.regen
	func _duplicate()->Shield_Data:
		return Shield_Data.new(_to_dictionary())
