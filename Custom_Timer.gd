extends Node
class_name Custom_Timer

signal one_tick(num:int)

@export var tick_speed_msec : int = 1000
@export var autostart : bool = false
@onready var tick : int = -int(!autostart)
var tick_num : int

func _process(_delta):
	if tick == -1:
		return
	var diff : int = Time.get_ticks_msec() - tick
	if diff < tick_speed_msec:
		return
	tick = Time.get_ticks_msec() - (diff-tick_speed_msec)
	tick_num += floor( float(diff) / float(tick_speed_msec) )
	one_tick.emit(tick_num)
