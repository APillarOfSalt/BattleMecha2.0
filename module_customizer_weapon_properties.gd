extends Container

func get_dict()->Dictionary:
	return {
		"push" : push_dir,
		"radius" : radius,
		"ap" : ap,
		"sp" : sp,
	}

var module : Module_Data = null
func setup(mod:Module_Data):
	module = mod
	visible = mod is Module_Data.Weapon_Data
	if visible:
		push_dir = mod.push
		radius = mod.radius
		ap = mod.ap
		sp = mod.sp

var push_dir : int = -1:
	set(val):
		push_dir = val
		push_disp.push_dir = val
	get: return push_disp.push_dir
@onready var push_disp : Container = $push
var radius : int = 0:
	set(val):
		radius = val
		radius_butt.value = val
	get: return radius_butt.value
@onready var radius_butt : SpinBox = $radius/val
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
