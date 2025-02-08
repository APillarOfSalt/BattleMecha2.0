extends Node2D

class_name Hand_Tile

var unit : Unit_Node = null:
	set(node):
		if unit != null:
			return
		unit = node
		if unit != null:
			unit.reparent( follow, false )

@export_enum("Left:0","Right:1") var left_or_right : int
@onready var progress : Array = [null,0 , 64.0, 0.5, 179.38, 1.0]
@onready var path : Path2D = $Path2D
@onready var follow : PathFollow2D = $Path2D/PathFollow2D
@onready var tile : Sprite2D = $Path2D/PathFollow2D/Sprite2D
var pos : int:
	set(val):
		pos = val
		follow.position = path.curve.get_point_position(val-1-int(!left_or_right))
func _ready():
	path.curve = path.curve.duplicate(true)
	if left_or_right: #right
		path.curve.remove_point(4)
		pos = 4
	else: #left
		path.curve.remove_point(0)
		pos = 2

@export var map_pos : Vector2i

func _process(delta):
	if holding != null and unit == null:
		follow.position = path.curve.get_closest_point(path.to_local(holding.cursor.global_position))

var holding : Cursor_Container = null
func _cursor_accept(cont:Cursor_Container)->bool:
	if unit != null:
		return false
	holding = cont
	tile.scale = Vector2(1.0,0.75)
	tile.rotation_degrees = -5
	if !cont.accept_released.is_connected(_cursor_release):
		cont.accept_released.connect(_cursor_release)
	return true

func _cursor_release():
	if holding == null:
		return
	if holding.accept_released.is_connected(_cursor_release):
		holding.accept_released.disconnect(_cursor_release)
	holding = null
	tile.scale = Vector2(1.0,1.0)
	tile.rotation_degrees = 0
	var closest : int = 0
	var min_dist : float = 100.0
	for i in path.curve.point_count:
		var pos : Vector2 = path.curve.get_point_position(i)
		var dist : float = path.get_local_mouse_position().distance_to(pos)
		if dist < min_dist:
			closest = i
			min_dist = dist
	pos = closest + 1 + int(!left_or_right)
