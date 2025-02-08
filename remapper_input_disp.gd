extends HBoxContainer

signal selected(node)

#-1 mouse, 0 keyboard, 1+ gamepads
@export var input : int:
	set(val):
		input = val
		$vibrate.visible = input > 0
		$spacer.visible = input > 0
		var text : String = "Keyboard"
		if input > 0:
			text = str("Gamepad ",input)
		elif input < 0:
			text = str("Mouse")
		$butt.text = text

var connected : Container = null
@onready var line : Line2D = $anchor/Line2D
func connect_line(node:Container):
	line.points[1] = node.anchor.global_position - line.global_position
	connected = node
	$butt.add_theme_color_override("font_color", node.color)
	line.self_modulate = node.color
	node.connected = self

func unsel():
	$butt.button_pressed = false

func _on_butt_toggled(toggled_on):
	if toggled_on:
		if connected != null:
			connected.connected = null
			for node in get_tree().get_nodes_in_group("input_remap"):
				if node.connected == connected and node != self:
					connected.connected = node
		connected = null
		selected.emit(self)
		$butt.add_theme_color_override("font_color", Color.WHITE)
		line.self_modulate = Color.WHITE
	else:
		if !connected:
			line.points[1] = Vector2(0,0)
		selected.emit(null)

func _on_vibrate_pressed():
	Input.start_joy_vibration(input-1, 0.5, 0.5, 0.5)
