extends Resource
class_name Full_Score_State_Data

var name : String = ""
func _to_json_string()->String:
	return JSON.stringify(_to_dictionary())
func _from_json_string(json:String):
	_from_dictionary(JSON.parse_string(json))
func _to_dictionary()->Dictionary:
	var state_dict : Dictionary = {}
	var step_dict : Dictionary = {}
	for key:int in data_states.keys():
		state_dict[key] = data_states[key]._to_dictionary()
	for comb:int in data_steps.keys():
		step_dict[comb] = {}
		for step:int in data_steps[comb].keys():
			step_dict[comb][step] = data_steps[comb][step]._to_dictionary()
	return {
		"name" : name,
		"states" : states, 
		"steps" : steps,
		"state_dict" : state_dict,
		"step_dict" : step_dict,
	}
func _from_dictionary(dict:Dictionary):
	data_states.clear()
	data_steps.clear()
	name = dict.name
	states = int(dict.states)
	steps = int(dict.steps)
	_dim_setter(states, steps)
	for key in dict.state_dict.keys():
		data_states[int(key)] = Score_State_Data.new(dict.state_dict[key])
	for comb in dict.step_dict.keys():
		data_steps[int(comb)] = {}
		for step in dict.step_dict[comb].keys():
			data_steps[int(comb)][int(step)] = Score_State_Data.new(dict.step_dict[comb][step])

var states : int = 3
var steps : int = 3
#x:states, y:steps (inclusive:so 2=A1>B2, 3=A1>2>B3, 4=A1>2>3>B4, 5=A1>2>3>4>B5)
func _dim_setter(sta:int, ste:int):
	while data_states.keys().size() >= sta:
		data_states.erase( data_states.keys().back() )
	var steps_save : Array = data_steps.keys().duplicate(true)
	for i in sta:
		var state_size : int = data_states.keys().size()
		var iflag : int = pow(2,i)
		if !iflag in data_states:
			data_states[iflag] = Score_State_Data.new()
		for j in sta:
			if i == j:
				continue
			var comb_flag : int = pow(2,j) + iflag
			var found : int = steps_save.find(comb_flag)
			if found > -1:
				steps_save.remove_at(found)
			if !comb_flag in data_steps.keys():
				data_steps[comb_flag] = {}
			while data_steps[comb_flag].keys().size() and data_steps[comb_flag].keys().size() >= ste-2:
				data_steps[comb_flag].erase( data_steps[comb_flag].keys().back() )
			while data_steps[comb_flag].keys().size() < ste-2:
				data_steps[comb_flag][data_steps[comb_flag].keys().size()+1] = Score_State_Data.new()
	for key in steps_save:
		data_steps.erase(key)
	states = sta
	steps = ste


var data_states : Dictionary = {
	1 : Score_State_Data.new(), #2^0==a
	2 : Score_State_Data.new(), #2^1==b
	4 : Score_State_Data.new(), #2^2==c
}
var data_steps : Dictionary = {
	3 : {1:Score_State_Data.new()}, #1+2==ab
	5 : {1:Score_State_Data.new()}, #1+4==ac
	6 : {1:Score_State_Data.new()}, #2+4==bc
}

