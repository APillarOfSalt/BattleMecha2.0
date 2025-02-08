extends GridContainer

@onready var ui : Container = get_parent()

func _on_rounds_reset_pressed():
	ui.round = 0
func _on_rounds_minus_pressed():
	ui.round -= 1
func _on_rounds_plus_pressed():
	ui.round += 1


func _on_turn_reset_pressed():
	ui.turn = 0
func _on_turn_minus_pressed():
	ui.turn -= 1
func _on_turn_plus_pressed():
	ui.turn += 1


func _on_zero_pressed():
	ui.set_res(res_id, 0)
func _on_minus_5_pressed():
	ui._cur(res_id, -5)
func _on_minus_pressed():
	ui._cur(res_id, -1)
func _on_plus_pressed():
	ui._cur(res_id, 1)
func _on_plus_5_pressed():
	ui._cur(res_id, 5)
func _on_big_pressed():
	ui.set_res(res_id, 99)

var res_id : int = 0:
	set(val):
		res_id = (val+4) % 4
		for i in 4:
			resource_checks[i].button_pressed = i == res_id

@onready var resource_checks : Array = [$"m/0/0", $"m/0/1", $"m/0/2", $"m/0/3"]
func _on_0_toggled(toggled_on): #§
	if !toggled_on:
		return
	res_id = 0
func _on_1_toggled(toggled_on): #Ħ
	if !toggled_on:
		return
	res_id = 1
func _on_2_toggled(toggled_on): #¤
	if !toggled_on:
		return
	res_id = 2
func _on_3_toggled(toggled_on): #Þ
	if !toggled_on:
		return
	res_id = 3





