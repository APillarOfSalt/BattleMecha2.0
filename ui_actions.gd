extends HBoxContainer

signal actions_changed(remain:int)

func can_act()->bool:
	return current > 0
func reset_actions():
	current = total
	remote_set.rpc(current)
	actions_changed.emit(current)
func spend_action()->bool:
	if current <= 0:
		return false
	current -= 1
	remote_set.rpc(current)
	actions_changed.emit(current)
	return true

@rpc("any_peer", "call_remote", "reliable")
func remote_set(val:int):
	current = val

var current : int = 0:
	set(val):
		current = val
		$val.text = str(val)
		$val.modulate = colors[val]
const total : int = 3
@export var colors : Array[Color] = [Color.RED, Color.ORANGE, Color.YELLOW, Color.GREEN]

func _ready():
	$total.text = str("/",total)
	current = total
