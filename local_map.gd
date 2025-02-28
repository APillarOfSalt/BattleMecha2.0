extends TileMap

var local_player : int:
	get: return get_parent().get_player_num()

func get_rollers(index:int)->Array:
	return [local_rollers, next_rollers, prev_rollers][(index +3- local_player) % 3]

var prev_tiles : Array[Vector2i]
var prev_rollers : Array[Vector2i] = [Vector2i(-3,-4),Vector2i(-4,-2),Vector2i(-5,-1)]
var prev_trash : Array[Vector2i] = [Vector2i(-4,-3),Vector2i(-5,-3),Vector2i(-5,-2)]
var prev_shared : Array[Vector2i]

var local_tiles : Array[Vector2i]
var local_rollers : Array[Vector2i] = [Vector2i(-2,4),Vector2i(0,4),Vector2i(2,4)]
#@onready var roller_nodes : Array = [$roller0,$roller1,$roller2]
var local_trash : Array[Vector2i] = [Vector2i(-1,4),Vector2i(0,5),Vector2i(1,4)]
@onready var trash_nodes : Array = [$trash0,$trash1,$trash2]
var next_shared : Array[Vector2i]
var local_roller_nodes : Array[Unit_Roller]

var next_tiles : Array[Vector2i]
var next_rollers : Array[Vector2i] = [Vector2i(5,-1),Vector2i(4,-2),Vector2i(3,-4)]
var next_trash : Array[Vector2i] = [Vector2i(5,-2),Vector2i(5,-3),Vector2i(4,-3)]
var not_shared : Array[Vector2i]
#const roller_scene : PackedScene = preload("res://unit_roller.tscn")
func _refresh():
	local_tiles = get_used_cells_by_id(0,0,Vector2i(1,0),1)
	#local_rollers = get_used_cells_by_id(0,0,Vector2i(0,0),1)
	next_tiles = get_used_cells_by_id(0,0,Vector2i(1,0),3)
	#next_rollers = get_used_cells_by_id(0,0,Vector2i(0,0),3)
	prev_tiles = get_used_cells_by_id(0,0,Vector2i(1,0),2)
	#prev_rollers = get_used_cells_by_id(0,0,Vector2i(0,0),2)
	
	prev_shared = get_used_cells_by_id(0,0,Vector2i(1,0),6)
	prev_shared.sort_custom(sort_vecs)
	next_shared = get_used_cells_by_id(0,0,Vector2i(1,0),5)
	next_shared.sort_custom(sort_vecs)
	not_shared = get_used_cells_by_id(0,0,Vector2i(1,0),4)
	#for i in 3 - local_roller_nodes.size():
		#var roller : Unit_Roller = roller_scene.instantiate()
		#roller.map = self
		#var cubic : Vector3i = oddq_to_cubic(local_rollers[i])
		#add_child(roller)
		#local_roller_nodes.append(roller)
		#roller.global_position = to_global(map_to_local(cubic_to_oddq(cubic)))
	#do_labels()

func do_labels():
	for i in all_walkable_tiles():
		var l := Label.new()
		add_child(l)
		l.text = str(i)
		l.position = map_to_local(cubic_to_oddq(i))-Vector2(32,16)

func recolor():
	var rollers : Array = [local_rollers, next_rollers, prev_rollers]
	var tiles : Array = [local_tiles, next_tiles, prev_tiles]
	var shared : Array = [next_shared, not_shared, prev_shared]
	var trash : Array = [prev_trash, local_trash, next_trash]
	var mix_color : Vector3
	for i in 3:
		var index : int = (local_player + i) % 3
		var team : Team_Data = Global.player_info_by_num[index].team
		var color : Color = team.base_color
		tile_set.get_source(1).get_tile_data(Vector2i(index+1,0), 1).modulate = team.get_color(1)
		get_cell_tile_data(0, rollers[i][0]).modulate = color
		get_cell_tile_data(0, tiles[i][0]).modulate = color
		var next : int = (local_player + i+1) % 3
		var col_n : Color = Global.player_info_by_num[next].team.base_color
		var mix : Color = Global.mix_colors( color, col_n )
		get_cell_tile_data(0, shared[i][0]).modulate = mix
		get_cell_tile_data(0, trash[i][0]).modulate = mix
		mix_color.x += color.r
		mix_color.y += color.g
		mix_color.z += color.b
	mix_color /= 3.0
	get_cell_tile_data(0, Vector2i(0,0)).modulate = Color(mix_color.x, mix_color.y, mix_color.z)
	clear_layer(2)

