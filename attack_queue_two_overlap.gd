extends PanelContainer

signal animation_finished()
func is_anim_playing()->bool:
	return anims_completed > -1


var a_unit : Unit_Node = null
@onready var a_spr : Sprite2D = $h/a/center/Sprite2D
var a_weapon : Module_Data.Weapon_Data = null

var b_unit : Unit_Node = null
@onready var b_spr : Sprite2D = $h/b/center/Sprite2D
var b_weapon : Module_Data.Weapon_Data = null

func setup(a:Unit_Node, a_wep:Module_Data, b:Unit_Node, b_wep:Module_Data):
	a_unit = a
	a_spr.frame_coords = a_unit.unit_data.atlas
	a_weapon = a_wep
	b_unit = b
	b_spr.frame_coords = b_unit.unit_data.atlas
	b_weapon = b_wep
	#a.anim_ctrl.setup_atk(a_wep, [b])
	#fx_atk._play()

func play():
	a_unit.attack_anim_complete.connect(_on_anim_complete)
	a_unit.animate_attack(a_weapon, [b_unit])
	b_unit.attack_anim_complete.connect(_on_anim_complete)
	b_unit.animate_attack(b_weapon, [a_unit])
	anims_completed = 0

var anims_completed : int = -1
func _on_anim_complete():
	anims_completed += 1
	if anims_completed == 2:
		anims_completed = -1
		animation_finished.emit()
		queue_free()
