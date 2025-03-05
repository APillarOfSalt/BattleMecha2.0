extends HBoxContainer
class_name Detailed_Unit_Display

var unit: Unit_Data = null: set = unit_setter
@onready var name_l : Label = $v/title/m/name
@onready var cost : Container = $v/cost
@onready var s1_spr : Sprite2D = $v/sprites/anchor/size1
@onready var s2_spr : Sprite2D = $v/sprites/anchor/size2
@onready var hp_l : Label = $v/hp_armor/hp/m/h/Label
@onready var armor_l : Label = $v/hp_armor/armor/m/h/Label
@onready var max_l : Label = $v/shields/max/m/h/Label
@onready var start_l : Label = $v/shields/start/m/h/Label
@onready var regen_l : Label = $v/shields/regen/m/h/Label

func unit_setter(data:Unit_Data):
	unit = data
	if data == null:
		unit_null_setter()
	else:
		unit_valid_setter(data)


func unit_valid_setter(data:Unit_Data):
	name_l.text = data.name
	cost.setup(data)
	s1_spr.visible = data.size == 1
	if data.size == 1:
		s1_spr.frame_coords = data.atlas
	s2_spr.visible = data.size == 2
	if data.size == 2:
		s2_spr.frame_coords = data.atlas
	loadout_manager.setup(data)
func unit_null_setter():
	name_l.text = ""
	cost.clear()
	s1_spr.hide()
	s2_spr.hide()
	loadout_manager.clear()


@onready var loadout_manager : Container = $loadout/content

