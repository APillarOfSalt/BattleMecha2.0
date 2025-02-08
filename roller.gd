extends Node2D
class_name Unit_Roller

@export var map : TileMap
func _ready():
	refresh_center.call_deferred()
func refresh_center():
	$h.position.x = -($h/v/tile.size.x*0.5) - cost_cont.size.x - 12#separation override
@export var game_controller : Game_Controller
@export var unit_controller : Unit_Controller

@onready var cost_cont : Cost_Data = $h/p/m/cost

var map_pos : Vector2i:
	get: return map.local_to_map(map.to_local(position))

signal request_reroll(unit:Unit_Node)

var current_unit : Unit_Node = null

func _on_reroll_approved():
	if !map is TileMap:
		return
	if fuck_godot:
		cost_cont.set_cost(current_unit.unit_data.sale)
	else:
		cost_cont.set_cost(current_unit.unit_data.cost)

func _on_reroll_pressed():
	request_reroll.emit(current_unit)


func _on_reroll_focus_entered():
	fuck_godot = true
func _on_reroll_mouse_entered():
	fuck_godot = true

func _on_reroll_focus_exited():
	fuck_godot = false
func _on_reroll_mouse_exited():
	fuck_godot = false

var fuck_godot : bool:
	set(toggle):
		if current_unit == null:
			fuck_godot = false
			return
		fuck_godot = toggle
		cost_cont.flip_colors = toggle
		current_unit.hovered = toggle
		if toggle:
			cost_cont.set_cost(current_unit.unit_data.sale)
		else:
			cost_cont.set_cost(current_unit.unit_data.cost)
	



