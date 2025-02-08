extends Container


@export_enum("40x40","80x80","120x120") var custom_size_step : int
#4*8=32 +5=37 +3=40
func _ready():
	separation = Vector2(1 + custom_size_step,1 + custom_size_step)
	custom_minimum_size = Vector2(40,40) * separation
	half_cell = Vector2(4,4) * separation
	cell_size = half_cell * 2
	corner_offset = custom_minimum_size - (cell_size*4) - (separation*5)
	#print("Min:",custom_minimum_size)
	#print("Sep:",separation*5)
	#print("Cel:",cell_size*4)
	#print("Cor:",corner_offset)
var separation : Vector2 
var cell_size : Vector2
var half_cell : Vector2
var corner_offset : Vector2

func _on_mod_sel(shp:String):
	data = shp


var data : String = "0000000000000000":
	set(text):
		if data.length() < 16:
			return
		data = text
		dimensions = get_extents(data)
		queue_redraw()
var dimensions : Vector2

func _draw():
	for y in 4:
		for x in 4:
			if data[x+(y*4)].to_int():
				var offset := corner_offset + ( half_cell * ( half_cell - dimensions ) )
				var cell_offset : Vector2 = ( cell_size + Vector2(1,1) ) * Vector2(x,y)
				draw_rect(Rect2(cell_offset+offset, cell_size), Color.WHITE, true)


func get_extents(st:String)->Vector2i:
	var extents := Vector2i(4,4)
	for x in 4:
		var do_break : bool = false
		for i in 4:
			var index : int = (3-x) + (4*i)
			if st[index] == "1":
				do_break = true
		if do_break:
			break
		extents.x -= 1
	for y in 4:
		var do_break : bool = false
		for i in 4:
			var index : int = 15-(y*4)-i
			if st[index] == "1":
				do_break = true
		if do_break:
			break
		extents.y -= 1
	return extents
