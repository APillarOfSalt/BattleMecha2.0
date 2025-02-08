extends Node2D

var ui : Player_UI = null:
	set(pui):
		ui = pui
		ui_res = pui.res_disp
		ui_cost = pui.cost_disp
var ui_res : Cost_Data = null
var ui_cost : Cost_Data = null

var unit : Unit_Node = null:
	set(node):
		if unit != null:
			unit.state_changed.disconnect(_on_unit_state)
		unit = node
		if node != null:
			node.state_changed.connect(_on_unit_state)
		else:
			show()
			set_hover()
func _on_unit_state(st:int):
	if st == Unit_Node.STATES.deploy:
		unit = null
@export_range(0,2,1) var index : int = 0
var map_pos : Vector2i
func _ready():
	await get_parent().ready
	var r = get_parent().local_rollers
	map_pos = get_parent().local_rollers[index]
	position = get_parent().map_to_local( map_pos )

func _new_unit():
	ui.apply_cost_to_res()
	ui.request_roller_unit(index)
	hide()

@onready var ti_l : Label = $reroll/ti/m/h/t_l/h/l
func _on_ti_pressed():
	_new_unit()
func _on_ti_mouse_entered():
	set_hover(0)
func _on_ti_mouse_exited():
	set_hover()

@onready var ga_l : Label = $reroll/ga/m/h/t_l/h/l
func _on_ga_pressed():
	_new_unit()
func _on_ga_mouse_entered():
	set_hover(1)
func _on_ga_mouse_exited():
	set_hover()

@onready var al_l : Label = $reroll/al/m/h/t_l/h/l
func _on_al_pressed():
	_new_unit()
func _on_al_mouse_entered():
	set_hover(2)
func _on_al_mouse_exited():
	set_hover()

@onready var co_l : Label = $reroll/co/m/h/t_l/h/l
func _on_co_pressed():
	_new_unit()
func _on_co_mouse_entered():
	set_hover(3)
func _on_co_mouse_exited():
	set_hover()

@onready var labels : Array = [ti_l,ga_l,al_l,co_l]
@onready var buttons : Array = [$reroll/ti/ti,$reroll/ga/ga,$reroll/al/al,$reroll/co/co]
func set_hover(ind:int=-1):
	ui_cost.clear()
	ui_cost.modulate.a = int(ind > -1)
	ui_cost.flip_colors = false
	if ind >= 0:
		ui_cost[ ui_cost.ele_strs[ind] ] = 1
	for i in 4:
		var res : int = ui_res.get_val(i)
		buttons[i].disabled = res <= 0
		buttons[i].focus_mode = [Control.FOCUS_NONE, Control.FOCUS_ALL][int(res >= 1)]
		var val : int = 0
		var color := Color.WHITE
		if ind == i:
			val = 1
			color = Color.LIME_GREEN
			if res-1 < 0:
				color = Color.RED
			elif res-1 > 1:
				color = Color.DODGER_BLUE
		labels[i].modulate = color
		labels[i].text = str(val)


