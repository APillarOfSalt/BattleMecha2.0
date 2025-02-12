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
@export var show_cost : bool = true
@export var show_local_sprite : bool = false
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
			s1sprite.visible = unit.size == 1
			s2sprite.visible = unit.size == 2
			if unit.size == 1:
				s1sprite.frame_coords = unit.atlas
			else:
				s2sprite.frame_coords = unit.atlas
		s1sprite.position = spr_cont.size * 0.5
		s2sprite.position = spr_cont.size * 0.5

func _ready():
	if !show_cost:
		cost.hide()
	if !show_name:
		title_cont.hide()
	if get_parent().get("unit_data") != null:
		unit_node = get_parent()
	if unit_node != null:
		unit = unit_node.unit_data

var unit_size : bool = false:
	set(toggle):
		unit_size = toggle
		if unit_node != null:
			spr_cont.custom_minimum_size = sprite_sizes[int(toggle)] * unit_node.spr_scale
const sprite_sizes : Array = [Vector2(70,50), Vector2(80,60)]
@onready var title_cont : Container = $v/title
@onready var name_l : Label = $v/title/m/name
@onready var spr_cont : Container = $v/sprite
@onready var s1sprite : Sprite2D = $v/sprite/sprite1
@onready var s2sprite : Sprite2D = $v/sprite/sprite2
@onready var stats : Unit_UI_Stats =  $v/stats
@onready var cost : Container = $v/cost

var offset : Vector2:
	get: return (sprite_sizes[int(unit_size)] * 0.5) + Vector2(0, title_cont.size.y)

func popup():
	show()
	we_hate_godot.call_deferred()
func we_hate_godot():
	position = -offset
	s1sprite.position = spr_cont.size * 0.5
	s2sprite.position = spr_cont.size * 0.5
