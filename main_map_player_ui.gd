extends VBoxContainer
class_name Player_UI

signal out_of_actions()
func _on_actions_out_of_actions():
	out_of_actions.emit()
@onready var end_turn_node : Container = $end_turn

@export var map : TileMap
@export var obj_ctrl : Object_Controller
@export var cursor : Node2D = null
@onready var actions : Container = $actions
func spend_action():
	actions.remote_set.rpc( actions.current - 1 )

const style : StyleBoxFlat = preload("res://styles/player_stylebox0.tres")
var our_style : StyleBoxFlat = null
func _ready():
	our_style = style.duplicate(true)
	$title/subpanel.add_theme_stylebox_override("panel",our_style)

var iid : int
var player_num : int = 0
var player_name : String:
	set(text):
		player_name = text
		$title/subpanel/m/Label.text = player_name
var player_color : Color:
	set(color):
		player_color = color
		our_style.bg_color = color
		var col : Color = Global.get_contrasting_greyscale_text_color(color)
		$title/subpanel/m/Label.modulate = col
		$deck.set_base_color(color)
var secondary_color : Color:
	set(color):
		secondary_color = color
		$deck.set_secondary_color(color)
var tertiary_color : Color:
	set(color):
		tertiary_color = color
		$deck.set_tertiary_color(color)
var input_device : int = -3

#player_data : Dictionary == {
	#"iid" : iid,
	#"num" : player_num,
	#"name" : player_name,
	#"device" : device,
	#"color" : color,
	#"ti" : cost_edit.ti,
	#"ga" : cost_edit.ga,
	#"al" : cost_edit.al,
	#"co" : cost_edit.co,
	#"team" : unit_picker.team,
	#"u0" : unit_picker.units[0].unit.id,
	#"u1" : unit_picker.units[1].unit.id,
	#"u2" : unit_picker.units[2].unit.id,
func setup(ctrl:Object_Controller, data:Player_Data): #->Array[Unit_Node]:
	obj_ctrl = ctrl
	iid = data.iid
	name = str(data.name,".",data.num)
	player_name = data.name
	player_num = data.num
	var pal : Array[Color] = ColorHelper.generate_palette(data.team.base_color, data.team.palette, 3)
	player_color = pal.pop_front()
	secondary_color = pal.pop_front()
	tertiary_color = pal.pop_front()
	ti = data.team.starting_resources.titanium
	ga = data.team.starting_resources.gallium
	al = data.team.starting_resources.aluminum
	co = data.team.starting_resources.cobalt
	deck.setup(data.team)

signal _on_roller_spawn_complete()
@rpc("any_peer", "call_local", "reliable")
func _start_round(ids:Array=[-1,-1,-1]):
	actions.remote_set.rpc(actions.total)
	end_turn_node._reset()
	for i in 3:
		if get_roller_unit(i) == null:
			obj_ctrl.local_unit_spawn(ids[i], i)
	_on_roller_spawn_complete.emit()

func get_roller_cube(r_index:int)->Vector3i:
	return map.oddq_to_cubic( map.local_rollers[r_index] )

func get_roller_unit(r_index:int)->Unit_Node:
	var obj : Map_Object = obj_ctrl.get_first_obj_at( get_roller_cube(r_index) )
	if obj == null:
		return null
	return obj.unit

func request_grab(node:Unit_Node):
	if held_object != null:
		return
	node.walkables = request_highlight(node, true)
	node.state = node.STATES.held
	held_object = node.map_obj
func request_buy(node:Unit_Node):
	request_grab(node)
	cost_disp.set_cost(node.unit_data.cost)
	cost_disp.modulate.a = 0.5
func request_drop(node:Unit_Node):
	cost_disp.clear()
	cost_disp.modulate.a = 0.0
	node.state = node.STATES.roller
	held_object = null
func check_affordable(cost:Dictionary)->bool:
	for key:String in cost:
		if self[key.substr(0,2)] < cost[key]:
			return false
	return true
