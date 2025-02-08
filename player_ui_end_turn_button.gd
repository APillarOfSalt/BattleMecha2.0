extends MarginContainer

@export var action_cont : Container = null

func _reset():
	pressed = false
	$Button.disabled = false

var pressed : bool = false:
	set(toggle): $Button.button_pressed = toggle
	get: return $Button.button_pressed
var current : int:
	get: return action_cont.current

func _on_actions_out_of_actions():
	pressed = true
	$Button.disabled = true
	$h/Label.text = "Out of Actions"

const tooltip : String = "Only 1 unused action can rollover"
func _on_button_focus_entered():
	var toggle : bool = current > 1
	$Button.tooltip_text = ["",tooltip][int(toggle)]
	$h/l.visible = toggle
	$h/r.visible = toggle
func _on_button_focus_exited():
	var toggle : bool = current > 1 and pressed
	$Button.tooltip_text = ["",tooltip][int(toggle)]
	$h/l.visible = toggle
	$h/r.visible = toggle
func _on_button_mouse_entered():
	var toggle : bool = current > 1
	$Button.tooltip_text = ["",tooltip][int(toggle)]
	$h/l.visible = toggle
	$h/r.visible = toggle
func _on_button_mouse_exited():
	var toggle : bool = current > 1 and pressed
	$Button.tooltip_text = ["",tooltip][int(toggle)]
	$h/l.visible = toggle
	$h/r.visible = toggle
func _on_button_toggled(toggled_on):
	$h/Label.text = ["End Turn", "Cancel End Turn"][int(toggled_on)]
	_remote_end.rpc(toggled_on)
	if toggled_on:
		get_parent().out_of_actions.emit()
@rpc("any_peer", "call_remote", "reliable")
func _remote_end(is_end:bool):
	pressed = is_end
