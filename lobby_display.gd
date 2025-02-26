extends VBoxContainer

func get_player_data()->Player_Data:
	if team == null:
		return null
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
	units.clear()
	$LineEdit.editable = is_local
	$ready.disabled = true
	selector.sel.disabled = !is_local
	if is_local:
		for t_name:String in DataLoader.teams_by_name:
			selector.sel.add_item(t_name)
	selector.sel.selected = -1

@export var is_local : bool = false
var is_online : bool = false:
	set(toggle):
		is_online = toggle
		$title/m/client/m/h/m/anchor/conn.modulate = [Color.BLACK, Color.WHITE][int(toggle)]

var all_units : Array[Unit_Data]

var player_num : int = -1:
	set(val):
		player_num = val
		$title/m/client.visible = val
		$title/m/host.visible = !val
		$title/p/m/Label.text = str("Player ",val+1)
		$title/m/client/m/h/iid.text = str(val)
		_check_ready()

@export var player_name : String = "": set = _on_line_edit_text_changed
func _on_line_edit_text_changed(new_text:String):
	while "  " in new_text:
		new_text = new_text.replace("  ", " ").strip_edges()
	if $LineEdit.text != new_text:
		$LineEdit.text = new_text
	player_name = new_text
	_check_ready()

var team : Team_Data = null:
	set(data):
		team = data
		if team == null:
			team_name = ""
			team_color = Color.WHITE
			team_palette = 0
			resource_setter({"titanium":0,"gallium":0,"aluminum":0,"cobalt":0})
			units.clear()
		else:
			team_name = team.name
			team_color = team.base_color
			team_palette = team.palette
			resource_setter(team.starting_resources)
			all_units = units.setup(team.starting_units, team.units)
		_check_ready()
var team_name : String:
	set(text):
		team_name = text
		selector.set_team_name(text)
var team_color : Color:
	set(color):
		team_color = color
		colors.set_colors(color, team_palette)
var team_palette : int:
	set(val):
		team_palette = val
		colors.set_colors(team_color, val)

func resource_setter(res:Dictionary):
	for i in 4:
		resources.set_val_i(i, res[ resources.ele_strs[i] ])
