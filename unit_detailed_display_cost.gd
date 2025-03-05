extends HBoxContainer

var buy : Dictionary = {}
var sell : Dictionary = {}

func clear():
	$cost.clear()
func setup(data:Unit_Data):
	buy = data.cost
	sell = data.sale
	refresh_cost()

var flip: bool = false #false==buy, true==sell
func refresh_cost():
	$cost.set_cost([buy,sell][int(flip)])

func _on_check_button_toggled(toggled_on):
	flip = toggled_on
	$cost.flip_colors = flip
	refresh_cost()