@onready var obj_ctrl : Object_Controller = $obj_controller 

func is_trash(cube:Vector3i)->bool:
	return map_at(cube) == AT_VALS.trash
func is_roller(cube:Vector3i)->bool:
	return map_at(cube) == AT_VALS.roller
func is_tile(cube:Vector3i)->bool:
	return map_at(cube) == AT_VALS.tile
enum AT_VALS{empty=0, tile=1, trash=2, roller=3}
func map_at(cubic:Vector3i)->AT_VALS:
	var oddq : Vector2i = cubic_to_oddq(cubic)
	if oddq in local_rollers:
		return AT_VALS.roller
	elif oddq in local_trash:
		return AT_VALS.trash
	elif cubic in all_walkable_tiles():
		return AT_VALS.tile
	return AT_VALS.empty

func get_walkables(ignore_objs:bool=false)->Array[Vector3i]:
	var tiles : Array[Vector3i] = all_walkable_tiles()
	if ignore_objs:
		return tiles
	var obstructed : Array[Vector3i] = obj_ctrl.get_occupied_tiles(tiles)
	var walkables : Array[Vector3i] = []
	for cube in tiles:
		if !cube in obstructed:
			walkables.append(cube)
	return walkables
func all_walkable_tiles()->Array[Vector3i]:
	var tiles : Array[Vector3i] = [Vector3i(0,0,0)]
	for arr in [local_tiles, local_trash,
	next_shared, next_tiles,
	not_shared , prev_tiles, prev_shared ]:
		for tile in arr:
			tiles.append(oddq_to_cubic(tile))
	return tiles

enum TRASH_FILTER{no=0, allow=1, only=2}
func set_highlight(area:Array, is_on:bool, trash:TRASH_FILTER=TRASH_FILTER.allow)->Array:#Vector3i
	var allowed_moves : Array = []
	var arr2 : Array = []
	for cubic in area:
		var map_pos : Vector2i = cubic_to_oddq(cubic)
		if !is_on:
			set_cell(1, map_pos)
		elif trash == TRASH_FILTER.no:
			arr2.append(map_pos)
		else:
			var index : int = local_trash.find(map_pos)
			var found : bool = index > -1
			if !found and trash == TRASH_FILTER.only:
				arr2.append(map_pos)
			else:
				allowed_moves.append(map_pos)
				if found:
					trash_nodes[index].animate_vis(true)
	if !is_on:
		return []
	while arr2.size():
		set_cell(1, arr2.pop_front(), 0, Vector2i(1,0), 9)
	for pos in allowed_moves:
		set_cell(1, pos, 0, Vector2i(1,0))
		arr2.append(oddq_to_cubic(pos))
	return arr2
func clear_highlight(trash_anim:bool=false):
	clear_layer(1)
	for i in 3:
		trash_nodes[i].animate_vis(trash_anim)


func sort_vecs(a,b):
	if a.length() > b.length():
		return true
	return false


#this assumes vec2 is local to p_num so if they are p 2 then vec2(0,2) will actually be up and to the right
func oddq_to_cubic(vec:Vector2i, p_num:int=local_player)->Vector3i:
	var q = vec.x
	var r = vec.y - (vec.x - (vec.x&1)) / 2
	if p_num == 1:
		return Vector3i(r, -q-r, q)
	elif p_num == 2:
		return Vector3i(-q-r, q, r)
	return Vector3i(q, r, -q-r)
func cubic_to_oddq(vec:Vector3i, p_num:int=local_player)->Vector2i:
	var q : int = vec.x
	var r : int = vec.y
	if p_num == 1:
		q = vec.z
		r = vec.x
	elif p_num == 2:
		q = vec.y
		r = vec.z
	var col = q
	var row = r + (q - (q&1)) / 2
	return Vector2i(col, row)


func get_equal_pos(pos:Vector2i, prev_next:bool)->Vector2i:
	var cube : Vector3i = oddq_to_cubic(pos)
	return cubic_to_oddq( get_equal_cube(cube, prev_next) )
func get_equal_cube(cube:Vector3i, prev_next:bool)->Vector3i:
	if prev_next:#true : next, 60deg cw
		return Vector3i(cube.z, cube.x, cube.y)
	#false : prev, 60deg ccw
	return Vector3i(cube.y, cube.z, cube.x)





