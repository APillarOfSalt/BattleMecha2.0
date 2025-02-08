extends Node2D
class_name Unit_Controller

#var units : Array[Unit_Node]
#@export var map : TileMap
#@export var game_controller : Game_Controller
#
#func add_unit(unit:Unit_Node):
	#if unit.get_parent() != self:
		#unit.reparent(self)
		#units.append(unit)
		#unit.controller = self
		#return true
	#return false
#
#func request_movement(unit:Unit_Node, is_plan:bool):
	#if is_plan:
		#request_highlight(unit, true)
		#return highlighting_tiles
	#if unit == highlighting_unit: #and !is_plan
		#request_highlight(unit, false)



#func check_affordable(cost:Dictionary):
	#return game_controller.ui.check_afforable(cost)
