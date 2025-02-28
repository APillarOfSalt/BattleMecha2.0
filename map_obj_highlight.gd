extends TileMap
class_name Movement_Highlighter

@onready var obj : Map_Object = get_parent()
var global_map : TileMap:
	get: return obj.map
var unit : Unit_Node:
	get: return obj.unit
var cubic : Vector3i:
	get: return obj.cubic
var to_cube : Vector3i:
	get: return obj.to_pos

func highlight_movement(io:bool):
	clear_layer(0)
	clear_layer(1)
	if !io:
		return
	var allowed_moves : Array[Vector3i] = obj.get_movement()
	for cube:Vector3i in unit.cubic_movement:
		var layer : int = 0
		if !cube in allowed_moves:
			layer = 1
		set_cell(layer, global_map.cubic_to_oddq(cube), 0, Vector2i(1,0))
