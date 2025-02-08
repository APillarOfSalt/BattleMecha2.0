extends GridContainer

func get_dict()->Dictionary:
	return {
		"start":start,
		"cap":capacity,
		"regen":regeneration,
	}

var module : Module_Data = null
func setup(mod:Module_Data):
	module = mod
	visible = mod is Module_Data.Shield_Data
	if visible:
		start = mod.start
		capacity = mod.cap
		regeneration = mod.regen

var start : int:
	set(val):
		start = val
		$start.value = val
var capacity : int:
	set(val):
		capacity = val
		$cap.value = val
var regeneration : int:
	set(val):
		regeneration = val
		$regen.value = val
