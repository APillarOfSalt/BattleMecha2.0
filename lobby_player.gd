extends VBoxContainer

@rpc("any_peer", "call_remote", "reliable")
func _on_host_item_selected(index, force:bool=false):
	if iid == index+1 and !force:
		return
	iid = index+1
	unit_picker.disabled = !is_local_authority()
	if Global.server_controller.instance_id == 1:
		pid_setter.rpc( Global.server_controller.host.iid_uid[iid] )
		_iid_text.rpc(str(iid))
		_on_host_item_selected.rpc(index, true)
		clear_unit_picker.rpc()

@rpc("any_peer", "call_local", "reliable")
func clear_unit_picker():
	unit_picker.disabled = !is_local_authority()
	unit_picker.team_op.selected = 0
	unit_picker.clear()

func _ready():
	if multiplayer.get_unique_id() == 1:
		_refresh_iids()
	unit_picker.clear()
	unit_picker.disabled = player_num > 0

@rpc("any_peer", "call_local", "reliable")
func pid_setter(pid:int):
	set_multiplayer_authority(pid, true)
	var auth : bool = is_local_authority()
	$ready.disabled = player_name == "" or total != total_allowed or !auth
	name_edit.editable = auth
	color_picker.disabled = !auth
	cost_edit.disabled = !auth
	unit_picker.disabled = !auth
	unit_picker.team_net_l.modulate.a = float(auth)
	if auth:
		unit_picker._refresh_teams()


func is_local_authority()->bool:
	if Global.server_controller.instance_id == -1:
		return true
	if multiplayer.get_unique_id() == 1:
		return iid == 1
	return is_multiplayer_authority()



@rpc("any_peer", "call_local", "reliable")
func _iid_text(text:String):
	client_num_l.text = text
@export var iid : int = 1:
	set(val):
		if iid != val:
			iid = val
@export var player_num : int = -1:
	set(val):
		player_num = val
		$title/p/m/Label.text = str("Player ",player_num+1)

@export var player_name : String = "":
	set(text):
		player_name = text
		if !is_inside_tree():
			await ready
		if name_edit.text != text:
			name_edit.text = text
@onready var name_edit : LineEdit = $LineEdit
@rpc("any_peer", "call_remote", "reliable")
func _on_line_edit_text_changed(new_text:String, dont_emit:bool=false):
	player_name = new_text.strip_edges()
	$ready.disabled = player_name == "" or total != total_allowed or !is_local_authority()
	if !dont_emit:
		_on_line_edit_text_changed.rpc(new_text, true)

@onready var color_picker : ColorPickerButton = $title/ColorPickerButton
@rpc("any_peer", "call_remote", "reliable")
func _on_color_picker_button_color_changed(col:Color, dont_emit:bool=false):
	color = col
	if !dont_emit:
		_on_color_picker_button_color_changed.rpc(col, true)
@export var color : Color = Color.BLACK:
	set(col):
		color = col
		if !is_inside_tree():
			await ready
		color_picker.color = col



@onready var client_num_disp : Container = $title/m/client
@onready var client_num_l : Label = $title/m/client/m/h/iid
@onready var host_num_disp : Container = $title/m/host
var local_instance_id : int = -1
@rpc("authority", "call_local", "reliable")
func _refresh_iids():
	var is_host : bool = Global.server_controller.instance_id == 1
	client_num_disp.visible = !is_host
	host_num_disp.visible = is_host




@onready var unit_picker = $unit_picker
func gather_data()->Dictionary:
	return {
		"iid" : iid,
		"num" : player_num,
		"name" : player_name,
		"color" : color,
		"ti" : cost_edit.ti,
		"ga" : cost_edit.ga,
		"al" : cost_edit.al,
		"co" : cost_edit.co,
		"team" : unit_picker.team,
		"u0" : unit_picker.units[0].unit.id,
		"u1" : unit_picker.units[1].unit.id,
		"u2" : unit_picker.units[2].unit.id,
	}

func from_data(data:Dictionary):
	iid = int(data.iid)
	player_num = data.num
	player_name = data.name
	name_edit.text = data.name
	unit_picker.team = data.team
	color = Global.color_from_json(data.color)
	for i in 4:
		var s : String = cost_edit.VAR_NAMES[i]
		cost_edit[s] = int(data[s])
		print(data[s])
	for i:int in 3:
		unit_picker[str("u",i,"_id")] = int(data[str("u",i)])
	if multiplayer.get_unique_id() == 1:
		delay_setter.call_deferred()
func delay_setter():
	pid_setter.rpc( Global.server_controller.host.iid_uid[iid] )

signal readied(data:Dictionary)
@export var is_ready : bool = false
@rpc("any_peer", "call_remote", "reliable")
func _on_ready_toggled(toggled_on):
	var auth : bool = is_local_authority()
	name_edit.editable = !toggled_on and auth
	color_picker.disabled = toggled_on or !auth
	cost_edit.disabled = toggled_on or !auth
	unit_picker.disabled = toggled_on or !auth
	$ready.text = "Ready"
	if !toggled_on:
		$ready.text = "Set Ready"
	if is_ready == toggled_on:
		return
	is_ready = toggled_on
	if is_ready:
		readied.emit(gather_data())
	else:
		readied.emit({})
	if auth:
		_on_ready_toggled.rpc(toggled_on)


@onready var cost_edit = $cost_editor
@export var total_allowed : int = 4
@export var ti : int:
	set(val): cost_edit.ti = val
	get: return cost_edit.ti
@export var ga : int:
	set(val): cost_edit.ga = val
	get: return cost_edit.ga
@export var al : int:
	set(val): cost_edit.al = val
	get: return cost_edit.al
@export var co : int:
	set(val): cost_edit.co = val
	get: return cost_edit.co
var total : int:
	get: return ti+ga+al+co
func _on_cost_editor_new_value(access:String):
	if Global.server_controller.instance_id == -1:
		cost_edit.remote_set(access, cost_edit[access])
	elif is_local_authority():
		cost_edit.remote_set.rpc(access, cost_edit[access])
	$ready.disabled = player_name == "" or total != total_allowed or !is_local_authority()
