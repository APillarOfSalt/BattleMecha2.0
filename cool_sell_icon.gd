extends Node2D

@export var cursor : Map_Cursor
@onready var w : Sprite2D = $w
@onready var b : Sprite2D = $b

enum HOVER{no=0, without=1, with=2}
var hovered := HOVER.no
@export var map_pos : Vector2i
@export_range(0,2,1) var index : int = 0
func _ready():
	await get_parent().ready
	if cursor != null:
		cursor.moved.connect(_on_cursor_new_pos)
		map_pos = get_parent().local_trash[index]
	position = get_parent().map_to_local( map_pos )
func _on_cursor_new_pos():
	if cursor.map_pos == map_pos:
		animate_vis(true)
	elif cursor.map_pos != map_pos:
		animate_vis(false)
@export var tick_speed_msec : int = 100
@onready var tick : int = T
var count : int = 0
var T : int:
	get: return Time.get_ticks_msec()
func _process(delta):
	if tick > 0 or !visible:
		var diff : int = T - tick
		if diff >= tick_speed_msec:
			var extra : int = (T - tick) % tick_speed_msec
			tick = T + extra
			do_tick()
func do_tick():
	count += 1
	if count%2:
		w.flip_h = !w.flip_h
		b.flip_v = !b.flip_v
	else:
		w.flip_v = !w.flip_v
		b.flip_h = !b.flip_h
		if anim_count:
			anim_count += 1
			if anim_count == 0:
				hide()
				return
			w.frame = abs(anim_count) - 1
			b.frame = abs(anim_count) - 1
			if abs(anim_count) >= 4:
				anim_count = 0
		var holding : bool = false
		if cursor != null:
			holding = cursor.held_object != null
		if !holding or cursor.map_pos != map_pos:
			w.frame = min(w.frame, 2)
			b.frame = min(b.frame, 2)
		elif !anim_count and w.frame == 2:
			w.frame += 1 
			b.frame += 1

var anim_count : int = 0
func animate_vis(vis:bool):
	if map_pos in get_parent().get_used_cells(1) and !vis:
		return
	var fr1 : int = w.frame + 1
	if vis:
		show()
		anim_count = max(1, fr1)
	else:
		anim_count = -min(4, fr1)


