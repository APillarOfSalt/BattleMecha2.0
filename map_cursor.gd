extends Sprite2D
class_name Map_Cursor

signal moved()

var local_ui : Player_UI = null
var local_player : int:
	get: return map.local_player

var held_object : Map_Object = null:
	set(obj):
		if held_object != null:
			if obj != null:
				return
			held_object.cursor.held = null
		held_object = obj
		if obj != null:
			obj.cursor.held = self
var map_pos : Vector2i:
	set(pos):
		if pos == map_pos:
			return
		do_highlight(false)
		map_pos = pos
		do_highlight(true)
		moved.emit()
		if !get_can_act():
			return
		hover()
var cubic : Vector3i:
	get: return map.oddq_to_cubic(map_pos)


@onready var map : TileMap = get_parent()
@export var turn_tracker : Turn_Tracker = null
@export var obj_ctrl : Object_Controller = null

func do_highlight(io:bool):
	var i := -int(!io) #false:-1 , true:0
	map.set_cell(2,map_pos, i, Vector2i(i,i))
	if turn_tracker.round:
		highlight_on_map.rpc(local_player, cubic, io)
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


var is_action_phase : bool:
	get:
		is_action_phase = turn_tracker.phase == turn_tracker.PHASES.action
		is_action_phase = is_action_phase and turn_tracker.anim_msec == 0 #is not animating
		return is_action_phase
var can_act : bool:
	set(toggle):
		if can_act and !toggle: #turn over
			held_object = null
		elif !can_act and toggle: #turn started
			hover()
		can_act = toggle
func get_can_act()->bool:
	can_act = local_ui.actions.can_act() and is_action_phase
	return can_act

func _process(_delta):
	if turn_tracker.phase  < 0:
		return
	global_position = get_global_mouse_position()
	map_pos = map.local_to_map(position)
	if !get_can_act():
		return
	var accept : bool = Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("lmb")
	var cancel : bool = Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("rmb")
	if accept and hovering_objs.size():
		hovering_objs[0].cursor.cursor_accept(self)
	elif cancel and hovering_objs.size():
		hovering_objs[0].cursor.cursor_cancel()

var hovering_objs : Array
func hover():
	var new_hovers : Array = []
	for obj in hovering_objs:
		if obj == null:
			continue
		elif map.cubic_to_oddq(obj.cubic) != map_pos:
			obj.cursor.cursor_hover(false)
		else:
			new_hovers.append(obj)
	if held_object != null:
		new_hovers.append(held_object)
	for obj in obj_ctrl.get_objs_at(map.oddq_to_cubic(map_pos)):
		if !obj in hovering_objs:
			new_hovers.append(obj)
			obj.cursor.cursor_hover(true)
	hovering_objs = new_hovers


var highlighting_tiles : Array[Vector3i] = []
func request_grab(obj:Map_Object):
	if !get_can_act() or held_object != null:
		return
	obj.move_highlight.highlight_movement(true)
	highlighting_tiles = obj.get_movement(true)
	obj.set_state_held()
	held_object = obj
func request_buy(obj:Map_Object):
	if !get_can_act() or held_object != null:
		return
	request_grab(obj)
	local_ui.cost_disp.set_cost(obj.unit.unit_data.cost)
	local_ui.cost_disp.modulate.a = 0.5
func request_drop(obj:Map_Object):
	local_ui.cost_disp.clear()
	local_ui.cost_disp.modulate.a = 0.0
	if obj.bought:
		obj.set_state_deploy()
	else:
		obj.set_state_roller()
	if obj == held_object:
		held_object = null
func request_purchase(obj:Map_Object)->bool:
	if !get_can_act() or obj != held_object or obj == null:
		return false
	if !cubic in highlighting_tiles:
		return false
	if !map.is_trash(cubic):
		if !obj.do_purchase():
			return false
	return do_move(obj)
func request_move(obj:Map_Object)->bool:
	if !get_can_act() or obj != held_object or obj == null:
		return false
	if !cubic in highlighting_tiles:
		return false
	return do_move(obj)
func do_move(obj:Map_Object):
	map.set_highlight(highlighting_tiles, false)
	highlighting_tiles.clear()
	obj.to_pos = cubic
	obj.turn_over = true
	obj.set_state_deploy()
	local_ui.actions.spend_action()
	held_object = null
	return true
