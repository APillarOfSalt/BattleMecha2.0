extends TileMap
class_name Combat_Highlighter

@onready var obj : Map_Object = get_parent()

var global_map : TileMap:
	get: return obj.map
var unit : Unit_Node:
	get: return obj.unit
var cubic : Vector3i:
	get: return obj.cubic
var to_cube : Vector3i:
	get: return obj.to_pos

var is_highlighting : bool = false
func highlight_attack(io:bool):
	is_highlighting = io
	clear_layer(0)
	clear_layer(2)
	if !io:
		return
	var wep_tiles : Dictionary = obj.get_weapon_tiles()
	for wep_id:int in wep_tiles.keys():
		for cube:Vector3i in wep_tiles[wep_id]:
			var oddq : Vector2i = global_map.cubic_to_oddq(cube)
			print(cube, oddq)
			set_cell(0, oddq, 0, Vector2i(1,0))
	var heal_tiles : Dictionary = obj.get_heal_tiles()
	for heal_id:int in heal_tiles.keys():
		for cube:Vector3i in heal_tiles[heal_id]:
			var oddq : Vector2i = global_map.cubic_to_oddq(cube)
			print(cube, oddq)
			set_cell(2, oddq, 0, Vector2i(1,0))
