extends Sprite2D
class_name Map_Cursor

signal moved()

var local_player : int:
	get: return map.local_player
var held_object : Map_Object = null:
	set(obj):
		held_object = obj
		hover()
var map_pos : Vector2i:
	set(pos):
		if pos == map_pos:
			return
		map.set_cell(2,map_pos)
		if turn_tracker.round:
			highlight_on_map.rpc(local_player, cubic, false)
		map_pos = pos
		map.set_cell(2,map_pos, 0, Vector2i(0,0))
		if turn_tracker.round:
			highlight_on_map.rpc(local_player, cubic, true)
		if held_object != null:
			held_object.unit.buy_sell = map_pos in map.local_trash
		if turn_tracker.phase != turn_tracker.PHASES.action:
			return
		if turn_tracker.anim_msec != 0:
			return
		moved.emit()
		hover()
var cubic : Vector3i:
	get: return map.oddq_to_cubic(map_pos)

@onready var map : TileMap = get_parent()
@export var turn_tracker : Turn_Tracker = null
@export var obj_ctrl : Object_Controller = null

@rpc("any_peer","call_remote","reliable")
func highlight_on_map(num:int, cube:Vector3i, toggle:bool):
	var oddq : Vector2i = map.cubic_to_oddq(cube)
	if !toggle:
		map.set_cell(2,oddq)
		return
	var tile = 2
	if (local_player + 1) % 3 == num:
		tile = 3
	map.set_cell(2,oddq,1,Vector2i(num,0),1)
	


func _process(_delta):
	global_position = get_global_mouse_position()
	map_pos = map.local_to_map(position)
	if turn_tracker.phase != turn_tracker.PHASES.action:
		return
	var accept : bool = Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("lmb")
	var cancel : bool = Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("rmb")
	if accept and hovering_objs.size():
		hovering_objs[0].cursor_accept()
	elif cancel and hovering_objs.size():
		hovering_objs[0].cursor_cancel()
	return

var hovering_objs : Array
func hover():
	var new_hovers : Array = []
	for obj in hovering_objs:
		if obj == null:
			continue
		elif map.cubic_to_oddq(obj.cubic) != map_pos:
			obj.unit.cursor_hover(false)
		else:
			new_hovers.append(obj)
	if held_object != null:
		new_hovers.append(held_object)
	for obj in obj_ctrl.get_objs_at(map.oddq_to_cubic(map_pos)):
		if !obj in hovering_objs:
			new_hovers.append(obj)
			obj.unit.cursor_hover(true)
	hovering_objs = new_hovers
