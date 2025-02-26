extends MarginContainer

signal countdown_complete()

func _start():
	if tick > 0:
		return
	tick_count = 0
	count_l.text = "3"
	show()
	tick = Time.get_ticks_msec()
func _stop():
	tick = -1
	hide()

@onready var count_l : Label = $anchor/countdown

@export_range(0,99,1) var count_to : int = 3
@export var tick_speed_msec : int = 1000
@onready var tick : int = -1
var tick_count : int: set = _tick_count_setter
func _tick_count_setter(val:int):
	tick_count = val
	count_l.text = str(count_to - val)
	if val == count_to:
		count_l.text = "Go"
		countdown_complete.emit()

func _process(_delta):
	if tick == -1:
		return
	var diff : int = Time.get_ticks_msec() - tick
	if diff < tick_speed_msec:
		return
	tick = Time.get_ticks_msec() - (diff-tick_speed_msec)
	tick_count += floor( float(diff) / float(tick_speed_msec) )
