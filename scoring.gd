extends TileMap

func c2o(cube:Vector3i)->Vector2i:
	return get_parent().cubic_to_oddq(cube)
func o2c(oddq:Vector2i)->Vector3i:
	return get_parent().oddq_to_cubic(oddq)

@rpc("authority", "call_local", "reliable")
func rpc_clear_layer(layer:int):
	clear_layer(layer)
@rpc("authority", "call_local", "reliable")
func rpc_set_cell(layer:int, cube:Vector3i, index:int):
	if index <= 0:
		set_cell(layer, c2o(cube))
	else:
		set_cell(layer, c2o(cube), 1, Vector2i(index,0))


signal give_points_to(num:int,val:int)
signal finished()

@export var obj_ctrl : Object_Controller = null

var score_data : Full_Score_State_Data = DataLoader.score_data_by_name.values().front()
var current_data : Score_State_Data = null
var total_states : int:
	get: return score_data.states
var total_steps : int:
	get: return score_data.steps
var state_at : int = 0
var step : int = -1
var state_to : int = 0


var tile_arr : Array = []
var self_step : int = 0

func _deploy_score():
	step = (step + 1) % total_states
	if step == 0:
		state_at = state_to
		current_data = score_data.data_states[int( pow(2,state_at) )]
		state_to = (state_to + 1) % total_states
	else:
		current_data = score_data.data_steps[int( pow(2,state_at)+pow(2,state_to) )][step]
	tile_arr = get_used_cells_by_id(0)
	tick = Time.get_ticks_msec()
	do_tick()

@onready var tick_speed_msec: int = Global.get_wait_msec(0.5)
var tick : int = -1
func _process(delta):
	if tick < 0 or Time.get_ticks_msec() - tick <= tick_speed_msec:
		return
	tick = Time.get_ticks_msec()
	do_tick()

func do_tick():
	if tile_arr.size() == 0:
		if self_step == 0:
			self_step = 1
			tile_arr = get_used_cells_by_id(1)
		elif self_step == 1:
			self_step = 2
			tile_arr = current_data.tile_score.keys()
		else:
			tick = -1
			self_step = 0
			finished.emit()
		return
	var tile = tile_arr.pop_front()
	if self_step == 0:
		var cube : Vector3i = o2c(tile)
		var objs : Array[Map_Object] = obj_ctrl.get_objs_at(cube)
		if objs.size() > 1:
			print("oop")
		var val : int = get_cell_atlas_coords(0, tile).x
		for obj in objs:
			give_points_to.emit( obj.player_num, val )
		rpc_set_cell.rpc(0, cube, -1)
	elif self_step == 1:
		var cube : Vector3i = o2c(tile)
		var val : int = get_cell_atlas_coords(1, tile).x
		rpc_set_cell.rpc(0, cube, val)
		rpc_set_cell.rpc(1, cube, -1)
	else:
		rpc_set_cell.rpc(1, tile, current_data.tile_score[tile] )
