extends Container

func get_dict()->Dictionary:
	var dict : Dictionary = {"push" : push_dir,"priority" : priority, "abilities":[]}
	if ap:
		dict.abilities.append("ap")
	if sp:
		dict.abilities.append("sp")
	if reflect:
		dict.abilities.append("ref")
	return dict

var module : Module_Data = null
func setup(mod:Module_Data):
	module = mod
	visible = mod is Module_Data.Weapon_Data
	if visible:
		push_dir = mod.push
		priority = mod.priority
		ap = "ap" in mod.abilities
		sp = "sp" in mod.abilities
		reflect = "ref" in mod.abilities

var push_dir : int = -1:
	set(val):
		push_dir = val
		push_disp.push_dir = val
	get: return push_disp.push_dir
@onready var push_disp : Container = $push
var priority : int = 0:
	set(val):
		priority = val
		priority_butt.value = val
	get: return priority_butt.value
@onready var priority_butt : SpinBox = $priority/val
var ap : bool = false:
	set(toggle):
		ap = toggle
		armor_butt.button_pressed = toggle
	get: return armor_butt.button_pressed
@onready var armor_butt : CheckButton = $armor_p/toggle
var sp : bool = false:
	set(toggle):
		sp = toggle
		shield_butt.button_pressed = toggle
	get: return shield_butt.button_pressed
@onready var shield_butt : CheckButton = $shield_p/toggle
var reflect : bool = false:
	set(toggle):
		reflect = toggle
		reflect_butt.button_pressed = toggle
	get: return reflect_butt.button_pressed
@onready var reflect_butt : CheckButton = $use_reflect/m/toggle
