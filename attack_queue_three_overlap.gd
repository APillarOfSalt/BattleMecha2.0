extends PanelContainer

@export var obj_ctrl : Object_Controller = null

signal animation_finished()
func is_anim_playing()->bool:
	return anim_playing > -1

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
	if a_weapon == null:
		a_unit.anim_ctrl.finished_defense.connect(_on_anim_complete)
	else:
		a_unit.anim_ctrl.finished.connect(_on_anim_complete)
	if b_weapon == null:
		b_unit.anim_ctrl.finished_defense.connect(_on_anim_complete)
	else:
		b_unit.anim_ctrl.finished.connect(_on_anim_complete)
	if c_weapon == null:
		c_unit.anim_ctrl.finished_defense.connect(_on_anim_complete)
	else:
		c_unit.anim_ctrl.finished.connect(_on_anim_complete)
	a_unit.animate_attack(a_weapon, [b_unit,c_unit])
	b_unit.animate_attack(b_weapon, [a_unit,c_unit])
	c_unit.animate_attack(c_weapon, [a_unit,b_unit])
	a_unit.anim_ctrl._play()
	b_unit.anim_ctrl._play()
	c_unit.anim_ctrl._play()
	anim_playing = 0

var anim_playing : int = -1

func _on_anim_complete():
	anim_playing += 1
	print(a_unit.player_num, ":", b_unit.player_num, ":", c_unit.player_num, ":", anim_playing)
	if anim_playing >= 3:
		anim_playing = -1
		await Global.create_wait_timer()
		animation_finished.emit()

func get_nodes()->Array[Unit_Node]:
	return [a_unit, b_unit, c_unit]
func get_atk_cube()->Vector3i:
	return a_unit.map_obj.to_pos
func get_aim_cubes()->Array[Vector3i]:
	return []
