extends Node2D
class_name Unit_Node

signal state_changed(st:STATES)
signal is_now_dead(node:Unit_Node, death_sale:bool)
signal unit_hovered(unit:Unit_Node, is_hovered:bool)
signal buy_sell_mode(bs:bool)

func _kill_me():
	is_now_dead.emit(self, false)
func _sell_me():
	is_now_dead.emit(self, true)
func get_is_dying()->bool:
	return anim_ctrl.active_anim == anim_ctrl.DEF_ANIM.death

const mat : Material = preload("res://assets/outlineShader.tres")
const shader : Shader = preload("res://outline.gdshader")

var map_obj : Map_Object = null

var bought : bool = false
var player_num : int = -1
var locally_owned : bool = false
var turn_over : bool = false:
	set(toggle):
		turn_over = toggle
		tint_outline = toggle
		sprite_tint.a = int(toggle)*0.5
		if !toggle:
			refresh_afford()

var player_color : Color:
	set(color):
		player_color = color
		spr_mat.set_shader_parameter("color", player_color)
		var hsv : Vector4 = Global.rgb_to_hsv(player_color)
		hsv *= Vector4(0,0.9,0.9,1.0)
		var accent := Color.from_hsv(hsv.x, hsv.y, hsv.z, hsv.w)


var unit_data : Unit_Data = null:
	set(data):
		unit_data = data
		if spr1 != null:
			#$anchor/defense_anim.unit_atlas = unit_data.atlas
			hp = unit_data.hp
			armor = unit_data.armor
			shield = unit_data.shield_start
			refresh()
var hp : int = 0
var armor : int = 0
var shield : int = 0

func _start_turn():
	turn_over = false
	sprite_tint.a = 0.0
	if state == STATES.roller:
		refresh_afford()


@rpc("any_peer", "call_remote", "reliable")
func _remote_state_set(val:STATES):
	state = val

enum STATES{roller=-1,held=0,deploy=1,ready=2}
@export_enum("Display:-2","Roller:-1","Held:0","Deployed:1","Ready:2") var state : int = STATES.roller:
	set(val):
		state = val
		$anchor/unit_ui.show_cost = val == STATES.roller
		state_changed.emit(val)
		if locally_owned:
			_remote_state_set.rpc(val)
const STATE_STRS : Array[String] = ["Display","Roller","Held","Deployed","Ready"]
func get_state_str()->String:
	return STATE_STRS[state+2]

var spr_mat : Material
func set_spr_mat()->Material:
	spr_mat = mat.duplicate(true)
	spr_mat.shader = shader.duplicate(true)
	spr_mat.set_shader_parameter("width", 0)
	return spr_mat.duplicate(true)
func _ready():
	if state == -2:
		set_spr_mat()
	if state <= STATES.roller:
		ui.popup()
	spr1.material = spr_mat
	spr2.material = spr_mat
	stats = ui.stats
	anim_ctrl.stats = stats
	refresh()
	ui.position = -ui.offset
	refresh_afford()

func refresh_afford():
	if state < STATES.roller:
		return
	sprite_tint = Color(0.0,0.0,0.0,0.3)
	if state != STATES.roller or !locally_owned:
		return
	sprite_tint.a = float(!controller.check_affordable(unit_data.cost)) * 0.5

func refresh():
	ui.unit = unit_data
	false
	if unit_data == null:
		spr1.visible = true
		spr1.frame_coords = Vector2i(6,2)
		spr2.visible = false
		return
	var toggle : bool = unit_data.size == 1
	spr1.visible = toggle
	spr2.visible = !toggle
	if toggle:
		spr1.frame_coords = unit_data.atlas
	else:
		spr2.frame_coords = unit_data.atlas

var tint_outline : bool = false:
	set(toggle):
		tint_outline = toggle
		spr_mat.set_shader_parameter("tint_outline", toggle)
const outline_width : int = 2
var outline_size : int = 0:
	set(val):
		outline_size = val
		spr_mat.set_shader_parameter("width", val)
var sprite_tint : Color = Color(0,0,0,0):
	set(col):
		sprite_tint = col
		spr_mat.set_shader_parameter("tint", col)

