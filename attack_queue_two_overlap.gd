extends PanelContainer

@export var obj_ctrl : Object_Controller = null

signal animation_finished(nd:Container)
func is_anim_playing()->bool:
	return anim_playing > -1

var glo_pos := Vector2(0,0)

var a_unit : Unit_Node = null
@onready var a_spr : Sprite2D = $h/a/center/Sprite2D
var a_weapon : Module_Data.Weapon_Data = null

var b_unit : Unit_Node = null
@onready var b_spr : Sprite2D = $h/b/center/Sprite2D
var b_weapon : Module_Data.Weapon_Data = null

var push_only : bool = false
func setup(a:Unit_Node, a_wep:Module_Data.Weapon_Data, b:Unit_Node, b_wep:Module_Data.Weapon_Data):
	a_unit = a
	a_spr.frame_coords = a_unit.unit_data.atlas
	a_weapon = a_wep
	b_unit = b
	b_spr.frame_coords = b_unit.unit_data.atlas
	b_weapon = b_wep
	push_only = a_weapon == null and b_weapon == null


func play():
	var units : Array = get_nodes()
	for i in 2:
		var unit : Unit_Node = units[i]
		var wep : Module_Data.Weapon_Data = [a_weapon, b_weapon][i]
		if wep == null:
			unit.def_anim_ctrl.finished.connect(_on_anim_complete)
			if push_only:
				unit.animate_push()
		else:
			unit.atk_anim_ctrl.finished.connect(_on_anim_complete)
			var others : Array[Unit_Node] = [units[(i+1)%3],units[(i+2)%3]]
			unit.animate_attack(wep, others)
	anim_playing = 0

var anim_playing : int = -1

func _on_anim_complete():
	anim_playing += 1
	print(a_unit.player_num, ":", b_unit.player_num, ":", anim_playing)
	if anim_playing >= 2:
		anim_playing = -1
		await Global.create_wait_timer()
		animation_finished.emit(self)

func get_nodes()->Array[Unit_Node]:
	return [a_unit, b_unit]
func get_atk_cube()->Vector3i:
	return a_unit.map_obj.to_pos
func get_aim_cubes()->Array[Vector3i]:
	return []
