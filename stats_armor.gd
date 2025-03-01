extends MarginContainer

@onready var tex_rects : Array = [
	[$bg/m1/rect, $bg/m0/rect, $bg/m2/rect],
	[$mg/m1/rect, $mg/m0/rect, $mg/m2/rect],
	[$fg/m1/rect, $fg/m0/rect, $fg/m2/rect]
]
func _ready():
	clear()
func clear():
	max = 0

signal finished_setup()

var set_max : int = -1
func setup(val:int):
	set_max = val
	increase()
func increase():
	if max < set_max:
		max += 1
		await get_tree().create_timer(0.25).timeout
		increase()
	else:
		finished_setup.emit()
var max : int = -1:
	set(val):
		max = val
		for i in 3:
			for j in 3:
				var index : int = (i*3) + j
				tex_rects[i][j].visible = index < val
