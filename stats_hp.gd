extends Container

@onready var bg_sprs : Array = [$bg/hp0/spr, $bg/hp1/spr, $bg/hp2/spr, $bg/hp3/spr]
@onready var hp_sprs : Array = [
	[$"hp0/1_4/spr", $"hp0/5_8/spr", $"hp0/9_12/spr", $"hp0/13_16/spr"],
	[$"hp1/17_20/spr", $"hp1/21_24/spr", $"hp1/25_28/spr", $"hp1/29_32/spr"]
]
func _ready():
	clear()
func clear():
	current = 0
	max = 0

signal finished()

func set_current(val:int)->Signal:
	set_cur = val
	normalize_current()
	return finished

var set_max: int = -1
var set_cur : int = -1
func setup(val:int):
	set_max = val
	set_cur = val
	increase_max()
func increase_max():
	if max < min(set_max,16):
		max += 1
		await get_tree().create_timer(0.1).timeout
		increase_max()
	else:
		max = set_max
		await get_tree().create_timer(0.1).timeout
		normalize_current()
func normalize_current():
	if current != set_cur:
		current += sign(set_cur-current)
		await get_tree().create_timer(0.0625).timeout
		normalize_current()
	else:
		finished.emit()

var current : int = -1 : set = hp_setter
var max : int = -1:
	set(val):
		max = val
		for i in 4:
			bg_sprs[i].visible = val > i*4
			bg_sprs[i].frame = 0
			for j in 4:
				var index : int = (i*4) + j
				if index >= val:
					break
				bg_sprs[i].frame = j

func hp_setter(val:int):
	current = val
	for i in 2: #hp0:1-16/hp1:17-32
		for j in 4: #hp0:1-4/ hp1:5-8/ hp2:9-12/ hp3:13-16 | hp0:17-20/ hp1:21-24/ hp2:25-28/ hp3:29-32
			hp_sprs[i][j].visible = val > (i*16) + (j*4)
			hp_sprs[i][j].frame = 0
			for k in 4: #hide/frame0/frame1/frame2/frame3
				var index : int = (i*16) + (j*4) + k
				if index >= val:
					break
				hp_sprs[i][j].frame = k



