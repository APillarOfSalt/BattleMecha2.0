extends Resource
class_name Team_Data
var name : String
var base_color : Color
var palette : int = -1
func get_color(ind:int)->Color:
	if base_color == Color.BLACK or palette == -1:
		return base_color
	return ColorHelper.generate_palette( base_color, palette, max(ind+1,4) )[ind]


var starting_resources : Dictionary = {
	"titanium" : 0,
	"gallium" : 0,
	"aluminum" : 0,
	"cobalt" : 0,
}
var starting_units : Array = [-1,-1,-1]

var units : Dictionary = { # num:int : [Unit_Data, etc...]
	1:[],2:[],3:[],4:[],
}

func _init(arg=null):
	if arg is Dictionary:
		_from_dictionary(arg)
	elif arg is String:
		_from_json_string(arg)

func _duplicate()->Team_Data:
	return Team_Data.new(_to_dictionary())


func _from_dictionary(dict:Dictionary):
	name = dict.name
	palette = dict.p_data.w
	base_color = Color(dict.p_data.x, dict.p_data.y, dict.p_data.z, 1.0)
	starting_resources.titanium = dict.ti
	starting_resources.gallium = dict.ga
	starting_resources.aluminum = dict.al
	starting_resources.cobalt = dict.co
	starting_units[0] = dict.u0
	starting_units[1] = dict.u1
	starting_units[2] = dict.u2
	for i in dict.units.keys():
		for unit in dict.units[i]:
			units[int(i)].append(unit)
func _from_json_string(json:String):
	var data : Dictionary = JSON.parse_string(json)
	var dict : Dictionary = {
		"name": data.name,
		"p_data" : Global.vec4_from_json(data.p_data),
		"ti" : int(data.ti),
		"ga" : int(data.ga),
		"al" : int(data.al),
		"co" : int(data.co),
		"u0" : int(data.u0),
		"u1" : int(data.u1),
		"u2" : int(data.u2),
		"units":{}}
	for num in data.units.keys():
		dict.units[int(num)] = []
		for unit_json in data.units[num]:
			var unit := Unit_Data.new(unit_json)
			dict.units[int(num)].append(unit)
	_from_dictionary(dict)
func _to_dictionary(skip_units:bool=false)->Dictionary:
	var dict : Dictionary = {
		"name" : name,
		"p_data" : Vector4(base_color.r, base_color.g, base_color.b, palette),
		"ti" : starting_resources.titanium,
		"ga" : starting_resources.gallium,
		"al" : starting_resources.aluminum,
		"co" : starting_resources.cobalt,
		"u0" : starting_units[0],
		"u1" : starting_units[1],
		"u2" : starting_units[2],
	}
	if skip_units:
		return dict
	dict.units = {}
	for i in units.keys():
		if units[i].size():
			dict.units[i] = units[i]
	return dict
func _to_json_string()->String:
	var dict : Dictionary = _to_dictionary(true)
	dict.units = {}
	for num in units.keys():
		dict.units[num] = []
		for i in units[num]:
			dict.units[num].append(i._to_json_string())
	return JSON.stringify(dict)
func _to_string()->String:
	return str(_to_dictionary())
