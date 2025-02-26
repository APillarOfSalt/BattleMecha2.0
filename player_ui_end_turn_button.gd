extends MarginContainer

@export var action_cont : Container = null
@onready var butt : Button = $Button
var locally_owned : bool = true

func _set_butt_mouse_off():
	butt.mouse_filter = MOUSE_FILTER_IGNORE
	_on_button_focus_exited()
func _reset():
	pressed = false
	butt.disabled = false
	butt.mouse_filter = MOUSE_FILTER_STOP
	_on_button_focus_exited()

var pressed : bool = false:
	set(toggle): butt.button_pressed = toggle
	get: return butt.button_pressed
var current : int:
	get: return action_cont.current

func _on_out_of_actions():
	pressed = true
	butt.disabled = true
	$h/Label.text = "Out of Actions"

const tooltip : String = "Only 1 unused action can rollover"
func _on_button_focus_entered():
	var toggle : bool = current > 1
	butt.tooltip_text = ["",tooltip][int(toggle)]
	$h/l.visible = toggle
	$h/r.visible = toggle
func _on_button_focus_exited():
	var toggle : bool = current > 1 and pressed
	butt.tooltip_text = ["",tooltip][int(toggle)]
	$h/l.visible = toggle
	$h/r.visible = toggle
func _on_button_mouse_entered():
	var toggle : bool = current > 1
	butt.tooltip_text = ["",tooltip][int(toggle)]
	$h/l.visible = toggle
	$h/r.visible = toggle
func _on_button_mouse_exited():
	var toggle : bool = current > 1 and pressed
	butt.tooltip_text = ["",tooltip][int(toggle)]
	$h/l.visible = toggle
	$h/r.visible = toggle
func _on_button_toggled(toggled_on):
	if !toggled_on:
		$h/Label.text = "End Turn"
	elif locally_owned:
		$h/Label.text = "Cancel End Turn"
	else:
		$h/Label.text = "Turn Ended"
	if locally_owned:
		_remote_end.rpc(toggled_on)
		if toggled_on:
			get_parent().out_of_actions.emit()
@rpc("any_peer", "call_remote", "reliable")
func _remote_end(is_end:bool):
	pressed = is_end
