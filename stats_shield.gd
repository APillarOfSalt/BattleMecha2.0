extends Container

@onready var bg_rects : Array = [$bg0/a0, $bg0/a1, $bg0/a2, $bg0/a3]
@onready var bg_sprs : Array = [$bg1/a/spr, $bg1/b/spr, $bg1/c/spr, $bg1/d/spr]
@onready var shield_sprs : Array = [
	[$"fg0/1_4/spr", $"fg0/5_8/spr", $"fg0/9_12/spr", $"fg0/13_16/spr"],
	[$"fg1/17_20/spr", $"fg1/21_24/spr", $"fg1/25_28/spr", $"fg1/29_32/spr"]
]
@onready var regen_sprs : Array = [
	[$regen0/a/spr, $regen0/b/spr, $regen0/c/spr, $regen0/d/spr],
	[$regen1/a/spr, $regen1/b/spr, $regen1/c/spr, $regen1/d/spr]
]
func _ready():
	clear()
func clear():
	max = 0
	current = 0
	regen = 0

signal finished()

func do_regen():
	if set_cur < set_max:
		set_cur = min(set_max, set_cur + set_regen)
		normalize_current()

func set_current(val:int)->Signal:
	set_cur = val
	normalize_current()
	return finished

var set_max: int = -1
var set_cur: int = -1
var set_regen : int = -1
func setup(max_val:int, cur_val:int, reg_val:int):
	set_max = max_val
	set_cur = cur_val
	set_regen = reg_val
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
	if current > set_cur:
		current -= 1
		if regen - set_regen > current:
			regen -= 1
	elif current < set_cur:
		current += 1
		if regen < current:
			regen += 1
	elif regen != min(set_max, set_cur + set_regen):
		regen += sign(min(set_max, set_cur + set_regen) - regen)
	else:
		finished.emit()
		return 
	await get_tree().create_timer(0.0625).timeout
	normalize_current()


var current : int = -1 : set = shield_setter
var max : int = -1: set = max_setter
var regen : int = -1 : set = regen_setter

func max_setter(val:int):
	max = val
	for i in 4:
		bg_rects[i].visible = val > i*4
		bg_sprs[i].visible = val > i*4
		for j in 4:
			var index : int = (i*4) + j
			if index >= val:
				break
			bg_sprs[i].frame = j

func shield_setter(val:int):
	current = val
	for i in 2: #hp0:1-16/hp1:17-32
		for j in 4: #hp0:1-4/ hp1:5-8/ hp2:9-12/ hp3:13-16 | hp0:17-20/ hp1:21-24/ hp2:25-28/ hp3:29-32
			shield_sprs[i][j].visible = val > (i*16) + (j*4)
			shield_sprs[i][j].frame = 0
			for k in 4: #hide/frame0/frame1/frame2/frame3
				var index : int = (i*16) + (j*4) + k
				if index >= val:
					break
				shield_sprs[i][j].frame = k

func regen_setter(val:int):
	regen = val 
	for i in 2:
		for j in 4:
			regen_sprs[i][j].visible = regen > (i*16) + (j*4)
			regen_sprs[i][j].frame = 0
			for k in 4:
				var index : int = (i*16) + (j*4) + k
				if index >= regen:
					break
				regen_sprs[i][j].frame = k


