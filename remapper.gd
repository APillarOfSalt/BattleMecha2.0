extends Container

const input_disp_scene : PackedScene = preload("res://remapper_input_disp.tscn")
const player_disp_scene : PackedScene = preload("res://remapper_player_disp.tscn")

@onready var input_cont : Container = $v/content/h/inputs
@onready var player_cont : Container = $v/content/h/v/players
@onready var add_butt : Button = $v/content/h/v/add_remove/add
@onready var remove_butt : Button = $v/content/h/v/add_remove/remove
var default_colors : Array

@onready var mouse : Container = $"v/content/h/inputs/-1"
@onready var keyboard : Container = $"v/content/h/inputs/0"
@onready var player_1 : Container = $"v/content/h/v/players/0"

func _ready():
	default_colors = Global.even_colors( 3, Color("cc2929") )
	player_1.color = default_colors[0]
	mouse.connect_line.call_deferred(player_1)
	keyboard.connect_line.call_deferred(player_1)
	_on_save_pressed.call_deferred()

var num_pads : int = 0:
	set(val):
		var diff = val - num_pads
		for i in abs(diff):
			if diff < 0: #remove
				var victim = input_cont.get_node(str(-i))
				victim.name = "oh_no"
				victim.selected.disconnect(_on_i_selected)
				victim.queue_free()
			else: #add
				var new_pad = input_disp_scene.instantiate()
				var num : int = input_cont.get_child_count()-1
				new_pad.name = str( num )
				input_cont.add_child(new_pad)
				new_pad.selected.connect(_on_i_selected)
				new_pad.input = num
		num_pads = val

func _on_add_pressed():
	var num : int = player_cont.get_child_count()
	if num == 2:
		add_butt.disabled = true
	var player = player_disp_scene.instantiate()
	player.name = str(num)
	player_cont.add_child(player)
	player.selected.connect(_on_p_selected)
	player.num = num
	player.color = default_colors[num]
	remove_butt.disabled = false

func _on_remove_pressed():
	var victim = player_cont.get_child(-1)
	victim.name = "oh_no"
	victim.selected.disconnect(_on_p_selected)
	victim.queue_free()
	remove_butt.disabled = player_cont.get_child_count() <= 2
	add_butt.disabled = false

var selected_input : Container = null
func _on_i_selected(node):
	if selected_input != null:
		selected_input.unsel()
	selected_input = node

func _process(_delta):
	if selected_input != null:
		selected_input.line.points[1] = selected_input.line.get_local_mouse_position()

func _on_p_selected(node):
	if node.connected != null:
		if selected_input == null:
			return
		elif selected_input.input > 0 or node.connected.input > 0:
			return
	if selected_input != null:
		selected_input.connect_line(node)
		selected_input.unsel()

signal close_popup(do_save:bool)
func _on_save_pressed():
	close_popup.emit(true)
func _on_cancel_pressed():
	close_popup.emit(false)

func gather_data()->Dictionary:
	var data : Dictionary = {} #input:int : [player:int, color]
	for i in input_cont.get_child_count():
		var inp = input_cont.get_child(i)
		var pla = inp.connected
		if pla != null:
			data[inp.input] = [pla.num, pla.color]
	return data


