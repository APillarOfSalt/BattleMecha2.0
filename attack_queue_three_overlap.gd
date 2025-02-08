extends PanelContainer

signal animation_finished()
func is_anim_playing()->bool:
	return anims_completed > -1

@onready var a_spr : Sprite2D = $m/h/a/center/Sprite2D
var a_unit : Unit_Node = null
var a_weapon : Module_Data.Weapon_Data = null
@onready var b_spr : Sprite2D = $m/h/bottom/b/spr/center/Sprite2D
var b_unit : Unit_Node = null
var b_weapon : Module_Data.Weapon_Data = null
@onready var c_spr : Sprite2D = $m/h/bottom/c/spr/center/Sprite2D
var c_unit : Unit_Node = null
var c_weapon : Module_Data.Weapon_Data = null

func setup(a:Unit_Node, a_wep:Module_Data, b:Unit_Node, b_wep:Module_Data,c:Unit_Node,c_wep:Module_Data):
	a_unit = a
	a_spr.frame_coords = a_unit.unit_data.atlas
	a_weapon = a_wep
	b_unit = b
	b_spr.frame_coords = b_unit.unit_data.atlas
	b_weapon = b_wep
	c_unit = c
	c_spr.frame_coords = c_unit.unit_data.atlas
	c_weapon = c_wep

func play():
	a_unit.attack_anim_complete.connect(_on_anim_complete)
	a_unit.animate_attack(a_weapon, [b_unit,c_unit])
	b_unit.attack_anim_complete.connect(_on_anim_complete)
	b_unit.animate_attack(b_weapon, [a_unit,c_unit])
	c_unit.attack_anim_complete.connect(_on_anim_complete)
	c_unit.animate_attack(c_weapon, [a_unit,b_unit])
	anims_completed = 0

var anims_completed : int = -1
func _on_anim_complete():
	anims_completed += 1
	if anims_completed == 3:
		anims_completed = -1
		animation_finished.emit()
		queue_free()
