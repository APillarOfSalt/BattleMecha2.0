extends PanelContainer

@export var obj_ctrl : Object_Controller = null

signal animation_finished()
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
	if wep.push >= 0:
		push = atk.cubic_weapons_push[wep.id]
	for defender : Unit_Node in def:
		defenders.append(defender)
		defenders_uis.append(_create_defender(defender))

var def_push : Dictionary = {}
func _create_defender(def:Unit_Node)->Unit_Ui:
	var def_node = def.ui._duplicate(true, false, true)
	$h/def.add_child(def_node)
	defenders_uis.append(def_node)
	def_push.clear()
	if push == Vector3i(0,0,0):
		return def_node
	if !def.player_num in def_push.keys():
		def_push[def.player_num] = {}
	var obj : Map_Object = def.map_obj
	if !obj.id in def_push[def.player_num]:
		def_push[def.player_num][obj.id] = {}
	def_push[def.player_num][obj.id].cube = obj.to_pos
	def_push[def.player_num][obj.id].to = obj.to_pos + push
	return def_node

func play():
	attacker.anim_ctrl.finished.connect(_on_anim_complete)
	attacker.anim_ctrl.setup_atk(weapon, defenders)
	attacker.anim_ctrl._play()
	if def_push.size():
		obj_ctrl._on_server_positions(def_push)
	anim_playing = true
var anim_playing : bool = false
func _on_anim_complete():
	anim_playing = false
	await get_tree().create_timer(0.01).timeout
	animation_finished.emit()
