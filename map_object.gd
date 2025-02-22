extends Node2D
class_name Map_Object

@onready var map : TileMap = get_parent().get_parent()
func get_local_player()->int:
	return map.local_player

var locally_owned : bool = false
var ui : Player_UI = null

func do_free(sale:bool=false):
	if sale:
		ui.unit_sale(unit)
	queue_free()

func setup(oid:int, cube:Vector3i,p_num:int,unit_id:int, local:bool):
	id = oid
	name = str("obj_",id)
	ui = Global.player_info_by_num[p_num].ui
	unit = ui.deck.get_unit(unit_id)
	unit.name = unit.unit_data.name
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

func confirm_move():
	cubic = to_pos
	unit.global_position = glo_pos_from_cube(cubic)
	unit._start_turn()

var to_pos : Vector3i:
	set(vec):
		to_pos = vec
		$fg.visible = to_pos != cubic
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

func tween_pos(ratio:float):
	unit.global_position = glo_pos_from_cube(cubic).lerp( glo_pos_from_cube(to_pos), ratio )

