extends GridContainer
class_name Unit_Editor

@export var is_dev : bool = false


func _on_module_backdrop_refresh_movement(move_arr):
	move_edit.bonus_tiles = move_arr
var unit : Unit_Data = null:
	set(data):
		unit = data
		s1_spr.hide()
		s2_spr.hide()
		if data == null:
			name_l.text = ""
			debug_sel.selected = -1
			mod_back.clear()
			move_edit.clear()
			return
		name_l.text = data.name
		mod_back.unit = data
		move_edit.tiles = data.movement
		if data.size == 1:
			s1_spr.show()
			s1_spr.frame_coords = data.atlas
		else:
			s2_spr.show()
			s2_spr.frame_coords = data.atlas
@onready var name_l : Label = $unit_disp/unit/title/anchor/scale/Label
@onready var s1_spr : Sprite2D = $unit_disp/spr/anchor/s1
@onready var s2_spr : Sprite2D = $unit_disp/spr/anchor/s2
@onready var mod_back : Module_Backdrop = $module_backdrop
@onready var move_edit : Container = $unit_props/move

@onready var debug_sel : Option_Button = $unit_disp/sel/unit_sel
func _ready():
	mod_back.is_dev = is_dev
	$unit_disp/sel/save_batch.visible = is_dev
	debug_sel.clear()
	var keys : Array = DataLoader.units_by_id.keys().duplicate(true)
	keys.sort()
	for id:int in keys:
		var unit : Unit_Data = DataLoader.units_by_id[id]
		var text : String = str(id,":",unit.name)
		debug_sel.add_item(text, id)
	debug_sel.selected = -1
func _on_debug_item_selected(index:int):
	var id : int = debug_sel.get_item_id(index)
	if unit is Unit_Data:
		if unit.id == id:
			return
	if index == -1:
		unit = null
	else:
		unit = DataLoader.units_by_id[id]
	mod_back.refresh()

func _on_save_pressed():
	if unit == null:
		return
	unit.modules.clear()
	unit.set_modules.clear()
	for mod:Module_Blocks in mod_back.modules:
		var data : Array = [mod.backdrop_pos, mod.module]
		if mod.lock_module:
			unit.set_modules.append( data )
		else:
			unit.modules.append( data )
	unit.movement = move_edit.get_data()
	DataLoader.units_by_id[unit.id] = unit

func _on_save_batch_pressed():
	DataLoader.units_to_memory()

func _on_tile_map_select_unit(id:int):
	debug_sel.selected = debug_sel.get_item_index(id)

func _on_main_menu_pressed():
	Global.to_main_menu_scene()

