extends VBoxContainer

func _ready():
	#false:-1==disconnected, true:0==offline
	status = int( Global.server_controller.refresh_gateway() ) - 1

	Global.server_controller.left_server.connect(_on_left_server)
	Global.server_controller.joined_server.connect(_on_join_server)

	Global.server_controller.host.server_started.connect(_on_server_opened)
	Global.server_controller.host.server_stopped.connect(_on_server_closed)
	Global.server_controller.host.joined_server.connect(_on_host_client_joined)
	Global.server_controller.host.left_server.connect(_on_client_leave)

signal server_joined() #procs on the CLIENT when joining a server
signal server_left() #procs on the CLIENT when leaving or closing the server
func _on_join_server(iid:int):
	status = STATUS.connected
	server_joined.emit()
func _on_left_server(_iid:int):
	status = STATUS.offline
	server_left.emit()


signal server_stopped() #procs on the HOST when the server stops
signal server_started() #procs on the HOST when the server starts
signal client_joined(iid:int) #procs on the HOST when a client joins
signal client_left(iid:int) #procs on the HOST when a client leaves
func _on_server_opened():
	status = STATUS.hosting
	server_started.emit()
func _on_server_closed():
	status = STATUS.offline
	server_stopped.emit()
func _on_host_client_joined(iid:int):
	set_err_l(str("Client#",iid," has joined the server."))
	
	client_joined.emit(iid)
func _on_client_leave(iid:int):
	client_left.emit(iid)


func _on_toggle_toggled(toggled_on:bool):
	#true == host
	$host.visible = toggled_on
	$title/h/v/host.visible = toggled_on
	#false == join
	$join.visible = !toggled_on
	$title/h/v/join.visible = !toggled_on

@onready var menu_butt : Button = $"../../../../title/bg/main_menu"

enum STATUS{disconnected=-1,offline=0,connected=1,hosting=2}
var status : STATUS = STATUS.disconnected:
	set(val):
		if status == val:
			return
		status = val
		menu_butt.disabled = val > 0
		$title.visible = $title.visible and val != STATUS.disconnected
		$join.visible = $join.visible and val != STATUS.disconnected
		$host.visible = $host.visible and val != STATUS.disconnected
		set_err_data(val)

func _on_host_server_status(err:int):
	var new_text : String = err_l.text
	if err == OK:
		status = STATUS.hosting
		set_err_l( "Server Created Successfully." )
	elif err in host_err_strings.keys():
		status = STATUS.offline
		set_err_l( host_err_strings[err] )
	else:
		status = STATUS.offline
		set_err_l( str(host_err_strings[-1],err) )

func _on_join_connection_status(err:int):
	#handled errors
	if err in join_err_strings.keys(): 
		status = STATUS.offline
		set_err_l( join_err_strings[err] )
	#unhandled error
	elif err < 0: 
		status = STATUS.offline
		set_err_l( str(join_err_strings[-1],err) )
	# OK -> err == iid ; instance_id
	else: 
		status = STATUS.connected
		set_err_l( "Connection Successful." )

const host_err_strings : Dictionary = {
	ERR_ALREADY_IN_USE: "Server Creation Failed: Port Already In Use",
	ERR_CANT_CREATE: "Server Creation Failed: Invalid Configuration",
	-1: "Server Creation Failed: Unhandled Error #",
	-2: "Server stopped"
}
const join_err_strings : Dictionary = {
	-ERR_TIMEOUT: "Connection Failed: Timeout was reached",
	-ERR_INVALID_DATA: "Connection Failed: Incorrect Password",
	OK: "Left Server.",
	-1: "Connection Failed: Unhandled Error #"
}

const err_l_data : Dictionary = {
	STATUS.disconnected :{ "text" : "Disconnected", "color" : Color.CRIMSON },
	STATUS.offline :	 { "text" : "Offline",		"color" : Color.LIGHT_GRAY },
	STATUS.connected :	 { "text" : "Connected",	"color" : Color.LIME_GREEN },
	STATUS.hosting :	 { "text" : "Hosting",		"color" : Color.LIME_GREEN },
}

func set_err_data(val:int):
	err_l.repeat_text[0] = err_l_data[val].text
	err_l.repeat_colors[0] = Color(err_l_data[val].color, 0.0)
	err_l.repeat_colors[1] = err_l_data[val].color

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


