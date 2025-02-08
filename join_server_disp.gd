extends Container

const lan_warning : String = "A LAN Connection will be attempted at 192.168.0."

@onready var ip_edit : LineEdit = $ip/LineEdit
var ip : String = "localhost"
var ip_valid : int = 0
func _on_line_edit_text_changed(new_text):
	ip = new_text
	ip_valid = is_valid_ip(ip)
	ip_edit.tooltip_text = ""
	if ip_valid == 0 and str(ip.to_int()) == ip:
		ip_valid = -1
		ip_edit.tooltip_text = str(lan_warning,ip)
	$ip/ip_valid/m/lan.visible = ip_valid == -1
	$ip/ip_valid/m/invalid.visible = ip_valid == 0
	$ip/ip_valid/m/valid.visible = ip_valid == 1

const eye_icons : Array = [preload("res://assets/eye.png"), preload("res://assets/eyeClosed.png")]
func _on_hide_toggled(toggled_on):
	$hide.icon = eye_icons[int(toggled_on)]
	ip_edit.secret = toggled_on

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
		ip_edit.editable = connected == -1
		port_edit.editable = connected == -1
		$password.editable = connected == -1
		$open.disabled = connected > -1
		$open.text = ["> Connect <","Connecting...","Connected"][connected+1]
func _on_open_pressed():
	connected = 0
	var server : Server_Controller = Global.server_controller
	server.connect_ip = ip
	server.current_port = port
	server.password = $password.text
	if !server.joined_server.is_connected(_on_server_join):
		server.joined_server.connect(_on_server_join)
	if !server.join_timeout.is_connected(_on_timeout):
		server.join_timeout.connect(_on_timeout)
	if !server.wrong_password.is_connected(_on_wrong_password):
		server.wrong_password.connect(_on_wrong_password)
	if !server.left_server.is_connected(_on_server_leave):
		server.left_server.connect(_on_server_leave)
	server.join_server()
func _on_server_join(iid:int):
	connection_status.emit(iid)
	connected = 1
func _on_timeout():
	connection_status.emit(-ERR_TIMEOUT)
	connected = -1
func _on_wrong_password():
	connection_status.emit(-ERR_INVALID_DATA)
	connected = -1
func _on_server_leave():
	connection_status.emit(OK)
	connected = -1

signal connection_status(arg:int)



# Function to check if the input string is a valid IPv4 or IPv6 address
func is_valid_ip(address: String) -> bool:
	# Check if it's a valid IPv4 address
	if _is_valid_ipv4(address):
		return true
	# Check if it's a valid IPv6 address
	if _is_valid_ipv6(address):
		return true
	return false

# Helper function to validate IPv4
func _is_valid_ipv4(address: String) -> bool:
	var parts = address.split(".")
	# An IPv4 address must have exactly 4 parts
	if parts.size() != 4:
		return false
	for part in parts:
		# Each part must be a valid number and in the range 0-255
		if not part.is_valid_int():
			return false
		var num = int(part)
		if num < 0 or num > 255:
			return false
	return true

# Helper function to validate IPv6
func _is_valid_ipv6(address: String) -> bool:
	# Special case for "::1" (IPv6 loopback address)
	if address == "::1" or address == "0:0:0:0:0:0:0:1":
		return true
	# Check if shorthand "::" exists and ensure it appears only once
	var parts = address.split("::")
	if parts.size() > 2:
		return false
	# Handle case where "::" exists: rebuild the address without shorthand
	if parts.size() == 2:
		var left_part = []
		var right_part = []
		# Fill left and right parts based on presence of groups
		if parts[0] != "":
			left_part = parts[0].split(":")
		if parts[1] != "":
			right_part = parts[1].split(":")
		# Reconstruct address
		address = ":".join(left_part) + ":" + ":".join(right_part)
	# Split the address into groups
	var groups = address.split(":")
	# An IPv6 address must have at least 3 groups (for "::1" case) and at most 8 groups
	if groups.size() < 3 or groups.size() > 8:
		return false
	# Count empty groups that might result from shorthand "::"
	var empty_groups = 0
	for group in groups:
		if group == "":
			empty_groups += 1
	# If there are more than 1 empty groups, it's invalid (only one "::" is allowed)
	if empty_groups > 1:
		return false
	# Each group must be 1 to 4 characters long and hexadecimal
	for group in groups:
		if group.length() < 1 or group.length() > 4:
			return false
		for cha in group:
			if not (cha.is_valid_int() or (cha >= "a" and cha <= "f") or (cha >= "A" and cha <= "F")):
				return false
	return true



