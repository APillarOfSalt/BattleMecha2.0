extends Node2D

class_name Game_Controller

var players : Array = [player_data.new()]

class player_data:
	var id : int = 0
	var name : String = "Debug"
	var input : int = 0
	var currency : int = 99
@export var objective_controller : Objective_Controller

@export var roller_l : Unit_Roller

func _on_roller_l_request_reroll(unit:Unit_Node=null):
	if !ui.add_cur(unit.unit_data.sale): #if not enough money
		return
	if unit != null:
		objective_controller.add_rolled_unit(unit, 0)
	roller_l.current_unit = null
	roller_l._on_reroll_approved()
@export var roller_m : Unit_Roller
func _on_roller_m_request_reroll(unit:Unit_Node=null):
	if !ui.add_cur(unit.unit_data.sale): #if not enough money
		return
	if unit != null:
		objective_controller.add_rolled_unit(unit, 0)
	roller_m.current_unit = null
	roller_m._on_reroll_approved()
@export var roller_r : Unit_Roller
func _on_roller_r_request_reroll(unit:Unit_Node=null):
	if !ui.add_cur(unit.unit_data.sale): #if not enough money
		return
	if unit != null:
		objective_controller.add_rolled_unit(unit, 0)
	roller_r.current_unit = null
	roller_r._on_reroll_approved()

@onready var ui_cont : Container = $game_ui
func ui_size_x(x:int):
	var view_x : int = get_viewport().size.x
	ui_cont.size.x = min(view_x, x)
	ui_cont.position.x = -clamp(x, drag_butt.size.x, view_x)
@onready var ui = $game_ui/ui
@onready var drag_butt : Button = $game_ui/drag
@onready var drag_x : int = -1
func _on_drag_button_down():
	drag_x = floor( drag_butt.get_local_mouse_position().x )
func _on_drag_button_up():
	drag_x = -1
func _process(_delta):
	if drag_x >= 0:
		ui_size_x( drag_x + get_viewport().size.x - get_global_mouse_position().x )



