extends PanelContainer

@export var obj_ctrl : Object_Controller = null

signal animation_finished(nd:Container)
func is_anim_playing()->bool:
	return anim_playing

const unit_ui_scene : PackedScene = preload("res://unit_ui.tscn")
var attacker : Unit_Node = null
@onready var atk_spr : Sprite2D = $h/off/center/Sprite2D
var weapon : Module_Data.Weapon_Data = null
var push := Vector3i(0,0,0)

var defenders : Array[Unit_Node] = []
var defenders_uis : Array[Unit_Ui] = []

func setup(atk:Unit_Node, wep:Module_Data, def:Array):
	attacker = atk
	atk_spr.frame_coords = atk.unit_data.atlas
	weapon = wep
	var has_push : bool = wep.push >= 0
	if has_push:
		push = atk.cubic_weapons_push[wep.id]
	all_nodes.append(attacker)
	for defender : Unit_Node in def:
		defenders.append(defender)
		all_nodes.append(defender)
		var def_node = defender.ui._duplicate(true, false, true)
		def_node.show_local_sprite = true
		$h/def.add_child(def_node)
		defenders_uis.append(def_node)
		if has_push:
			defender.map_obj.push_cube = push

var num_anims : int = 0
func play():
	num_anims = defenders.size()+1
	attacker.atk_anim_ctrl.finished.connect(_on_anim_complete)
	for defender in defenders:
		defender.def_anim_ctrl.finished.connect(_on_anim_complete)
	attacker.animate_attack(weapon, defenders)
	anim_playing = true
var anim_playing : bool = false
func _on_anim_complete():
	num_anims -= 1
	if num_anims <= 0:
		anim_playing = false
		animation_finished.emit(self)

var all_nodes : Array[Unit_Node] = []
func get_nodes()->Array[Unit_Node]:
	return all_nodes
func get_atk_cube()->Vector3i:
	return attacker.map_obj.to_pos
func get_aim_cubes()->Array[Vector3i]:
	var aims : Array[Vector3i] = []
	for defender in defenders:
		aims.append(defender.map_obj.to_pos)
	return aims
