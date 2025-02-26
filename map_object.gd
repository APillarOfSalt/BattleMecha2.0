extends Node2D
class_name Map_Object

@onready var map : TileMap = get_parent().get_parent()
func get_local_player()->int:
	return map.local_player

var locally_owned : bool = false
var ui : Player_UI = null

var dying : bool = false
func do_free(death_return_sale:int=-1):
	dying = true
	if death_return_sale == 1:
		ui.unit_sale(unit)
	unit.is_now_dead.emit(unit, death_return_sale)
	queue_free()

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

func glo_pos_from_cube(cube:Vector3i)->Vector2:
	return map.to_global( map.map_to_local( map.cubic_to_oddq(cube) ) )

var id : int = -1

var held : Map_Cursor = null:
	set(cursor):
		if held != null:
			held.moved.disconnect(_on_cursor_moved)
			highlight_attack_tiles(false)
		held = cursor
		if held != null:
			held.moved.connect(_on_cursor_moved)
		$bg.visible = cursor != null

func _on_cursor_moved():
	if held == null:
		return
	for oddq in map.get_used_cells(1):
		if map.oddq_to_cubic(oddq) == held.cubic:
			to_pos = held.cubic
			highlight_attack_tiles(map.map_at(to_pos) == 1)

func confirm_combat_move():
	if push_cube == Vector3i(0,0,0):
		return
	cubic = to_pos
	to_pos += push_cube
	unit.global_position = glo_pos_from_cube(to_pos)
	push_cube = Vector3i(0,0,0)
func confirm_move():
	cubic = to_pos
	unit.global_position = glo_pos_from_cube(cubic)
	
	unit._start_turn()

var push_cube := Vector3i(0,0,0):
	set(vec):
		push_cube = vec
		$fg.visible = vec != Vector3i(0,0,0)
		$fg.global_position = glo_pos_from_cube(vec)
var to_pos : Vector3i:
	set(vec):
		to_pos = vec
		$fg.visible = vec != cubic
		$fg.global_position = glo_pos_from_cube(vec)
		unit.to_cube = vec
var cubic : Vector3i:
	set(vec):
		cubic = vec
		to_pos = vec
		$bg.global_position = glo_pos_from_cube(vec)
		unit.cubic = vec
func get_oodq(cube:Vector3i=cubic)->Vector2i:
	return map.cubic_to_oddq(cube)
var player_num : int = -1
var player_color : Color
var secondary_color : Color:
	set(color):
		secondary_color = color
		$bg.modulate = color
		$fg.modulate = color
var tertiary_color : Color
var unit : Unit_Node = null
#enum unit.STATES{roller=-1,held=0,deploy=1,ready=2}
func cursor_accept():
	if held != null:
		if held.cubic == cubic:
			to_pos = cubic
	unit.cursor_accept()
	$bg.visible = unit.state == unit.STATES.held
func cursor_cancel():
	if held != null:
		to_pos = cubic
	unit.cursor_cancel()
	$bg.visible = unit.state == unit.STATES.held

#false:Push ; true:Move
func tween_pos(ratio:float, push_move:bool=false):
	var to : Vector3i = to_pos # true to_pos
	var from : Vector3i = cubic # true cubic
	if !push_move: #push
		if push_cube == Vector3i(0,0,0):
			return
		from = to_pos # false to_pos
		to += push_cube # false to_pos+cubic
	unit.global_position = glo_pos_from_cube(from).lerp( glo_pos_from_cube(to), ratio )


func highlight_attack_tiles(io:bool):
	map.clear_layer(3)
	if !io:
		return
	for wep_id:int in unit.cubic_weapons.keys():
		for cube:Vector3i in unit.cubic_weapons[wep_id]:
			var oddq : Vector2i = map.cubic_to_oddq(to_pos + cube)
			map.set_cell(3, oddq, 0, Vector2i(1,0))
	
