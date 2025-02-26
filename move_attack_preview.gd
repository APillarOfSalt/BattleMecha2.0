extends PanelContainer

#false:move, true:weapon
@export_enum("Move","Weapon") var mode : int = 0:
	set(toggle):
		mode = toggle
		if !is_inside_tree():
			return
		_refresh()
@export var push_dir : int = -1
func _on_push_dir_changed(dir:int):
	push_dir = dir
	refresh()


func _ready():
	_refresh()
	shader_mat.shader = mat_shader

func _refresh():
	$m/move.visible = !mode
	$m/wep.visible = mode
	var hue : float =  0.36 * int(!mode)
	var col := Color.from_hsv(hue, 0.8, 1.0, 1.0)
	$map.set_layer_modulate(2,col)
	col = Color.from_hsv(hue, 0.8, 1.0 - (0.3*int(!mode)), 1.0)
	$map.set_layer_modulate(1,col)

#Vertical    ___
#Odd Q   ___/ 0 \___
#    ___/-1 \-2_/+1 \___
#   /-2 \-2_/ 0 \-2_/+2 \
#   \-1_/-1 \-1_/+1 \-1_/
#   /-2 \-1_/x:0\-1_/+2 \
#   \_0_/-1 \y:0/+1 \_0_/
#   /-2 \_0_/ 0 \_0_/+2 \
#   \+1_/-1 \+1_/+1 \+1_/
#       \+1_/ 0 \+1_/   
#           \+2_/
const DIRS_CUBE : Array[Vector3i] = [
	Vector3i(0,-1,1),Vector3i(1,-1,0),Vector3i(1,0,-1),
	Vector3i(0,-1,1),Vector3i(-1,1,0),Vector3i(-1,0,1)
]
func oddq_to_cubic(vec:Vector2i)->Vector3i:
	var q = vec.x
	var r = vec.y - (vec.x - (vec.x&1)) / 2
	return Vector3i(q, r, -q-r)
func cubic_to_oddq(vec:Vector3i)->Vector2i:
	var col = vec.x
	var row = vec.y + (vec.x - (vec.x&1)) / 2
	return Vector2i(col, row)

func get_equal_pos(pos:Vector2i, prev_next:bool):
	var cube : Vector3i = oddq_to_cubic(pos)
	if prev_next:#true : next, 60deg cw
		return cubic_to_oddq(Vector3i(cube.z, cube.x, cube.y))
	#false : prev, 60deg ccw
	return cubic_to_oddq(Vector3i(cube.y, cube.z, cube.x))

var tiles : Array = []
var bonus_tiles : Array = []

func set_data(data:Array):
	tiles = data
	refresh()

func clear():
	tiles = []
	bonus_tiles = []
	refresh()

func get_data()->Array[Vector2i]:
	return $map.get_used_cells_by_id(1)

func refresh():
	for i in 3:
		$map.clear_layer(i+1)
	for line in lines.values():
		line.queue_free()
	lines.clear()
	for vec in tiles:
		$map.set_cell(1, vec, 0, Vector2i(1,0))
		set_push_vec(vec, true)
	for vec in bonus_tiles:
		$map.set_cell(2, vec, 0, Vector2i(1,0))
		set_push_vec(vec, true)

var lines : Dictionary = {}
func set_push_vec(map_pos:Vector2i, io:bool):
	if !mode or push_dir < 0 or push_dir > 5:
		return
	var zero_pos : Vector2 = $map.map_to_local(Vector2(0,0))
	var loc_pos : Vector2 = $map.map_to_local(map_pos)
	var pos_dir : int = int(Global.dir_from_vec(loc_pos - zero_pos) + 5) % 6
	var push_vec : Vector2i = Global.get_relative(map_pos.x, (push_dir + pos_dir) % 6 )
	var push_map : Vector2i = map_pos + push_vec
	if io:
		create_arrow(map_pos, push_map)
		$map.set_cell(3, push_map, 0, Vector2i(0,0))
	elif map_pos in lines.keys():
		lines[map_pos].queue_free()
		lines.erase(map_pos)
		$map.set_cell(3, push_map)

var cursor_map_pos : Vector2i
func _physics_process(_delta):
	cursor_map_pos = $map.local_to_map( $map.get_local_mouse_position() )
	$map.clear_layer(4)
	if cursor_map_pos in $map.get_used_cells_by_id(0, 0, Vector2i(0,0)):
		$map.set_cell(4, cursor_map_pos, 0, Vector2i(0,0),1)
		if Input.is_action_just_pressed("lmb"):
			$map.set_cell(1, cursor_map_pos, 0, Vector2i(1,0))
			set_push_vec(cursor_map_pos, true)
		elif Input.is_action_just_pressed("rmb"):
			$map.set_cell(1, cursor_map_pos)
			set_push_vec(cursor_map_pos, false)

var shader_mat := ShaderMaterial.new()
const mat_shader : Shader = preload("res://alpha_overlaps.gdshader")

func create_arrow(map_pos:Vector2i, push_map:Vector2i):
	var loc_pos : Vector2 = $map.map_to_local(map_pos)
	var line := Line2D.new()
	$CanvasGroup.add_child(line)
	line.width = 6
	line.material = shader_mat
	line.position = loc_pos
	line.add_point( Vector2(0,0) )
	var to_point : Vector2 = $map.map_to_local(push_map) - loc_pos
	create_arrow_head(line, to_point)
	line.add_point( to_point.limit_length(42) )
	lines[map_pos] = line
	

func create_arrow_head(line:Line2D, to_point:Vector2):
	var rot : float = deg_to_rad(45)
	for i in 2:
		var head := Line2D.new()
		line.add_child(head)
		head.width = 6
		head.material = shader_mat
		head.end_cap_mode = Line2D.LINE_CAP_BOX
		head.begin_cap_mode = Line2D.LINE_CAP_BOX
		head.position = to_point.limit_length(45)
		head.add_point( Vector2(0,0) )
		head.add_point( -to_point.limit_length(15).rotated(rot) )
		rot *= -1
