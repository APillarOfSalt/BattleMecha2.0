extends Node2D
class_name Objective_Controller

const weight : bool = false #false == clockwise, true == counterclockwise
const dirs : Array = ["mm","ml","mr","lr"]

const tiles : Dictionary = {
	"mm0" : Vector2i(4,3),
	"ml1" : Vector2i(3,3),
	"ml2" : Vector2i(2,4),
	"mr1" : Vector2i(5,3),
	"mr2" : Vector2i(6,4),
	"lr1" : Vector2i(4,2),
	"lr2" : Vector2i(4,1),
}
var tile_contents : Dictionary = {
	"mm0" : null,
	"ml1" : null,
	"ml2" : null,
	"mr1" : null,
	"mr2" : null,
	"lr1" : null,
	"lr2" : null,
}

func advance_dir(dir:String):
	var next : String = "mm0"
	for i in 2:
		var tile : String = str(dir,i+1)
		var contents = tile_contents[tile]
		var next_cotents = tile_contents[next]
		if contents != null and next_cotents != null:
			next_cotents.merge(contents)
		elif contents != null:
			contents.map_pos = tiles[next]
			tile_contents[next] = contents
			tile_contents[tile] = null
		next = str(dir,1)

var flippers : Array = [false,false,false]


#		dir:	0	1
#0local 0cw:	ml	mr
#0local 1ccw:	mr	ml
#1left 0cw: 	lr	ml
#1left 1ccw:	ml	lr
#2right 0cw:	mr	lr
#2right 1ccw:	lr	mr
func get_dir_from(from:int,dir:bool)->String:
	var toggle := int(weight != dir)
	return [ ["ml","mr"], ["lr","ml"], ["mr","lr"] ][ from ][ toggle ]

func find_next_local(from:int)->String:
	for i in 2:
		for d in 2:
			var tile : String = str(get_dir_from(from, d) , 2-i)
			if tile_contents[tile] == null:
				return tile
	return ""

#from : 0 local, 1:left, 2:right
func add_rolled_unit(unit:Unit_Node, from:int):
	var tile : String = find_next_local(from)
	if tile == "":
		var dir : String = get_dir_from(from, flippers[from])
		advance_dir(dir)
		flippers[from] = !flippers[from]
		return add_rolled_unit(unit, from)
	unit.reparent(self)
	tile_contents[tile] = unit
	unit.map_pos = tiles[tile]
	unit.position += unit.to_pos
