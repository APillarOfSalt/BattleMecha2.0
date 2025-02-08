extends TileMap

enum TILES{W=0, K=1, R=2, G=3, B=4, C=5, M=6, Y=7, A=8} #A==Gray
const tile_assignments : Dictionary = {
	TILES.W : "",
	TILES.K : "Scrapyard",
	TILES.R : "Left Opponent",
	TILES.G : "Friendly",
	TILES.B : "Right Opponent",
	TILES.C : "Hand Tiles",
	TILES.M : "Roller Tiles",
	TILES.Y : "Base Tiles",
	TILES.A : "Objective",
}
const walkable : Array = [TILES.R,TILES.G,TILES.B,TILES.Y,TILES.A]

@export var hand_l : Hand_Tile
@export var hand_r : Hand_Tile

var objects : Array:
	get: return get_tree().get_nodes_in_group("object")

func get_hand_tile_map_pos(l_r:bool):
	var hand : Hand_Tile = [hand_l,hand_r][int(l_r)]
	var hand_pos : Vector2i = local_to_map(to_local(hand.global_position))
	var relative : Vector2i = Global.get_relative(hand_pos.x, hand.pos)
	return relative+hand_pos

func set_highlight(area:Array, is_on:bool):
	for pos in area:
		if is_on:
			set_cell(1, pos, 1, Vector2i(1,0))
		else:
			set_cell(1, pos)

func get_walkables(ignore_objs:bool=false):
	var tiles : Array = all_walkable_tiles()
	if ignore_objs:
		return tiles
	return check_objs(tiles)
func all_walkable_tiles():
	var tiles : Array
	for pos in get_used_cells(0):
		var alt_id : int = get_cell_alternative_tile(0, pos, true)
		if alt_id in walkable:
			tiles.append(pos)
	for i in 2:
		tiles.append(get_hand_tile_map_pos(i))
	return tiles

func check_objs(tiles:Array):
	for obj in objects:
		var pos = obj.get("map_pos")
		if pos is Vector2i:
			var found : int = tiles.find(pos)
			if found >= 0:
				tiles.remove_at(found)
	return tiles