@onready var anchor : Node2D = $anchor
@onready var spr1 : Sprite2D = $anchor/s1
@onready var spr2 : Sprite2D = $anchor/s2
@onready var spr_scale : Vector2 = spr1.scale
@onready var ui : Container = $anchor/unit_ui
@onready var anim_ctrl : Animation_Controller = $anchor/animation_controller
var stats : Unit_UI_Stats = null

var cubic_movement : Array[Vector3i] = []
var cubic_weapons : Dictionary = {} #weapon_id:int : [Vector3i(),etc...],
var cubic_weapons_push : Dictionary = {} #weapon_id:int : cube:Vector3i(),

@export var map : TileMap
var controller : Player_UI = null
var cubic : Vector3i
var to_cube : Vector3i = cubic

var buy_sell : bool = false:
	set(toggle):
		buy_sell = toggle
		buy_sell_mode.emit(buy_sell)
var held : Map_Cursor = null:
	set(cursor):
		held = cursor
		if map_obj != null:
			map_obj.held = cursor
		if cursor == null:
			outline_size = min(outline_size,outline_width)
			anchor.position = Vector2(0,0)
		else:
			outline_size = outline_width*2
var walkables : Array = []
var hovered : bool = false
func cursor_hover(is_hovered:bool):
	if hovered and !is_hovered:
		hovered = false
	elif !hovered and is_hovered:
		hovered = true
	else: #if the hover state isn't being changed
		return
	if outline_size <= outline_width:
		outline_size = int(is_hovered)*outline_width
	spr1.z_index = 1
	spr2.z_index = 1
	ui.z_index = 0
	if is_hovered:
		spr1.z_index = 3
		spr2.z_index = 3
		ui.z_index = 2
		ui.popup()
	elif state > STATES.held:
		ui.hide()
	if controller != null:
		controller.request_highlight(self, is_hovered)
		unit_hovered.emit(self, is_hovered)

func cursor_accept():
	if !locally_owned:
		return
	if state == STATES.roller:
		controller.request_buy(self)
	elif state == STATES.deploy and !turn_over:
		controller.request_grab(self)
	elif state == STATES.held and held != null:
		if held.cubic == cubic:
			controller.request_drop(self)
		elif !bought:
			bought = controller.request_purchase(self)
			if !bought:
				return
		else:
			controller.request_move(self)

func cursor_cancel():
	if !locally_owned:
		return
	if state == STATES.held:
		controller.request_drop(self)

signal attack_anim_started(end_time_msec:int)
signal attack_anim_complete()
func animate_attack(wep:Module_Data.Weapon_Data, defense:Array[Unit_Node])->Signal:
	anim_ctrl.setup_atk(wep, defense)
	return attack_anim_started

func _on_animation_controller_started(end_time_msec):
	attack_anim_started.emit(end_time_msec)

func get_dmg_type(wep:Module_Data.Weapon_Data)->Module_Data.DMG_TYPES:
	var dmg_type : Module_Data.DMG_TYPES = -2
	if wep.subtype == "Melee":
		dmg_type = Module_Data.DMG_TYPES.percussive
	elif wep.subtype == "Rifle":
		dmg_type = Module_Data.DMG_TYPES.percussive
	elif wep.subtype == "Laser" or wep.subtype == "Coil":
		dmg_type = Module_Data.DMG_TYPES.voltaic
	elif wep.subtype == "Cannon" or wep.subtype == "Launcher":
		dmg_type = Module_Data.DMG_TYPES.concussive
	return dmg_type

func calc_cubic():
	cubic_movement.clear()
	for vec in unit_data.full_movement:
		cubic_movement.append( map.oddq_to_cubic(vec, player_num) )
	cubic_weapons.clear()
	cubic_weapons_push.clear()
	for mod in unit_data.weapons:
		cubic_weapons[mod.id] = []
		for oddq:Vector2i in mod.hex_shape:
			cubic_weapons[mod.id].append( map.oddq_to_cubic(oddq, player_num) )
		if mod.push in range(6):
			cubic_weapons_push[mod.id] = map.oddq_to_cubic( Global.directions_evenx[mod.push] )


