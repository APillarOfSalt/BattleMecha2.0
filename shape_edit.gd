extends Container

@onready var area_l : Label = $h/p/m/area

signal shape_changed()

var shape : String
func load_shape(new_shape:String):
	shape = new_shape
	for i in 16:
		skip_toggle = true
		get_node(str("g/",i)).button_pressed = new_shape[i] == "1"
	skip_toggle = false
	shape_changed.emit()

func get_updated_shape()->String:
	var text : String = ""
	for i in 16:
		text += str(int(get_node(str("g/",i)).button_pressed))
	return text

var skip_toggle : bool = false
func _on_toggle(index:int, toggled_on:bool):
	if skip_toggle:
		skip_toggle = false
		return
	var found : Vector4 = check_button_neighbors(index, get_check_dirs(index))
	if toggled_on and "1" in shape: #(⮧ except the first one)
		if found.length() == 0.0: #ensure the bit thats flipped isnt alone
			skip_toggle = false
			get_node( str("g/",index) ).button_pressed = false
			return
	elif shape.count("1") > 1: #(⮧ except the last one)
		#check to make sure turning off this bit doesnt break the connectivity
		if check_broken_connectivity( get_updated_shape() ):
			skip_toggle = false
			get_node( str("g/",index) ).button_pressed = true
			return
	shape = get_updated_shape()
	shape_changed.emit()
	area_l.text = str("Size : ", shape.count("1"))

func get_check_dirs(index:int)->Vector4:
	var check := Vector4(1,1,1,1)
	if index <= 3: #top
		check.x = 0
	elif index >= 12: #bottom
		check.z = 0
	if (index % 4) == 3: #right
		check.y = 0
	elif (index % 4) == 0: #left
		check.w = 0
	return check
func check_button_neighbors(index:int, check:Vector4)->Vector4:
	var found := Vector4(0,0,0,0)
	if check.x: #up
		found.x = int( get_node(str("g/",index-4)).button_pressed )
	if check.y: #right
		found.y = int( get_node(str("g/",index+1)).button_pressed )
	if check.z: #bottom
		found.z = int( get_node(str("g/",index+4)).button_pressed )
	if check.w: #left
		found.w = int( get_node(str("g/",index-1)).button_pressed )
	return found
func check_broken_connectivity(new_shape:String)->bool: #false:OK, true:connectivity broken
	var first1 : int = new_shape.find("1")
	if first1 == -1:
		return OK
	var visited : Dictionary = {}
	for i in 16:
		visited[i] = false
	visited = flood_fill(first1, new_shape, visited)
	var visit_count : int = 0
	for i in 16:
		visit_count += int( visited[i] )
	return visit_count < new_shape.count("1")

func flood_fill(start:int, temp_shape:String, visited:Dictionary):
	var stack : Array = [start]
	while stack.size():
		var current : int = stack.pop_back()
		if visited[current]:
			continue
		visited[current] = true
		for neighbor in get_neighbors(current):
			if temp_shape[neighbor] == "1" and !visited[neighbor]:
				stack.append(neighbor)
	return visited

func get_neighbors(index:int):
	var neighbors = []
	if index >= 4:  # Up
		neighbors.append(index - 4)
	if index % 4 < 3:  # Right
		neighbors.append(index + 1)
	if index < 12:  # Down
		neighbors.append(index + 4)
	if index % 4 > 0:  # Left
		neighbors.append(index - 1)
	return neighbors


func _on_0_toggled(toggled_on:bool):
	_on_toggle(0, toggled_on)
func _on_1_toggled(toggled_on:bool):
	_on_toggle(1, toggled_on)
func _on_2_toggled(toggled_on:bool):
	_on_toggle(2, toggled_on)
func _on_3_toggled(toggled_on:bool):
	_on_toggle(3, toggled_on)
func _on_4_toggled(toggled_on:bool):
	_on_toggle(4, toggled_on)
func _on_5_toggled(toggled_on:bool):
	_on_toggle(5, toggled_on)
func _on_6_toggled(toggled_on:bool):
	_on_toggle(6, toggled_on)
func _on_7_toggled(toggled_on:bool):
	_on_toggle(7, toggled_on)
func _on_8_toggled(toggled_on:bool):
	_on_toggle(8, toggled_on)
func _on_9_toggled(toggled_on:bool):
	_on_toggle(9, toggled_on)
func _on_10_toggled(toggled_on:bool):
	_on_toggle(10, toggled_on)
func _on_11_toggled(toggled_on:bool):
	_on_toggle(11, toggled_on)
func _on_12_toggled(toggled_on:bool):
	_on_toggle(12, toggled_on)
func _on_13_toggled(toggled_on:bool):
	_on_toggle(13, toggled_on)
func _on_14_toggled(toggled_on:bool):
	_on_toggle(14, toggled_on)
func _on_15_toggled(toggled_on:bool):
	_on_toggle(15, toggled_on)


func _on_normalize_pressed():
	if !"1" in shape:
		return
	while !"1" in shape.substr(0,4):
		shape = Global.translate_binary_string_bitwise(shape, Vector2i(0,-1))
	while !"1" in str(shape[0],shape[4],shape[8],shape[12]):
		shape = Global.translate_binary_string_bitwise(shape, Vector2i(-1,0))
	load_shape( shape )
	

