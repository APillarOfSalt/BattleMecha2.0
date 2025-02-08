extends Node2D

class_name Cursor_Controller

signal pads_updated()

var pad_inputs : Dictionary
func _process(_delta):
	var joys : Array = Input.get_connected_joypads()
	var toErase : Array = []
	for j in pad_inputs.keys():
		if !j in joys:
			toErase.append(j)
	var changeMade : bool = false
	for j in joys:
		if !j in pad_inputs:
			pad_inputs[j] = {}
			changeMade = true
	for j in toErase:
		pad_inputs.erase(j)
		changeMade = true
	if changeMade:
		update_inputs()

@onready var pad_list : Container = $h/pad_list
func update_inputs():
	if pad_list == null:
		return
	pads_updated.emit()
	#var num0 : int = pad_list.get_child_count()-1
	var num1 : int = pad_inputs.keys().size()
	$remapper.num_pads = num1

#
#func get_first_player()->Cursor_Container:
	#return pad_list.get_child(0)
#
#var data : Dictionary #input:int : [player:int, color]
#
#const disp_scene : PackedScene = preload("res://cursor_disp.tscn")
#
#func refresh():
	#for ch in pad_list.get_children():
		#ch.name = "oh_no"
		#ch.queue_free()
	#for input:int in data.keys():
		#var disp = disp_scene.instantiate()
		#disp.name = str(input)
		##print(input)
		#pad_list.add_child(disp)
		#disp.input = input
		#disp.num = data[input][0]
		#disp.color = data[input][1]
#
#
#func _on_show_remap_pressed():
	#$remapper.show()
#func _on_remapper_close_popup(do_save:bool):
	#if do_save:
		#data = $remapper.gather_data()
		#refresh()
	#$remapper.hide()

