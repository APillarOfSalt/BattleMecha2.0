extends TileMap

signal select_unit(id:int)
signal full_valid(is_valid:bool)
signal do_recalc()

const unit_scene : PackedScene = preload("res://team_editor_unit_disp.tscn")
var tiles : Array
var units : Array#[unit_scene]
func _ready():
	tiles = get_used_cells(0)

func get_units()->Dictionary:
	var ids : Dictionary
	for unit in units:
		if unit.unit == null:
			return {}
		var id : int = unit.unit.id
		if id in ids:
			ids[id] += 1
		else:
			ids[id] = 1
	var dict : Dictionary = {}
	for id:int in ids.keys():
		var num : int = ids[id]
		if !num in dict:
			dict[num] = []
		dict[num].append(DataLoader.units_by_id[id])
	return dict

func clear_units():
	for unit in units:
		unit.queue_free()
	units.clear()

 # data == { num:int : [Unit_Data, etc...] }
func set_units(data:Dictionary):
	clear_units()
	for i:int in 4:
		var num : int = 4-i
		if !num in data:
			continue
		for unit:Unit_Data in data[num]:
			create_unit(unit, num)
	create_unit(null,tiles.size()-units.size())
	recalc()

func create_unit(data:Unit_Data, num:int=1):
	for _i in num:
		var map_pos : Vector2i = tiles[units.size()]
		var unit = unit_scene.instantiate()
		add_child(unit)
		units.append(unit)
		unit.position = map_to_local(map_pos)
		unit.unit = data

var selected_id : int = -1: set = select
func select(unit_id:int):
	selected_id = unit_id
	select_unit.emit(unit_id)
	if unit_id == -1:
		return
	for i in get_children():
		i.selected = false
		if i.unit is Unit_Data:
			i.selected = i.unit.id == unit_id

func _on_unit_edit_unit_changed(unit:Unit_Data):
	if unit == null:
		select(-1)
	else:
		select(unit.id)
func recalc():
	do_recalc.emit()
	var all_valid : bool = true
	var all_ids : Array
	for i in units:
		if i.unit == null:
			all_valid = false
		else:
			all_ids.append(i.unit.id)
	full_valid.emit(all_valid)
	var ids : Array
	for id in all_ids:
		if all_ids.count(id) >= 4:
			ids.append(id)
	for i in units:
		i.hide_from_cap(ids)
