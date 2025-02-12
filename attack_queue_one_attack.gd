extends PanelContainer

signal animation_finished()
func is_anim_playing()->bool:
	return anim_playing

const unit_ui_scene : PackedScene = preload("res://unit_ui.tscn")
var attacker : Unit_Node = null
@onready var atk_spr : Sprite2D = $h/off/center/Sprite2D
var weapon : Module_Data.Weapon_Data = null

var defenders : Array[Unit_Node] = []
var defenders_uis : Array[Unit_Ui] = []

func setup(atk:Unit_Node, wep:Module_Data, def:Array):
	attacker = atk
	atk_spr.frame_coords = atk.unit_data.atlas
	weapon = wep
	for defender : Unit_Node in def:
		defenders.append(defender)
		defenders_uis.append(_create_defender(defender))

func _create_defender(def:Unit_Node)->Unit_Ui:
	var def_node = def.ui._duplicate(true, false, true)
	$h/def.add_child(def_node)
	defenders_uis.append(def_node)
	return def_node

func play():
	attacker.anim_ctrl.finished.connect(_on_anim_complete)
	attacker.anim_ctrl.setup_atk(weapon, defenders)
	attacker.anim_ctrl._play()
	anim_playing = true
var anim_playing : bool = false
func _on_anim_complete():
	anim_playing = false
	await get_tree().create_timer(0.01).timeout
	animation_finished.emit()
