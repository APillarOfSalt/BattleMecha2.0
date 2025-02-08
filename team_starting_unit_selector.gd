extends PanelContainer

signal unit_selected(unit_id:int)

var selected_units : Array = [-1,-1,-1]
@export_range(0,2,1) var sel_index : int = 0 
var valid_units : Dictionary #unit_id:int : num:int

var animate : bool = false:
	set(val):
		if animate == val:
			return
		animate = val
		$m/limits/anchor/TileMap/trash.animate_vis(val)
		$m/limits/anchor/TileMap/trash2.animate_vis(val)
		$m/limits/anchor/TileMap/trash3.animate_vis(val)

const no_price : Dictionary = {"titanium":0,"gallium":0,"aluminum":0,"cobalt":0}
@onready var unit_data :Unit_Data:
	set(unit):
		var atlas : Vector2i = Vector2i(6,2)
		var buy : Dictionary = no_price
		var sell : Dictionary = no_price
		if unit != null:
			atlas = unit.atlas
			buy = unit.cost
			sell = unit.sale
		unit_spr.frame_coords = atlas
		$m/h/price/m/v/cost.set_cost(buy)
		$m/h/sale/m/v/cost.set_cost(sell)
		unit_data = unit
@onready var unit_spr : Sprite2D = $m/limits/anchor/unit
func set_unit_data(unit:Unit_Data=null):
	unit_data = unit
	_refresh_map()
	var unit_id = -1
	if unit != null:
		unit_id = unit.id
	else:
		unit_sel.selected = -1
	refresh_op()
	unit_selected.emit(unit_id)

func _refresh_map():
	map.clear_layer(1)
	var cells : Array[Vector2i] = map.get_used_cells(0)
	if unit_data != null:
		var center : Vector2i = [Vector2i(-2,0), Vector2i(0,0), Vector2i(2,0)][sel_index]
		for vec in unit_data.full_movement:
			var alt_tile : int = 8
			var cell : Vector2i = center + vec
			if cell in cells:
				alt_tile = 2
			map.set_cell(1, cell, 0, Vector2i(1,0), alt_tile)

var _ready_done : bool = false
@onready var map : TileMap = $m/limits/anchor/TileMap
func _ready():
	map.position.x -= 96 * (sel_index-1)
	_ready_done = true
	set_unit_data()

func _on_option_button_item_selected(index):
	var unit : Unit_Data = null
	if index > -1:
		unit = DataLoader.units_by_id[unit_sel.get_item_id(index)]
	set_unit_data( unit )
@onready var unit_sel : OptionButton = $m/h/OptionButton
func refresh_op():
	if !_ready_done:
		return
	unit_sel.clear()
	for unit_id in valid_units.keys():
		unit_sel.add_item(DataLoader.units_by_id[unit_id].name, unit_id)
		var disable : bool = selected_units.count(unit_id) >= valid_units[unit_id]
		unit_sel.get_popup().set_item_disabled(unit_sel.item_count-1, disable)
	if unit_data != null:
		unit_sel.selected = unit_sel.get_item_index(unit_data.id)
	else:
		unit_sel.selected = -1
	unit_sel.mouse_filter = [Control.MOUSE_FILTER_IGNORE, Control.MOUSE_FILTER_STOP][clamp(unit_sel.item_count, 0,1)]


func _process(delta):
	var mouse_pos : Vector2 = get_local_mouse_position()
	animate = mouse_pos.x > 0 and mouse_pos.x < size.x and mouse_pos.y > 0 and mouse_pos.y < size.y


func _on_tile_map_do_recalc():
	valid_units.clear()
	for disp in get_tree().get_nodes_in_group("team_edit_unit_disp"):
		if disp.unit != null:
			var unit_id : int = disp.unit.id
			if !unit_id in valid_units.keys():
				valid_units[unit_id] = 0
			valid_units[unit_id] += 1
	if unit_data != null:
		if !unit_data.id in valid_units.keys():
			set_unit_data()
	selected_units = [-1,-1,-1]
	for disp in get_tree().get_nodes_in_group("team_edit_unit_sel"):
		var unit_id : int = -1
		if disp.unit_data != null:
			unit_id = disp.unit_data.id
		selected_units[disp.sel_index] = unit_id
	if unit_data != null:
		var unit_id : int = unit_data.id
		if !unit_id in valid_units.keys():
			set_unit_data()
		else:
			var count : int = valid_units[unit_id] - selected_units.count(unit_id)
			if count < 0:
				set_unit_data()
	_refresh_map()
	refresh_op()

func _on_sel_0_unit_selected(unit_id):
	selected_units[0] = unit_id
	refresh_op()
func _on_sel_1_unit_selected(unit_id):
	selected_units[1] = unit_id
	refresh_op()
func _on_sel_2_unit_selected(unit_id):
	selected_units[2] = unit_id
	refresh_op()
