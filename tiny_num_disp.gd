extends HBoxContainer


func setup(m:int,c:int,a:int=0,o:bool=false):
	suppress_refresh = true
	maximum = m
	current = c
	if o:
		operator = OP.multiply
	else:
		operator = OP.plus
	argument = a
	_refresh(true)

func get_color_from(c:int=current, m:int=maximum)->Color:
	if c == 0:
		return color_min
	var index : int = floor( 4.0 * float(c) / float(m) )
	return [color_quarter, color_half, color_max, color_max][index-1]

@export_group("Colors")
@export_color_no_alpha var default_color := Color.WHITE
@export_color_no_alpha var color_max := Color.FOREST_GREEN
@export_color_no_alpha var color_half := Color.CORAL
@export_color_no_alpha var color_quarter := Color.CRIMSON
@export_color_no_alpha var color_min := Color(0.1,0,0,1.0)
@export_group("Properties")
@export var hide_tens : bool = false:
	set(toggle):
		var do_refresh : bool = hide_tens != toggle
		hide_tens = toggle
		if !is_inside_tree():
			return
		if do_refresh:
			_refresh()
@export var maximum : int = 0:
	set(val):
		var do_refresh : bool = maximum != val
		maximum = val
		if !is_inside_tree():
			return
		if do_refresh:
			_refresh()
@export_group("Values")
@export var current : int = 0:
	set(val):
		var do_refresh : bool = current != val
		current = val
		if !is_inside_tree():
			return
		if do_refresh:
			_refresh()
enum OP{none=-1,minus=0,plus=1,equal=2,divide=3,multiply=4}
@export_enum("none:-1","minus:0","plus:1","equal:2","divide:3","multiply:4") var operator : int = OP.plus:
	set(val):
		var do_refresh : bool = operator != val
		operator = val
		if !is_inside_tree():
			return
		if do_refresh:
			_refresh()
@export var argument : int = 0:
	set(val):
		var do_refresh : bool = argument != val
		argument = val
		if !is_inside_tree():
			return
		if do_refresh:
			_refresh()

@onready var cur_node : Tiny_Digit_Display = $disp/current
@onready var max_node : Tiny_Digit_Display = $disp/max
@onready var arg_node : Tiny_Digit_Display = $left/argument/num
@onready var op_spr : Sprite2D = $left/argument/operator/op
@onready var total_node : Tiny_Digit_Display = $left/total/num

func _input(event):
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_0:
				push_arg(0)
			elif event.keycode == KEY_1:
				push_arg(1)
			elif event.keycode == KEY_2:
				push_arg(2)

func _ready():
	_refresh()
func push_arg(arg:int):
	suppress_refresh = true
	current = total_node.val
	argument = arg
	_refresh(true)

func _recalc_total():
	var val : int = current
	match operator:
		OP.minus:
			val -= argument
		OP.plus:
			val += argument
		OP.equal:
			val = argument
		OP.divide:
			val /= argument
		OP.multiply:
			val *= argument
	val = clamp(val, 0, maximum)
	total_node.val = val

var suppress_refresh : bool = false
func _refresh(un_supress:bool=false):
	if un_supress:
		suppress_refresh = false
	if suppress_refresh:
		return
	_refresh_operator()
	$left.visible = operator != OP.none
	_recalc_total()
	cur_node.val = current
	max_node.val = maximum
	arg_node.val = abs(argument)
	_refresh_colors()
	cur_node.hide_tens = hide_tens
	max_node.hide_tens = hide_tens
	arg_node.hide_tens = hide_tens
	total_node.hide_tens = hide_tens

func _refresh_operator():
	if argument > 0:
		if operator >= OP.divide: # * & /
			operator = OP.multiply #⮡ *
		else:
			operator = OP.plus #⮡ +
	elif argument > 0:
		if operator >= OP.divide: # * & /
			operator = OP.divide #⮡ /
		else:
			operator = OP.minus #⮡ -
	else:
		operator = OP.none

func _refresh_colors():
	cur_node.modulate = get_color_from()
	max_node.modulate = default_color
	op_spr.modulate = default_color
	arg_node.modulate = default_color
	total_node.modulate = get_color_from(total_node.val)



