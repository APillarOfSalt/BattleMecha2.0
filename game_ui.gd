extends VBoxContainer

func _ready():
	round = 0
	turn = 0
	titanium = 1
	gallium = 1
	aluminum = 1
	cobalt = 1

var round : int:
	set(val):
		round = val
		turn_label_text()
var turn : int:
	set(val):
		turn = val
		turn_label_text()
@onready var turn_l : Label = $turn_count
func turn_label_text():
	turn_l.text = str("Round ",round," : Turn ",turn)

@onready var cost : Cost_Data = $cost
var titanium: int:
	set(val):
		titanium = val
		cost.set_val("ti", val)
var gallium: int:
	set(val):
		gallium = val
		cost.set_val("ga", val)
var aluminum: int:
	set(val):
		aluminum = val
		cost.set_val("al", val)
var cobalt: int:
	set(val):
		cobalt = val
		cost.set_val("co", val)
func get_res(i:int):
	return [titanium, gallium, aluminum, cobalt][(i+4)%4]
func set_res(i:int, val:int):
	self[["titanium", "gallium", "aluminum", "cobalt"][i]] = val
func mod_res(i:int, amount:int):
	self[["titanium", "gallium", "aluminum", "cobalt"][i]] += amount

func add_cur(dict:Dictionary)->bool:
	for key in dict:
		self[key] += dict[key]
	return true
func sub_cur(dict:Dictionary)->bool:
	for key in dict:
		if self[key] < dict[key]:
			return false
	for key in dict:
		self[key] -= dict[key]
	return true

func check_afforable(pay:Dictionary)->bool:
	for key in pay.keys():
		if get(key) == null:
			return false
		if self[key] < pay[key]:
			return false
	return true


