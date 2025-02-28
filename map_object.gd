extends Node2D
class_name Map_Object

func get_local_player()->int:
	return map.local_player
@onready var map : TileMap = get_parent().get_parent()
func glo_pos_from_cube(cube:Vector3i)->Vector2:
	return map.to_global( map.map_to_local( map.cubic_to_oddq(cube) ) )

@onready var cursor : Sprite2D = $cursor_manager
@onready var move_highlight : TileMap = $movement_highlight
@onready var atk_highlight : TileMap = $cursor_manager/combat_highlight

func _start_turn():
	turn_over = false

func play_death()->Signal:
	unit.def_anim_ctrl._play_death()
	return unit.def_anim_ctrl.finished

var turn_over : bool = false:
	set(toggle):
		turn_over = toggle
		unit.tint_outline = toggle
var bought : bool = false
func do_purchase()->bool:
	if check_afforable():
		ui.apply_cost_to_res()
		bought = true
	return bought
var locally_owned : bool = false
var ui : Player_UI = null
func check_afforable()->bool:
	return ui.check_affordable(unit.unit_data.cost)

var id : int = -1
var dying : bool = false
func do_free(death_return_sale:int=-1):
	dying = true
	if death_return_sale == 1:
		ui.unit_sale(unit)
	unit.is_now_dead.emit(unit, death_return_sale)

func setup(oid:int, cube:Vector3i,p_num:int,unit_id:int, local:bool):
	id = oid
	name = str("obj_",id)
	ui = Global.player_info_by_num[p_num].ui
	unit = ui.deck.get_unit(unit_id)
	unit.name = unit.unit_data.name
	player_num = p_num
	player_color = ui.player_color
	secondary_color = ui.secondary_color
	tertiary_color = ui.tertiary_color
	unit.map = map
	unit.controller = ui
	unit.map_obj = self
	unit.player_num = p_num
	unit.locally_owned = local
	locally_owned = local
	add_child(unit)
	unit.calc_cubic()
	global_position = glo_pos_from_cube(cube)
	cubic = cube

var player_num : int = -1
var player_color : Color
var secondary_color : Color:
	set(color):
		secondary_color = color
		$bg.modulate = color
		$cursor_manager.self_modulate = color
var tertiary_color : Color
var unit : Unit_Node = null
#enum unit.STATES{roller=-1,held=0,deploy=1,ready=2}
func set_state_roller():
	unit.state = unit.STATES.roller
func get_state_is_roller()->bool:
	return unit.state == unit.STATES.roller
func set_state_held():
	unit.state = unit.STATES.held
func get_state_is_held()->bool:
	return unit.state == unit.STATES.held
func set_state_deploy():
	unit.state = unit.STATES.deploy
func get_state_is_deploy()->bool:
	return unit.state == unit.STATES.deploy
func set_state_ready():
	unit.state = unit.STATES.ready
func get_state_is_ready()->bool:
	return unit.state == unit.STATES.ready


func confirm_combat_move():
	if cursor.push_cube == Vector3i(0,0,0):
		return
	cubic = to_pos
	to_pos += cursor.push_cube
	cursor.push_cube = Vector3i(0,0,0)
func confirm_move():
	cubic = to_pos
	_start_turn()


var to_pos : Vector3i:
	set(vec): cursor.to_pos = vec
	get: return cursor.to_pos
var cubic : Vector3i:
	set(vec):
		cubic = vec
		to_pos = vec
		global_position = glo_pos_from_cube(vec)
		unit.global_position = glo_pos_from_cube(vec)

func get_movement(use_cubic:bool=false):
	var affordable : bool = check_afforable() or bought
	var movement : Array[Vector3i] = []
	for cube in unit.cubic_movement.duplicate(true):
		if affordable or map.is_trash(cube + cubic):
			movement.append(cube)
			if use_cubic:
				movement[-1] += cubic
	return movement

#false:Push ; true:Move
func tween_pos(ratio:float, push_move:bool=false):
	var to : Vector3i = to_pos # true to_pos
	var from : Vector3i = cubic # true cubic
	if !push_move: #push
		if cursor.push_cube == Vector3i(0,0,0):
			return
		from = to_pos # false to_pos
		to += cursor.push_cube # false to_pos+cubic
	unit.global_position = glo_pos_from_cube(from).lerp( glo_pos_from_cube(to), ratio )



