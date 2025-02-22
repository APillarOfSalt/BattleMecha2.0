extends VBoxContainer

class_name Combat_Manager

@export var map : TileMap = null
@export var obj_ctrl : Object_Controller = null
@export var turn_tracker : Turn_Tracker = null
@onready var display : Combat_Display = $display
@onready var sniffer = $sniffer


func check_tiles_raw(tiles:Array):
	sniffer._setup(tiles)

func _on_sniffer_on_search_complete():
	get_parent().
	
	
	
	if sniffer.overlap_tiles.size():
		for tile in sniffer.overlap_tiles:
			display.create_combat_at(tile)
	else:
		for tile in sniffer.attacks.keys():
			display.create_combat_at(tile)
	
	
	
	if !display.attacks.size():

			get_parent()._advance.rpc()
			clear_map.rpc()
	else:
		clear_map.rpc()
		print("finished : ",display.attacks)

@rpc("authority", "call_local", "reliable")
func clear_map():
	map.clear_layer(3)
