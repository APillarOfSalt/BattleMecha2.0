extends HBoxContainer

signal out_of_actions()

@rpc("any_peer", "call_local", "reliable")
func remote_set(val:int):
	current = val
	if val == 0:
		out_of_actions.emit()
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
