extends Container

@onready var step_l : Label = $v/title/m/step
@onready var title_l : Label = $v/title/m/Label
@onready var total_l : Label = $v/title/m/total
@onready var map : TileMap = $v/m/Control/TileMap
@export_enum("To","From") var to_from : int = 1
var score_data : Score_State_Data = null:
	set(data):
		score_data = data
		_recalc()

func set_score(tile:Vector2i, val:int, local:bool=true):
	var cube : Vector3i = oddq_to_cubic(tile)
	if val == 0 and cube in score_data.tile_score.keys():
		score_data.tile_score.erase(cube)
	else:
		score_data.tile_score[cube] = val
	for nd in get_tree().get_nodes_in_group("score_state_disp"):
		if nd.state == state and nd.step == step:
			nd._recalc()

var step : int = 0:
	set(val):
		step = val
		_update_labels()
var state_letter : String = ""
var state : int = 0:
	set(val):
		state = val
		state_letter = Global.get_letter_from_int(flag_to_index(val))
		_update_labels()

func setup(sta:int, data:Score_State_Data):
	score_data = data
	state = sta
	_update_labels()
func _update_labels():
	step_l.text = str("Step ",step)
	var title_text : String = state_letter
	if step > 0:
		title_text = str(step)
	title_l.text = title_text

var total : int = 0:
	set(val):
		total = val
		var text : String = str(val)
		if text.length() < 2:
			text = str("0",val)
		total_l.text = "Total : " + text

var highlight := Vector2i(0,0):
	set(vec):
		map.set_cell(2, highlight)
		highlight = vec
		if vec in map.get_used_cells(0):
			map.set_cell(2, vec, 0, Vector2i(0,0))
func _input(event):
	if event is InputEventMouseMotion:
		map.clear_layer(2)
		highlight = map.local_to_map(map.get_local_mouse_position())
	if !highlight in map.get_used_cells(0):
		return
	var atlas : Vector2i = map.get_cell_atlas_coords(1,highlight)
	if event.is_action_pressed("lmb"):
		set_score(highlight, atlas_to_int(atlas) + 1)
	elif event.is_action_pressed("rmb"):
		set_score(highlight, atlas_to_int(atlas) - 1)

func _recalc():
	map.clear_layer(1)
	var subtotal : int = 0
	for vec:Vector3i in score_data.tile_score.keys():
		var score : int = score_data.tile_score[vec]
		map.set_cell(1, cubic_to_oddq(vec), 1, int_to_atlas(score) )
		subtotal += score
	total = subtotal

func flag_to_index(flag:int)->int:
	var index = 0
	while flag > 1:
		flag = flag >> 1
		index += 1
	return index

func atlas_to_int(atlas:Vector2i)->int:
	var val : int = 0
	if atlas.y >= 0 and atlas.y < 2 and atlas.x >= 0 and atlas.x < 5:
		return atlas.x + (atlas.y*5)
	return val
func int_to_atlas(val:int)->Vector2i:
	var vec := Vector2i(-1,-1)
	if val >= 0 and val < 10:
		vec.x = val % 5
		vec.y = int(val >= 5)
	return vec

func oddq_to_cubic(vec:Vector2i)->Vector3i:
	var q = vec.x
	var r = vec.y - (vec.x - (vec.x&1)) / 2
	return Vector3i(q, r, -q-r)
func cubic_to_oddq(vec:Vector3i)->Vector2i:
	var col = vec.x
	var row = vec.y + (vec.x - (vec.x&1)) / 2
	return Vector2i(col, row)
