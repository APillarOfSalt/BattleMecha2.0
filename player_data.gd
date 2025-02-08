extends Resource
class_name Player_Data

func _init(arg=null):
	if arg is Dictionary:
		_from_dictionary(arg)
	elif arg is String:
		_from_json_string(arg)

func _from_dictionary(dict:Dictionary, skip_team:bool=false)->bool:
	for s in VAR_STRS:
		if s == "team" and skip_team:
			continue
		if !s in dict:
			return false
		if self[s] is int:
			self[s] = int(dict[s])
		else:
			self[s] = dict[s]
	return true
func _to_dictionary()->Dictionary:
	var dict : Dictionary = {}
	for s in VAR_STRS:
		dict[s] = self[s]
	return dict
func _from_json_string(json:String)->bool:
	var dict : Dictionary = JSON.parse_string(json)
	team = Team_Data.new(dict.team)
	_from_dictionary(dict, true)
	return true
func _to_json_string()->String:
	var dict : Dictionary = _to_dictionary()
	dict.team = team._to_json_string()
	return JSON.stringify(dict)

var ui : Player_UI = null
const VAR_STRS : Array[String] = ["iid","peer_id","num","name","team"]
var iid : int = -1
var peer_id : int = -1
var num : int = -1
var name : String = ""
var team : Team_Data = null
