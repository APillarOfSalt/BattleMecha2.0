extends MarginContainer

@export var tick_speed_msec : int = 1000
@onready var tick : int = -1
var tick_num : int
func _process(_delta):
	if tick == -1:
		return
	var diff : int = Time.get_ticks_msec() - tick
	if diff < tick_speed_msec:
		return
	tick = Time.get_ticks_msec() - (diff-tick_speed_msec)
	tick_num += floor( float(diff) / float(tick_speed_msec) )
	
	$anchor/countdown.text = str(3-tick_num)
	if tick_num == 3 and multiplayer.get_unique_id() == 1:
		get_parent().start_the_game()
