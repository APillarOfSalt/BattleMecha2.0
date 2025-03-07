extends Sprite2D

@onready var bg_spr : Sprite2D = $"../bg"
@onready var move_highlight : TileMap = $"../movement_highlight"
@onready var atk_highlight : TileMap = $"../combat_highlight"
@onready var obj : Map_Object = get_parent()
var global_map : TileMap:
	get: return obj.map
func glo_pos_from_cube(cube:Vector3i)->Vector2:
	return global_map.to_global( global_map.map_to_local( global_map.cubic_to_oddq(cube) ) )
var unit : Unit_Node:
	get: return obj.unit

var held : Map_Cursor = null:
	set(cursor):
		if held != null:
			held.moved.disconnect(_on_cursor_moved)
			if obj.bought:
				obj.set_state_deploy()
			else:
				obj.set_state_roller()
			atk_highlight.highlight_attack(false)
			move_highlight.highlight_movement(false)
		held = cursor
		var is_held : bool = cursor != null
		if is_held:
			held.moved.connect(_on_cursor_moved)
		visible = is_held or to_pos != cubic
		bg_spr.visible = is_held or to_pos != cubic
		move_highlight.modulate.a = (int(is_held)*0.5) + 0.5

var cubic : Vector3i:
	set(vec):
		obj.cubic = vec
	get: return obj.cubic
var to_pos : Vector3i:
	set(vec):
		to_pos = vec
		visible = vec != cubic
		bg_spr.visible = vec != cubic
		atk_highlight.highlight_attack(atk_highlight.is_highlighting)
		global_position = glo_pos_from_cube(vec)
		atk_highlight.position = position - Vector2(32,32)
		if !obj.locally_owned:
			unit.ui.set_cost_vis(0)
		elif global_map.is_trash(vec):
			unit.ui.set_cost_vis(1)
		elif obj.bought:
			unit.ui.set_cost_vis(0)
		else:
			unit.ui.set_cost_vis(-1)
var push_cube := Vector3i(0,0,0):
	set(vec):
		push_cube = vec
		visible = vec != Vector3i(0,0,0)
		global_position = glo_pos_from_cube(vec)
		atk_highlight.position = position - Vector2(32,32)


var hovered : bool = false
func cursor_hover(is_hovered:bool):
	if hovered == is_hovered:
		return #if the hover state isn't being changed
	if !obj.locally_owned:
		atk_highlight.highlight_attack(is_hovered)
	else:
		move_highlight.highlight_movement(is_hovered or held != null)
	hovered = is_hovered
	unit.hovered = is_hovered
func cursor_accept(cursor:Map_Cursor):
	if !obj.locally_owned:
		return
	if held == null:
		if obj.get_state_is_roller():
			cursor.request_buy(obj)
		elif obj.get_state_is_deploy() and !obj.turn_over:
			cursor.request_grab(obj)
	elif obj.get_state_is_held():
		if held.cubic == cubic:
			held.request_drop(obj)
		elif !obj.bought:
			obj.bought = held.request_purchase(obj)
			if !obj.bought:
				return
		else:
			held.request_move(obj)
	bg_spr.visible = obj.get_state_is_held()
func cursor_cancel():
	if held == null or !obj.locally_owned:
		return
	to_pos = cubic
	held.request_drop(obj)
	bg_spr.visible = obj.get_state_is_held()
func _on_cursor_moved():
	if held == null:
		return
	var new_pos : Vector3i = held.cubic
	var is_valid_move : bool = new_pos in obj.get_movement(true)
	atk_highlight.highlight_attack(is_valid_move and global_map.is_tile(new_pos))
	if is_valid_move:
		if obj.get_state_is_roller():
			if !obj.check_afforable() and !global_map.is_trash(new_pos):
				return
		to_pos = new_pos
