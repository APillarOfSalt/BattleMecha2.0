extends Container

class_name Module_Blocks

var lock_module : bool = false:
	set(toggle):
		lock_module = toggle
		for ch in $g.get_children():
			ch.get_node("lock").visible = toggle

@export var mouse_display : bool = false

var backdrop_pos := Vector2i(-1,-1)
var backdrop_index : int = -1

@onready var style : StyleBox = preload("res://styles/moduleStylebox.tres")
@export var do_reposition : bool = true
@export var border_color : Color = Color.WHITE:
	set(col):
		border_color = col
		for ch in $g.get_children():
			ch.get_theme_stylebox("panel").border_color = col
@onready var border_width : int = 2:
	set(val):
		border_width = val
		for i in $g.get_child_count():
			set_border(i)
const DIRS : Array = ["top","right","bottom","left"]
func set_border(index:int):
	if $g.get_child(index) == null:
		return
	for i in 4:
		var dir : String = str("border_width_",DIRS[i])
		$g.get_child(index).get_theme_stylebox("panel")[dir] = vecs[index][i] * border_width


func _ready():
	if mouse_display:
		$anchor.free()
	else:
		add_to_group("mod_blocks")
		add_to_group("input")
	for i in 16:
		var sty : StyleBox = style.duplicate(true)
		sty.border_color = border_color
		$g.get_child(i).add_theme_stylebox_override("panel", sty)
var module : Module_Data = null:
	set(mod):
		module = mod
		var cell_size : Vector2 = $g.get_child(0).size
		if do_reposition:
			position = cell_size * -0.5 * dimensions
		var named : String = ""
		var xy := Vector2(80,0)
		visible = mod != null
		if mod == null:
			sub_type_setter("", "Module")
			shape = "0000000000000000"
		else:
			sub_type_setter(mod.subtype, mod.type)
			shape = mod.shape
			named = mod.name
			xy = (dimensions * cell_size)
		if mouse_display:
			return
		$anchor/title.custom_minimum_size.x = xy.x
		$anchor/title/m.custom_minimum_size.x = xy.x
		$anchor/title/m/Label.custom_minimum_size.x = xy.x
		$anchor/title/m/Label.text = "[center]"+named
		$anchor/title.size.y = 0
		$anchor/title/m.size.y = 0
		$anchor/title/m/Label.size.y = 0
		$anchor/title.position.y = (xy.y - $anchor/title.custom_minimum_size.y) * 0.5

var hovering : bool = false:
	set(toggle):
		hovering = toggle
		$anchor.visible = toggle
		if !toggle:
			return
		for node in get_tree().get_nodes_in_group("mod_blocks"):
			if node != self and node.hovering:
				node.hovering = false
		$anchor/title.size.y = 0
		$anchor/title/m.size.y = 0
		$anchor/title/m/Label.size.y = 0

					# 1_-_2_-_3_-_4_-_
var shape : String = "0000000000000000":
	set(text):
		shape = text
		vecs = _shape_edges()
		dimensions = get_extents()
		for i in 16:
			$g.get_child(i).modulate.a = shape[i].to_int()
			set_border(i)
var type : String = "Module"
var subtype : String = ""
func sub_type_setter(sub, typ):
	type = typ
	subtype = sub
	if sub != "":
		for i in 16:
			var tex : Texture = Global.type_textures[ Global.type_from_str(sub) ]
			get_node(str("g/",i,"/tex")).texture = tex
var vecs : Array
var dimensions : Vector2

enum STATES{unsel,sel,grab}
var state : int = 0:
	set(val):
		if val == state:
			return
		state = val
		match state: #new/current
			STATES.unsel:
				border_width = 2
			STATES.sel:
				border_width = 4
			STATES.grab:
				border_width = 5
func adv_state():
	match state: #new/current
		STATES.unsel:
			for mod_block in get_tree().get_nodes_in_group("mod_blocks"):
				mod_block.state = STATES.unsel
			state = STATES.grab
		STATES.sel:
			state = STATES.grab
		STATES.grab:
			state = STATES.sel

func _shape_edges(shp:String=shape, toggle:bool=false) -> Array:
	assert(shp.length() == 16, "Binary string must have exactly 16 digits.")
	var s : String = str(int(toggle))
	var directions = []
	for i in range(16):
		var x = i % 4
		var y = floor(i / 4.0)
		# Determine connections in each direction
		var vec := Vector4(1,1,1,1)
		if y != 0:
			vec.x = int(shp[i - 4] == s) # Edge or tile above
		if x != 3:
			vec.y = int(shp[i + 1] == s) # Edge or tile to the right
		if y != 3:
			vec.z = int(shp[i + 4] == s) # Edge or tile below
		if x != 0:
			vec.w = int(shp[i - 1] == s) # Edge or tile to the left
		directions.append(vec)
	return directions

func get_extents(shp:String=shape)->Vector2i:
	var extents := Vector2i(4,4)
	for x in 4:
		var do_break : bool = false
		for i in 4:
			var index : int = (3-x) + (4*i)
			if shp[index] == "1":
				do_break = true
		if do_break:
			break
		extents.x -= 1
	for y in 4:
		var do_break : bool = false
		for i in 4:
			var index : int = 15-(y*4)-i
			if shp[index] == "1":
				do_break = true
		if do_break:
			break
		extents.y -= 1
	return extents

