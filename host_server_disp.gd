extends HBoxContainer


var save_hide : bool = false
func _on_check_toggled(toggled_on):
	$hide.disabled = toggled_on
	if toggled_on:
		save_hide = $hide.button_pressed
		$hide.button_pressed = false
		$LineEdit.text = Global.server_controller.this_computer_ip
	else:
		$hide.button_pressed = save_hide

const eye_icons : Array = [preload("res://assets/eye.png"), preload("res://assets/eyeClosed.png")]
func _on_hide_toggled(toggled_on):
	$hide.icon = eye_icons[int(toggled_on)]
	$LineEdit.secret = toggled_on

const port_range : Vector2i = Vector2i(1024, 65535)
@onready var port_edit : SpinBox = $SpinBox
var port : int = 1024
func _on_spin_box_value_changed(val:int):
	if port == val:
		return
	port = clamp(val, port_range.x, port_range.y)
	if port_edit.value != val:
		port_edit.value = val


var connected : int = -1:
	set(val):
		connected = val
		$open.disabled = val == 1
		$password.editable = val == -1
		port_edit.editable = val == -1
func _on_open_pressed():
	connected = 0
	$open.text = "Starting" #wait a frame so the button can update
	var server : Server_Controller = Global.server_controller
	server.current_port = port

func _process(_delta):
	if $open.text == "Starting...":
		var ip : String = ""
		if $lan/butt/check.button_pressed:
			ip = "localhost"
		var err := Global.server_controller.host.start_server(port, ip)
		if err == OK:
			$open.text = "Running"
			Global.server_controller.host.password = $password.text
			connected = 1
		else:
			$open.text = "> Run <"
			connected = -1
		server_status.emit(err)
	if $open.text == "Starting":
		$open.text = "Starting..."

signal server_status(err:int)
