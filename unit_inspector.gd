extends Container

@onready var cost : Cost_Data = $m/cost
@onready var name_l : Label = $title/anchor/name
@onready var sprite_1 : Sprite2D = $sprs/m/anchor/sprite1
@onready var sprite_2 : Sprite2D = $sprs/m/anchor/sprite2
@onready var stats : Unit_UI_Stats = $sprs/anchor/stats
@onready var stat_nums = $stat_nums

var object : Map_Object = null:
	set(obj):
		if object != null:
			if obj.id == object.id:
				return
		object = obj
		unit = obj.unit
var unit : Unit_Node = null:
	set(nd):
		unit = nd
		if unit == null:
			setup_null()
		else:
			setup_unit()
func setup_null():
	name_l.text = ""
	cost.flip_colors = false
	cost.clear()
	sprite_1.hide()
	sprite_2.hide()
	stats.clear()
	stat_nums.clear()
func setup_unit():
	name_l.text = unit.unit_data.name
	if unit.unit_data.size == 1:
		sprite_1.show()
		sprite_1.frame_coords = unit.unit_data.atlas
	else:
		sprite_2.show()
		sprite_2.frame_coords = unit.unit_data.atlas
	stats.duplicate_from(unit.stats)
	stat_nums.duplicate_from(unit.stats)
	refresh_cost()


func _on_map_cursor_new_top_hover(obj:Map_Object):
	object = obj

var sale : bool = false:
	set(toggle):
		if sale == toggle or unit == null:
			return
		sale = toggle
		refresh_cost()
func refresh_cost():
	cost.flip_colors = sale
	if sale:
		cost.set_cost(unit.unit_data.sale)
	else:
		cost.set_cost(unit.unit_data.cost)
func _on_map_cursor_hover_trash(is_trash:bool):
	sale = is_trash
