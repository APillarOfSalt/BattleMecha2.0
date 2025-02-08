extends GridContainer

func get_dict()->Dictionary:
	return {
		"radius":radius,
		"ap":ap,
		"sp":sp,
	}

var module : Module_Data = null
func setup(mod:Module_Data):
	module = mod
	visible = mod is Module_Data.Weapon_Data
	if visible:
		radius = mod.radius
		ap = mod.ap
		sp = mod.sp

var radius : int:
	set(val):
		radius = val
		$radius.value = val
var ap : bool:
	set(toggle):
		ap = toggle
		$ap.button_pressed = toggle
var sp : bool:
	set(toggle):
		sp = toggle
		$sp.button_pressed = toggle
