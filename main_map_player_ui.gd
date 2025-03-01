extends VBoxContainer
class_name Player_UI

signal out_of_actions()
func _on_actions_actions_changed(remain:int):
	if remain == 0:
		end_turn_node._on_out_of_actions()
		out_of_actions.emit()
	for obj:Map_Object in obj_ctrl.get_all_local_roller_objs():
		obj.unit.refresh_afford(remain)

var victory_points : int = 0
func gain_points(val:int):
	victory_points += val
	$victory_points/Label2.text = str(victory_points)

func start_round():
	actions.reset_actions()
	end_turn_node._reset()
	for obj:Map_Object in obj_ctrl.get_all_roller_objs():
		obj._start_turn()
func end_action_phase():
	end_turn_node._set_butt_mouse_off()

@onready var end_turn_node : Container = $end_turn

@export var map : TileMap
@export var obj_ctrl : Object_Controller
@export var cursor : Node2D = null
@onready var actions : Container = $actions

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
	set_multiplayer_authority(data.peer_id, true)
	if multiplayer.get_unique_id() != data.peer_id:
		end_turn_node.locally_owned = false
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

func unit_sale(unit:Unit_Node):
	if unit.player_num != player_num:
		print("oop",unit)
		return false
	res_disp.mod_cost_by(unit.unit_data.sale)
	_remote_res_set.rpc(ti, ga, al, co)
@rpc("any_peer", "call_remote", "reliable")
func _remote_res_set(_ti:int,_ga:int,_al:int,_co:int):
	ti = _ti
	ga = _ga
	al = _al
	co = _co

func check_affordable(cost:Dictionary)->bool:
	for key:String in cost:
		if self[key.substr(0,2)] < cost[key]:
			return false
	return true

func apply_cost_to_res():
	res_disp.add_with(cost_disp)
	cost_disp.clear()
	cost_disp.modulate.a = 0.0
	_remote_res_set.rpc(ti, ga, al, co)
	

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



#@rpc("any_peer", "call_local", "reliable")
#func sell_unit(unit:Unit_Node):
	#print("RPC:sell_unit(unit:Unit_Node):[id:",unit.map_obj.id,",name:",unit.unit_data.name,"]\n",
		#"from:",multiplayer.get_remote_sender_id(),
		#", p:",Global.server_controller.instance_id,
		#", on:",multiplayer.get_unique_id(),"\n","@:",Time.get_ticks_msec())
	#if unit.player_num != player_num:
		#print("oop",unit)
		#return false
	#cost_disp.set_cost(unit.unit_data.sale)
	#cost_disp.flip_colors = true
	#apply_cost_to_res()
	#cost_disp.flip_colors = false