func _on_unit_bs_mode(bs:bool):
	if held_object == null:
		return
	cost_disp.flip_colors = bs
	if bs:
		cost_disp.set_cost(held_object.unit.unit_data.sale)
	else:
		cost_disp.set_cost(held_object.unit.unit_data.cost)
func request_purchase(node:Unit_Node)->bool:
	if node != held_object.unit or node == null or actions.current <= 0:
		return false
	var new_cube : Vector3i = cursor.cubic
	if !new_cube in highlighting_tiles:
		return false
	if map.map_at(new_cube) != map.AT_VALS.trash:
		if !check_affordable(node.unit_data.cost):
			return false
		apply_cost_to_res()
	return request_move(node)
func request_move(node:Unit_Node)->bool:
	if node != held_object.unit or node == null or actions.current <= 0:
		return false
	var new_cube : Vector3i = cursor.cubic
	if !new_cube in highlighting_tiles:
		return false
	map.set_highlight(highlighting_tiles, false)
	node.to_cube = new_cube
	node.turn_over = true
	node.state = node.STATES.deploy
	spend_action()
	held_object = null
	return true


var held_object : Map_Object = null:
	set(obj):
		if held_object != null:
			if obj != null:
				return
			held_object.unit.buy_sell_mode.disconnect(_on_unit_bs_mode)
			held_object.unit.held = null
			map.clear_highlight()
		held_object = obj
		cursor.held_object = obj
		if obj != null:
			obj.unit.held = cursor
			obj.unit.buy_sell_mode.connect(_on_unit_bs_mode)

func get_unit_trash_filter(unit:Unit_Node)->int:
	if unit.turn_over:
		return map.TRASH_FILTER.no
	if unit.state == unit.STATES.roller:
		if !check_affordable(unit.unit_data.cost):
			return map.TRASH_FILTER.only
	return map.TRASH_FILTER.allow

var highlighting_unit : Unit_Node = null
var highlighting_tiles : Array[Vector3i] = []
func request_highlight(unit:Unit_Node, is_plan:bool)->Array: #allowed moves
	if (unit != highlighting_unit and !is_plan) or held_object != null:
		return []
	map.set_highlight(highlighting_tiles, false)
	highlighting_tiles.clear()
	highlighting_unit = unit
	if !is_plan:
		return []
	var walkables : Array = map.get_walkables(false)
	for cube in unit.cubic_movement:
		var move_to : Vector3i = cube + unit.cubic
		if move_to in walkables:
			highlighting_tiles.append(move_to)
	return map.set_highlight(highlighting_tiles, true, get_unit_trash_filter(unit))

@onready var deck : Deck_Manager = $deck
@onready var res_disp : Cost_Data = $resources
var ti : int:
	set(val):
		ti = val
		res_disp.titanium = val
	get: return res_disp.titanium
var ga : int:
	set(val):
		ga = val
		res_disp.gallium = val
	get: return res_disp.gallium
var al : int:
	set(val):
		al = val
		res_disp.aluminum = val
	get: return res_disp.aluminum
var co : int:
	set(val):
		co = val
		res_disp.cobalt = val
	get: return res_disp.cobalt

@rpc("any_peer", "call_local", "reliable")
func sell_unit(unit:Unit_Node):
	if unit.player_num != player_num:
		return false
	cost_disp.set_cost(unit.unit_data.sale)
	cost_disp.flip_colors = true
	apply_cost_to_res()
	cost_disp.flip_colors = false

func apply_cost_to_res():
	res_disp.add_with(cost_disp)
	cost_disp.clear()
	cost_disp.modulate.a = 0.0

@onready var cost_disp : Cost_Data = $cost
var c_ti : int:
	set(val):
		ti = val
		cost_disp.titanium = val
	get: return cost_disp.titanium
var c_ga : int:
	set(val):
		ga = val
		cost_disp.gallium = val
	get: return cost_disp.gallium
var c_al : int:
	set(val):
		al = val
		cost_disp.aluminum = val
	get: return cost_disp.aluminum
var c_co : int:
	set(val):
		co = val
		cost_disp.cobalt = val
	get: return cost_disp.cobalt


