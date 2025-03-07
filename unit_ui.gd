extends Container
class_name Unit_Ui

var ui_scene : PackedScene = load("res://unit_ui.tscn")
func _duplicate(sn:bool=show_name, sc:bool=show_cost, sls:bool=show_local_sprite)->Unit_Ui:
	var dup = ui_scene.instantiate()
	dup.unit_node = unit_node
	dup.show_name = sn
	dup.show_cost = sc
	dup.show_local_sprite = sls
	return dup

@export var show_name : bool = true
@export var show_cost : bool = true:
	set(toggle):
		show_cost = toggle
		if !is_inside_tree():
			return
		cost.visible = toggle
@export var show_local_sprite : bool = false
@export var do_setup : bool = false
var unit_node : Unit_Node = null

var unit : Unit_Data:
	set(u):
		unit = u
		if u == null:
			stats.clear()
			cost.clear()
			name_l.text = "Unit"
			s1sprite.hide()
			s2sprite.hide()
			return
		if !u._initialized:
			u._initialize()
		unit_size = bool(u.size-1)
		stats.setup(u)
		cost.set_cost(u.cost)
		name_l.text = u.name
		title_cont.visible = show_name
		cost.visible = show_cost
		if show_local_sprite:
			s1sprite.visible = unit.size != 2
			s2sprite.visible = unit.size == 2
			if unit.size != 2:
				s1sprite.frame_coords = unit.atlas
			else:
				s2sprite.frame_coords = unit.atlas
		if do_setup:
			stats._start_turn()

func _ready():
	cost.visible = show_cost
	title_cont.visible = show_name
	if unit is Unit_Data:
		s1sprite.visible = show_local_sprite and unit.size == 1
		s2sprite.visible = show_local_sprite and unit.size == 2
	if get_parent() is Unit_Node:
		unit_node = get_parent()
		unit = get_parent().unit_data

var unit_size : bool = false:
	set(toggle):
		unit_size = toggle
		if unit_node != null:
			spr_cont.custom_minimum_size = sprite_sizes[int(toggle)] * unit_node.spr_scale
const sprite_sizes : Array = [Vector2(70,50), Vector2(80,60)]
@onready var title_cont : Container = $title
@onready var name_l : Label = $title/m/name
@onready var spr_cont : Container = $content/sprites
@onready var s1sprite : Sprite2D = $content/sprites/anchor/size1
@onready var s2sprite : Sprite2D = $content/sprites/anchor/size2
@onready var stats : Unit_UI_Stats = $content/stats
@onready var cost : Cost_Data = $cost

var offset : Vector2:
	get: return (sprite_sizes[int(unit_size)] * 0.5) + Vector2(0, title_cont.size.y)

func popup():
	show()
	we_hate_godot.call_deferred()
func we_hate_godot():
	position = -offset

enum COST_VIS{cost=-1,hidden=0,sale=1}
func set_cost_vis(vis:COST_VIS):
	show_cost = bool(vis)
	cost.flip_colors = false
	if vis < 0:
		cost.set_cost(unit.cost)
	elif vis > 0:
		cost.flip_colors = true
		cost.set_cost(unit.sale)

