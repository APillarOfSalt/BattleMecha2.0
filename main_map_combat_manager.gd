extends VBoxContainer

class_name Combat_Manager

@export var map : TileMap = null
@export var obj_ctrl : Object_Controller = null
@export var turn_tracker : Turn_Tracker = null
@onready var display : Combat_Display = $display
@onready var sniffer = $sniffer

var is_overlap : bool = false

func check_tiles_raw(overlap:bool, tiles:Array):
	#print("START : ",overlap)
	is_overlap = overlap
	sniffer._setup(tiles)

func _on_sniffer_on_search_complete():
	if is_overlap:
		for tile in sniffer.overlap_tiles:
			display.create_combat_at(tile)
	else:
		for tile in sniffer.attacks.keys():
			display.create_combat_at(tile)
	if !display.attacks.size():
		#print("finished : ",is_overlap)
		if is_overlap:
			check_tiles_raw( false, obj_ctrl.get_obj_tiles().keys() )
		else:
			get_parent()._advance.rpc()
			clear_map.rpc()
	else:
		clear_map.rpc()
		print("finished : ",display.attacks)

@rpc("authority", "call_local", "reliable")
func clear_map():
	map.clear_layer(3)
