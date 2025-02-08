extends PanelContainer

#false:move, true:weapon
@export_enum("Move=0","Weapon=1") var mode : int = 0:
	set(toggle):
		mode = toggle
		if !is_inside_tree():
			return
		_refresh()

func _ready():
	_refresh()

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

var movement : Array = []:
	set(arr):
		movement = arr
		$map.clear_layer(1)
		for vec in arr:
			$map.set_cell(1, vec, 0, Vector2i(1,0))
var bonus_movement : Array = []:
	set(arr):
		bonus_movement = arr
		$map.clear_layer(2)
		for vec in arr:
			$map.set_cell(2, vec, 0, Vector2i(1,0))

func set_data(data:Array):
	movement = data

func clear():
	movement = []
	bonus_movement = []

func get_data()->Array[Vector2i]:
	return $map.get_used_cells_by_id(1)

func refresh():
	for i in 6:
		for num in movement[i]:
			var map_pos : Vector2i = cubic_to_oddq( (DIRS_CUBE[i].sign())*Vector3i((DIRS_CUBE[i]*(num+1))).abs() )
			print("Setting Cell :",map_pos)
			$map.set_cell(2, map_pos, 0, Vector2i(1,0))

var cursor_map_pos : Vector2i
func _physics_process(_delta):
	cursor_map_pos = $map.local_to_map( $map.get_local_mouse_position() )
	$map.clear_layer(3)
	if cursor_map_pos in $map.get_used_cells_by_id(0, 0, Vector2i(0,0)):
		$map.set_cell(3, cursor_map_pos, 0, Vector2i(0,0),1)
		if Input.is_action_just_pressed("lmb"):
			$map.set_cell(1, cursor_map_pos, 0, Vector2i(1,0))
		elif Input.is_action_just_pressed("rmb"):
			$map.set_cell(1, cursor_map_pos)
