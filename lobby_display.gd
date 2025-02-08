extends VBoxContainer

func get_player_data()->Player_Data:
	var data : Dictionary = {
		"iid" : Global.server_controller.instance_id,
		"peer_id" : multiplayer.get_unique_id(),
		"num" : player_num,
		"name" : player_name,
		"team" : team,
	}
	return Player_Data.new(data)

signal readied(is_ready:bool)
func _on_ready_toggled(toggled_on):
	$ready.text = ["Set Ready","Readied"][int(toggled_on)]
	if !toggled_on:
		$ready.release_focus()
	_remote_set_ready_butt.rpc(toggled_on)
	readied.emit(toggled_on)
@rpc("any_peer", "call_remote", "reliable")
func _remote_set_ready_butt(toggle:bool):
	$ready.button_pressed = toggle
	$ready.text = ["Set Ready","Readied"][int(toggle)]

var is_ready : bool = false:
	set(toggle):
		if is_ready == toggle:
			return
		is_ready = toggle

func _check_ready():
	is_ready = player_name != "" and player_num != -1 and team != null
	$ready.disabled = !is_ready or !is_local
	return is_ready and $ready.button_pressed

@onready var selector : Container = $selector
@onready var colors : Container = $colors
@onready var resources : Cost_Data = $cost
@onready var units : Container = $units
func _ready():
	selector.sel.clear()
	$LineEdit.editable = is_local
	$ready.disabled = true
	selector.sel.disabled = !is_local
	if is_local:
		for t_name:String in DataLoader.teams_by_name:
			selector.sel.add_item(t_name)
	else:
		selector.sel.disabled = true
	selector.sel.selected = -1

@export var is_local : bool = false
var is_online : bool = false

var all_units : Array[Unit_Data]

var player_num : int = -1:
	set(val):
		player_num = val
		$title/m/client.visible = val
		$title/m/host.visible = !val
		$title/p/m/Label.text = str("Player ",val+1)
		$title/m/client/m/h/iid.text = str(val)
		_check_ready()

var player_name : String = ""
func _on_line_edit_text_changed(new_text:String):
	player_name = new_text.strip_edges()
	while "  " in player_name:
		player_name = player_name.replace("  ", " ")
	if $LineEdit.text != player_name:
		$LineEdit.text = player_name
	_check_ready()

var team : Team_Data = null:
	set(data):
		team = data
		if is_online:
			selector.set_team_name.rpc(team.name)
			colors.set_colors.rpc(team.base_color, team.palette)
			remote_sender()
		else:
			selector.set_team_name(team.name)
			colors.set_colors(team.base_color, team.palette)
			resources.set_cost(team.starting_resources)
		all_units = units.setup(team.starting_units, team.units)
		_check_ready()

func remote_sender():
	var ti : int = team.starting_resources.titanium
	var ga : int = team.starting_resources.gallium
	var al : int = team.starting_resources.aluminium
	var co : int = team.starting_resources.cobalt
	remote_res_setter.rpc(ti, ga, al, co)
@rpc("any_peer", "call_local", "reliable")
func remote_res_setter(ti:int,ga:int,al:int,co:int):
	resources.ti = ti
	resources.ga = ga
	resources.al = al
	resources.co = co

