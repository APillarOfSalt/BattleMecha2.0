extends HBoxContainer

signal client_joined(iid:int)
signal update_iid(new:int)

func _ready():
	Global.server_controller.host.joined_server.connect(_on_host_client_joined)
	_on_offline_pressed()

@onready var err_l : Color_Label = $connect_err
func set_err_l(text:String):
	var color := Color.LIGHT_GRAY
	if "Failed" in text:
		color = Color.RED
	elif "Success" in text:
		color = Color.GREEN
	err_l.this_first = Color(err_l.modulate, 0.0)
	err_l.first_hold = -1
	err_l.first_text = text
	err_l.interrupt_colors.append_array([color, Color(color,0), err_l.repeat_colors[0]])
	err_l.i_holds_msec.append(2000)

func _on_offline_pressed():
	var toggle : bool = Global.server_controller.refresh_gateway()
	$offline.visible = !toggle
	$j_h_butt.visible = toggle
	$j_h.visible = toggle
	var s := STATUS.disconnected
	if toggle:
		s = STATUS.offline
	status = s

func _on_j_h_butt_toggled(toggled_on):
	$j_h_butt.text = "Join by IP"
	if toggled_on:
		$j_h_butt.text = "Hosting"
	$j_h/join.visible = !toggled_on
	$j_h/host.visible = toggled_on

var instance_id : int = -1:
	set(val):
		instance_id = val
		update_iid.emit(val)

enum STATUS{disconnected=-1,offline=0,connected=1,hosting=2}
var status : STATUS = STATUS.disconnected:
	set(val):
		if status == val:
			return
		status = val
		$j_h_butt.disabled = status != STATUS.offline
		var text : String = ""
		var col : Color
		match val:
			STATUS.disconnected:
				text = "Disconnected"
				col = Color.CRIMSON
			STATUS.offline:
				text = "Offline"
				col = Color.LIGHT_GRAY
			STATUS.connected:
				text = "Connected"
				col = Color.LIME_GREEN
			STATUS.hosting:
				text = "Hosting"
				col = Color.LIME_GREEN
		err_l.repeat_text[0] = text
		err_l.repeat_colors[0] = Color(col, 0.0)
		err_l.repeat_colors[1] = col

func _on_join_connection_status(err:int):
	var new_text : String = err_l.text
	match err:
		-ERR_TIMEOUT:
			new_text = "Connection Failed: Timeout was reached"
			instance_id = -1
		-ERR_INVALID_DATA:
			new_text = "Connection Failed: Incorrect Password"
			instance_id = -1
		OK:
			new_text = "Left Server."
			instance_id = -1
		_: 
			if err < 0:
				new_text = str("Connection Failed: Unhandled Error #",err)
				instance_id = -1
			else:
				instance_id = err
	if new_text != err_l.text:
		status = STATUS.offline
		set_err_l(new_text)
		return
	#err == iid ; instance_id
	status = STATUS.connected
	set_err_l("Connection Successful.")


func _on_host_server_status(err):
	var new_text : String = err_l.text
	status = STATUS.offline
	instance_id = -int(err != OK) #OK, iid==0, else iid==-1
	match err:
		OK:
			status = STATUS.hosting
			new_text = "Server Created Successfully."
		ERR_ALREADY_IN_USE:
			new_text = "Server Creation Failed: Port Already In Use"
		ERR_CANT_CREATE:
			new_text = "Server Creation Failed: Invalid Configuration"
		_:
			new_text = str("Server Creation Failed: Unhandled Error #",err)
	set_err_l(new_text)

func _on_host_client_joined(iid:int):
	set_err_l(str("Client#",iid," has joined the server."))
	client_joined.emit(iid)
	






