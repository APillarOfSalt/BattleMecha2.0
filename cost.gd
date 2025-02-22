@tool
extends GridContainer

class_name Cost_Data

const ele_strs : Array = ["titanium","gallium","aluminum","cobalt"]
enum vis_indicies{ti=0,ga=1,al=2,co=3}
enum vis_flags{ti=1,ga=2,al=4,co=8}
@export_flags("titanium:1","gallium:2","aluminum:4","cobalt:8") var override_visible : int:
	set(val):
		override_visible = val
		if !is_inside_tree():
			return
		refresh_vis.call_deferred()
#negative means it ADDs that amount of money
@onready var elements_n : Array = [$ti, $ga, $al, $co]
@onready var elements_s : Array = [$ti_s, $ga_s, $al_s, $co_s]
@onready var elements_l : Array = [$ti_l/l, $ga_l/l, $al_l/l, $co_l/l]

@export var simplified : bool = false:
	set(toggle):
		simplified = toggle
		if !is_inside_tree():
			return
		refresh_vis.call_deferred()
@export var flip_colors : bool = false:
	set(toggle):
		flip_colors = toggle
		if !is_inside_tree():
			return
		refresh_vis.call_deferred()
		flip_sign = int(flip_colors) - int(!flip_colors)#==true: val is +,  ==false: val is -
var flip_sign : int = -1
@export var font_size_override : int = 18:
	set(val):
		font_size_override = val
		if !is_inside_tree():
			return
		for e in elements_l:
			e.add_theme_font_size_override("font_size", val)
func _ready():
	font_size_override = font_size_override
	refresh_vis.call_deferred()
	for e in elements_l:
		e.add_theme_font_size_override("font_size", font_size_override)
	set_val("ti", titanium)
	set_val("ga", gallium)
	set_val("al", aluminum)
	set_val("co", cobalt)

func refresh_vis():
	for i in 4:
		var s : String = ele_strs[i]
		var vis : bool = self[s] != 0 or (override_visible & vis_flags[s.substr(0,2)])
		elements_n[i].visible = !simplified and ( vis )
		elements_s[i].visible = simplified and ( vis )
		elements_l[i].visible = vis
		var col : Color = Color.WHITE
		if self[ele_strs[i]] < 0:
			col = [Color.LIME_GREEN,Color.ORANGE_RED][int(flip_colors)]
		elif self[ele_strs[i]] > 0:
			col = [Color.LIME_GREEN,Color.ORANGE_RED][int(!flip_colors)]
		elements_l[i].add_theme_color_override("font_color",col)
		get_node(str("c",i)).visible = vis

@export var titanium : int = 0: 
	set(val):
		titanium = val
		if !is_inside_tree():
			return
		set_val("ti", val)
@export var gallium : int = 0: 
	set(val):
		gallium = val
		if !is_inside_tree():
			return
		set_val("ga", val)
@export var aluminum : int = 0: 
	set(val):
		aluminum = val
		if !is_inside_tree():
			return
		set_val("al", val)
@export var cobalt : int = 0: 
	set(val):
		cobalt = val
		if !is_inside_tree():
			return
		set_val("co", val)

func get_val(index:int)->int:
	return self[ele_strs[index]]
func set_val(res:String, val:int):
	var index : int = vis_indicies[res]
	elements_l[index].text = str(val)
	if !flip_colors:
		elements_l[index].text = elements_l[index].text.replace("-","+")
	#var toggle : bool = val != 0 and override_visible | flag
	refresh_vis()
func set_cost(cost:Dictionary):
	for i in ele_strs:
		if i in cost:
			self[i] = cost[i]
func clear():
	for i in ele_strs:
		self[i] = 0

func add_with(cost:Cost_Data):
	for i in ele_strs:
		self[i] += cost[i] * cost.flip_sign
func mod_cost_by(cost:Dictionary):
	for i in ele_strs:
		if i in cost:
			self[i] += cost[i] * -flip_sign
			#if RED:false, +1 == higher price, -1==lower price
			#if GREEN:true, +1 == more asset, -1==less asset

	#elements_n[res-1].visible = toggle and !simplified
	#elements_s[res-1].visible = toggle and simplified
	#elements_l[res-1].visible = toggle
