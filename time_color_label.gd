extends Label
class_name Color_Label

signal hold_status(stop_start:bool)

signal repeat_adv(index:int)
signal interrupt_adv()
signal first_reached()

#the label will repeat shifting between colors in repeat_colors
#if interrupt_colors.size()
#	it will shift until it reaches interrupt_colors.front()
#	and it will pop_front() that color from the array

@export var max_shift : float = 0.01
@export var max_shift_for_first : float = 0.025

@export var default_r_hold : int = 0
@export var repeat_text : Array[String]
var r_index : int = 0
@export var r_holds_msec : Array[int] #set this first during runtime
@export var repeat_colors : Array[Color]:
	set(arr):
		repeat_colors = arr
		while true:
			var diff : int = r_size - r_holds_msec.size()
			if diff == 0:
				return
			elif diff < 0:
				r_holds_msec.pop_back()
			elif diff > 0:
				r_holds_msec.append(default_r_hold)
var r_size : int:
	get: return repeat_colors.size()

@export var interrupt_text : Array[String]
@export var i_holds_msec : Array[int]
@export var interrupt_colors : Array[Color]
var i_size : int:
	get: return interrupt_colors.size()

var first_text : String = ""
var this_first = null: #if Color: it will shift to this color before doing the next normal action
	set(col):
		if !(col is Color or col == null):
			return
		r_index = 0
		hold_start_msec = -1
		this_first = col
var first_hold : float = 0.0
#negative means the text will change to first_text AFTER first_hold is over
#positive means the text will change to first_text WHEN modulate first == this_first, on hold start

var hold_start_msec : int = -1
func _process(_delta):
	var next_color : Color = modulate
	if this_first is Color:
		if hold_start_msec == -1:
			if first_hold > 0:
				text = first_text
				first_text = ""
		if !check_hold(this_first, abs(first_hold) ):
			next_color = this_first
		else:
			if first_hold < 0:
				text = first_text
				first_text = ""
			first_reached.emit() ##		SIGNAL EMIT
			first_hold = 0.0
			this_first = null
	elif i_size:
		var i_col : Color = interrupt_colors.front()
		if modulate == i_col:
			if !i_holds_msec.size(): #if no wait timer
				interrupt_colors.pop_front() #pop if we reached the target
			elif check_hold(i_col, i_holds_msec.front()): #else if wait timer done
				i_holds_msec.pop_front() #pop
				interrupt_colors.pop_front()
				if interrupt_text.size():
					text = interrupt_text.pop_front()
				interrupt_adv.emit() ##		SIGNAL EMIT
		if i_size:
			next_color = interrupt_colors.front()
	elif r_size:
		r_index = (r_index + r_size) % r_size
		next_color = repeat_colors[r_index]
		if repeat_text.size() > r_index:
			text = repeat_text[r_index]
		if next_color == modulate and check_hold(next_color, r_holds_msec[r_index]):
			r_index = (r_index + 1 + r_size) % r_size
			repeat_adv.emit(r_index) ##		SIGNAL EMIT
		next_color = repeat_colors[r_index]
		if repeat_text.size() > r_index:
			text = repeat_text[r_index]
	if next_color != modulate:
		modulate = do_lerp(next_color)

func check_hold(target:Color, msec:int):
	if msec == 0:
		return true
	if modulate == target:
		var t : int = Time.get_ticks_msec()
		if hold_start_msec == -1:
			hold_start_msec = t
			hold_status.emit(true)
		if t - hold_start_msec >= msec:
			hold_status.emit(false)
			hold_start_msec = -1
			return true
	return false

func do_lerp(target:Color, current:Color=modulate)->Color:
	if current.a == 0.0 and target.a == 0.0:
		return target
	var t_vec : Vector4 = col_to_vec(target)
	var c_vec : Vector4 = col_to_vec(current)
	var diff : Vector4 = t_vec - c_vec
	var shift : Vector4 =  diff.normalized() * max_shift
	if this_first is Color:
		shift = diff.normalized() * max(max_shift_for_first,max_shift)
	if shift.length() > diff.length():
		shift = diff
	return vec_to_col( c_vec + shift )

func col_to_vec(col:Color)->Vector4:
	return Vector4(col.r, col.g, col.b, col.a)
func vec_to_col(vec:Vector4)->Color:
	return Color(vec.x, vec.y, vec.z, vec.w)

