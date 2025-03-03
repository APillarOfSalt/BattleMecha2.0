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
	unit.stats._start_turn()


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
var dying : bool = false:
	set(toggle):
		dying = toggle
func do_free(death_return_sale:int=-1):
	dying = true
	if death_return_sale == 1:
		ui.unit_sale(unit)
	unit.is_now_dead.emit(unit, death_return_sale)
func get_is_dying()->bool:
	dying = dying or unit.stats.hp <= 0
	return dying

func play_death()->Signal:
	unit.def_anim_ctrl._play_death()
	return unit.def_anim_ctrl.finished

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
	if push_cube == Vector3i(0,0,0):
		return
	cubic = to_pos + push_cube
	push_cube = Vector3i(0,0,0)
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
var push_cube : Vector3i:
	set(vec): cursor.push_cube = vec
	get: return cursor.push_cube

func get_highest_wep_prio()->int:
	var highest : int = 0
	for wep_id:int in unit.cubic_weapons.keys():
		highest = max( highest, unit.unit_data.get_module(wep_id).priority )
	return highest

const exceptions : Array[String] = [""]
func get_weapon_tiles(use_cubic:bool=false)->Dictionary:
	var wep_tiles : Dictionary = {}
	for wep_id:int in unit.cubic_weapons.keys():
		wep_tiles[wep_id] = []
		if "ref" in DataLoader.modules_by_id[wep_id].abilities and to_pos != Vector3i(0,0,0):
			for i in 2:
				var cube : Vector3i = map.get_equal_cube(to_pos,bool(i))
				wep_tiles[wep_id].append( cube-to_pos )
		else:
			for cube:Vector3i in unit.cubic_weapons[wep_id]:
				wep_tiles[wep_id].append(cube)
				if use_cubic:
					wep_tiles[wep_id][-1] += to_pos
	return wep_tiles

func get_movement(use_cubic:bool=false)->Array[Vector3i]:
	var affordable : bool = check_afforable() or bought
	var movement : Array[Vector3i] = []
	for cube in unit.cubic_movement:
		if affordable or map.is_trash(cube + cubic):
			movement.append(cube)
			if use_cubic:
				movement[-1] += cubic
	return movement

const overlap_padding : int = 24
var glo_from := Vector2(-1,-1)
func start_tween():
	glo_from = unit.global_position
#false:Push ; true:Move
func tween_pos(ratio:float, push_move:bool=false):
	var to : Vector3i = to_pos # true to_pos
	if !push_move: #push
		if push_cube == Vector3i(0,0,0):
			return
		to += push_cube # false to_pos+cubic
	var glo_to : Vector2 = glo_pos_from_cube(to)
	var from_to : Vector2 = glo_to - glo_from
	if check_overlaps(to).size():
		from_to -= from_to.limit_length(overlap_padding)
	unit.global_position = glo_from + (from_to * ratio) 

func check_overlaps(cube:Vector3i):
	var others : Array[int] = []
	for obj:Map_Object in get_tree().get_nodes_in_group("map_obj"):
		if obj.id != id and obj.to_pos + obj.push_cube == cube:
			others.append(obj.id)
	return others
