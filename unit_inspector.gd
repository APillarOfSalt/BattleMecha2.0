extends Container

@onready var cost : Cost_Data = $m/cost
@onready var name_l : Label = $title/anchor/name
@onready var sprite_1 : Sprite2D = $sprs/m/anchor/sprite1
@onready var sprite_2 : Sprite2D = $sprs/m/anchor/sprite2
@onready var stats : Unit_UI_Stats = $sprs/anchor/stats
@onready var stat_nums = $stat_nums


var unit : Unit_Node = null:
	set(nd):
		unit = nd
		if unit == null:
			setup_null()
		else:
			setup_unit()
func setup_null():
	name_l.text = ""
	cost.clear()
	sprite_1.hide()
	sprite_2.hide()
	stats.clear()
	stat_nums.clear()
func setup_unit():
	name_l.text = unit.unit_data.name
	cost.set_cost(unit.unit_data.cost)
	if unit.unit_data.size == 1:
		sprite_1.show()
		sprite_1.frame_coords = unit.unit_data.atlas
	else:
		sprite_2.show()
		sprite_2.frame_coords = unit.unit_data.atlas
	stats.duplicate_from(unit.stats)
	stat_nums.duplicate_from(unit.stats)


func _on_map_cursor_new_top_hover(obj):
	unit = obj.unit
