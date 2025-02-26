extends ScrollContainer

const disp_scene : PackedScene = preload("res://score_state_disp.tscn")

var state_to : int = 2
var state_from : int = 1
func state_setter(value:int, to_from:bool)->bool:
	if value == [state_from,state_to][int(to_from)]:
		return false
	if to_from: #from
		state_from = value
	else:
		state_to = value
	return true

func step_setter(steps:int):
	for ch in $h/h.get_children():
		ch.remove_from_group("score_state_disp")
		ch.free()
	for i in steps - 2:
		var disp = disp_scene.instantiate()
		$h/h.add_child(disp)
		disp.step = $h/h.get_child_count()
