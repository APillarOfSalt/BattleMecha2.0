extends Node2D
class_name Player_Controller

###OLD CODE###

const unit_scene : PackedScene = preload("res://unit_node.tscn")

func _ready():
	map._refresh()

func _setup(data:Dictionary, ui:Player_UI):
	player_name = data.name
	player_num = data.num
	device = data.device
	color = data.color
	for s in VARS:
		self[s] = data[s]

var controller_name : String:
	get: return str(player_name,":",player_num)
var color : Color:
	set(col):
		color = col
		$cursor_container.modulate = col
var player_num : int = 0:
	set(val):
		player_num = val
		
var player_name : String
var iid : int = -1
var device: int = -3

var ti : int = 0
var ga : int = 0
var al : int = 0
var co : int = 0
const VARS : Array = ["iid", "device", "ti", "ga", "al", "co"]
@export var map : TileMap
@onready var game_controller = get_parent()

var cursor_pos_map : Vector2i:
	get: return $cursor_container.map_pos
var cursor_pos_gcubic : Vector3i:
	get: return local_to_gcubic(cursor_pos_map)

func _on_cursor_container_new_map_pos(pos:Vector2i):
	map.highlight_pos = pos
	#print(pos,":",gcubic_to_local(cursor_pos_gcubic) )

func gcubic_to_local(gcube:Vector3i)->Vector2i:
	var pos_loc_1 : Vector2i = map.cubic_to_oddq(gcube)
	if player_num == 1: #num==1 cubic == gcubic
		return pos_loc_1
	return map.get_equal_pos(pos_loc_1, player_num==2) #num==2 is next for 1, else num==3 is prev for 1 
func local_to_gcubic(loc_pos:Vector2i)->Vector3i:
	if player_num != 1:
		loc_pos = map.get_equal_pos(loc_pos, player_num==3) #if num==3 next is 1, elif num==2 prev is 1
	return map.oddq_to_cubic(loc_pos) #num==1 cubic == gcubic

func request_highlight(node:Unit_Node, display:bool):
	pass

func request_movement(node:Unit_Node, display:bool):
	pass

func check_affordable(cost:Dictionary):
	
	pass
