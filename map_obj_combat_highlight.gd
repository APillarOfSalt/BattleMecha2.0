extends TileMap
class_name Combat_Highlighter

@onready var obj : Map_Object = get_parent().get_parent()

var global_map : TileMap:
	get: return obj.map
var unit : Unit_Node:
	get: return obj.unit
var cubic : Vector3i:
	get: return obj.cubic
var to_cube : Vector3i:
	get: return obj.to_pos

func highlight_attack(io:bool):
	clear_layer(0)
	if !io:
		return
	for wep_id:int in unit.cubic_weapons.keys():
		for cube:Vector3i in unit.cubic_weapons[wep_id]:
			set_cell(0, global_map.cubic_to_oddq(cube), 0, Vector2i(1,0))
