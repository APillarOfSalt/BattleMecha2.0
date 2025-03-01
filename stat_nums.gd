extends HBoxContainer

var hp := Vector2i(0,0)
@onready var hp_c_l : Label = $hp/m/current/val
@onready var hp_m_l : Label = $hp/m/max/val
var armor : int = 0
@onready var armor_l = $armor/Label
var shield := Vector3i(0,0,0) #current, max, regen
@onready var s_c_l : Label = $shield/h/m/h/current/val
@onready var s_m_l : Label = $shield/h/m/h/max/val
@onready var s_r_l : Label = $shield/h/regen/val

func clear():
	hp.x = 0
	hp_c_l.text = "0"
	hp.y = 0
	hp_m_l.text = "0"
	armor = 0
	armor_l.text = "0"
	shield.x = 0
	s_c_l.text = "0"
	shield.y = 0
	s_m_l.text = "0"
	shield.z = 0
	s_r_l.text = "0"
	

func duplicate_from(from:Unit_UI_Stats):
	hp.x = from.hp
	hp_c_l.text = str(from.hp)
	hp.y = from.hp_max
	hp_m_l.text = str(from.hp_max)
	armor = from.armor
	armor_l.text = str(from.armor)
	shield.x = from.shield
	s_c_l.text = str(from.shield)
	shield.y = from.shield_max
	s_m_l.text = str(from.shield_max)
	shield.z = from.shield_regen
	s_r_l.text = str(from.shield_regen)

