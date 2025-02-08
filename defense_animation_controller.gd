extends Node2D
class_name Defense_Animation_Controller

var unit_atlas : Vector2i:
	set(vec):
		$mask.frame_coords = vec

 #-1:shield_break, 0:hit, +1:shield_hit
const ANIMS : Array[String] = ["shield_break","hit","shield_hit","death"]
var anim : int = 0
func setup(type:Module_Data.DMG_TYPES, arg:int):
	$shield.visible = arg != 0
	anim = arg + 1
	set_dmg(type)

var dmg_type : Module_Data.DMG_TYPES = -2
func set_dmg(type:Module_Data.DMG_TYPES=-1):
	$melee_hit.visible = type == -1
	$p_hit.visible = type == Module_Data.DMG_TYPES.percussive
	$v_hit.visible = type == Module_Data.DMG_TYPES.voltaic
	$mask.visible = type == Module_Data.DMG_TYPES.voltaic
	$c_hit.visible = type == Module_Data.DMG_TYPES.concussive


