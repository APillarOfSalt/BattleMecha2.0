extends TileMap

###OLD CODE####

var all_units : Dictionary:
	get: return DataLoader.units_by_id

@export var editor : Unit_Editor
@onready var unit_spaces : Dictionary = {
	1: get_used_cells_by_id(0, 1, Vector2i(1,0)),
	2: get_used_cells_by_id(0, 1, Vector2i(0,0))
} 
var unit_nodes : Dictionary = {
	1: [],
	2: []
}
const unit_scene : PackedScene = preload("res://unit_node.tscn")

func _ready():
	for id:int in all_units.keys():
		add_unit(id)

func add_unit(id:int):
	var unit : Unit_Node = unit_scene.instantiate()
	unit.unit_data = all_units[id]
	var size = all_units[id].size
	unit.state = unit.STATES.roller
	unit.map = self
	add_child(unit)
	var map_pos : Vector2i = unit_spaces[size][unit_nodes[size].size()]
	unit.map_pos = map_pos
	unit.position = map_to_local(map_pos)
	unit_nodes[size].append(unit)
	unit.unit_hovered.connect(unit_hovered)
	unit.request_buy.connect(unit_selected)

func unit_hovered(unit:Unit_Node, is_hovered:bool):
	if is_hovered:
		if editor.debug_sel.selected == -1:
			editor.unit = unit.unit_data

func unit_selected(unit:Unit_Node, is_selected:bool):
	if is_selected:
		editor.debug_sel.selected_id = unit.unit_data.id
		editor.unit = unit.unit_data

func _on_unit_edit_unit_changed(unit:Unit_Data):
	for size:int in unit_nodes.keys():
		for node:Unit_Node in unit_nodes[size]:
			var outline : bool = false
			if unit != null:
				if node.unit_data.id == unit.id:
					outline = true
			node.outline_size = 2*int(outline)
