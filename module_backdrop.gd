extends GridContainer

class_name Module_Backdrop

signal refresh_movement(move_arr:Array)
func mod_change(mod:Module_Data):
	if mod.type != "Weapon" and mod.hex_shape.size():
		regather_movement()
func regather_movement():
	var movement : Array = []
	for blocks in modules:
		if blocks.module.type != "Weapon" and blocks.module.hex_shape.size():
			movement.append_array(blocks.module.hex_shape)
	refresh_movement.emit(movement)

var is_dev : bool = false

@onready var style : StyleBox = preload("res://styles/moduleStylebox.tres")
@onready var cell_size : Vector2 = get_child(0).size
@onready var anchor : Node2D = $anchor

var unit : Unit_Data:
	set(data):
		shape = "00000000000000000000"
		unit = data
		for m in modules:
			if m != null:
				m.name = "oh_no"
				m.free()
		modules.clear()
		if data != null:
			for arr in data.set_modules:
				var pos : Vector2i = arr[0]
				var mod : Module_Data = arr[1]
				add_module( mod, pos, true, true)
			for arr in data.modules:
				var pos : Vector2i = arr[0]
				var mod : Module_Data = arr[1]
				add_module( mod, pos, false, true)
		regather_movement()
		refresh()

func clear():
	popped_mod = null
	popped_pos = Vector2i(-1,-1)
	unit = null

var popped_mod : Module_Data = null
var popped_pos := Vector2i(-1,-1)
func _pop_mod(pos:Vector2i, to=null):
	if popped_mod != null:
		return false
	var mod : Module_Blocks = get_module_at(pos)
	popped_mod = mod.module
	popped_pos = mod.backdrop_pos
	#var mod_index : int = mod.backdrop_index
	#shape = Global.get_shape_without(shape, str(mod_index) )
	if to is Cursor_Modules:
		to.grab_module(mod.module)
	while mod in modules:
		modules.remove_at(modules.find(mod))
	mod_change(mod.module)
	mod.free()
	refresh()
	return true
func _unpop(pos:Vector2i=popped_pos)->bool:
	if popped_mod == null:
		return false
	var trans_shape : String = Global.translate_binary_string_bitwise(popped_mod.shape, pos, true)
	if trans_shape == "Error":
		return false
	if !get_combined(trans_shape):
		return false
	if add_module(popped_mod, pos):
		popped_mod = null
		popped_pos = Vector2i(-1,-1)
		return true
	return false

func _cursor_accept(cont:Cursor_Container)->bool:
	var manager : Cursor_Modules = cont.mod_manager
	refresh.call_deferred()
	if manager.current_mod != null:
		return false
	var pos : Vector2i = global_to_vec(manager.global_position)
	if pos == Vector2i(-1,-1):
		return false
	var mod : Module_Blocks = get_module_at(pos)
	if popped_mod != null:
		if !_unpop(pos):
			return false
	if mod == null:
		return false
	elif mod.lock_module:
		return false
	_pop_mod(pos, manager)
	if popped_mod == null:
		if cont.cancel_pressed.is_connected(_cursor_cancel):
			cont.cancel_pressed.disconnect(_cursor_cancel)
	elif !cont.cancel_pressed.is_connected(_cursor_cancel):
		cont.cancel_pressed.connect(_cursor_cancel)
	return true

func _cursor_cancel(cont:Cursor_Container=null)->bool:
	if popped_mod != null:
		if !_unpop():
			return false
	elif cont != null:
		var vec : Vector2i = global_to_vec(cont.cursor.global_position)
		var mod = get_module_at( vec )
		if mod:
			if Input.is_action_pressed("shift") and is_dev:
				mod.lock_module = !mod.lock_module
			elif !mod.lock_module:
				while mod in modules:
					modules.remove_at(modules.find(mod))
				mod_change(mod.module)
				mod.free()
				refresh()
			return true
	else:
		return false
	return true

func _get_input_rect(glo_pos:Vector2)->Rect2:
	var pos : Vector2 = vec_to_global(global_to_vec(glo_pos))
	return Rect2(pos, cell_size)

func hover_at(pos:=Vector2i(-1,-1)):
	if pos == Vector2i(-1,-1):
		for i in get_tree().get_nodes_in_group("mod_blocks"):
			i.hovering = false
		return
	var mod = get_module_at(pos)
	if mod != null:
		mod.hovering = true

var modules : Array
func add_module(mod:Module_Data, offset:Vector2i, lock:bool=false, skip_refresh:bool=false)->bool:
	if popped_mod != null:
		if popped_mod.id == mod.id:
			popped_mod = null
			popped_pos = Vector2i(-1,-1)
	var translated : String = Global.translate_binary_string_bitwise(mod.shape, offset, true)
	if translated == "Error":
		return false
	if !get_combined(translated):
		return false
	var mod_block : Module_Blocks = mod_block_scene.instantiate()
	modules.append(mod_block)
	mod_block.backdrop_index = modules.size()
	mod_block.backdrop_pos = offset
	mod_block.name = str(modules.size(),":",offset)
	mod_block.do_reposition = false
	anchor.add_child(mod_block)
	mod_block.lock_module = lock
	mod_block.position = Vector2(offset) * cell_size
	mod_block.module = mod
	#for i in 4:
		#print(shape.substr(i*4,4),"|",translated.substr(i*4,4))
	#shape = new_shape
	if !skip_refresh:
		mod_change(mod)
		refresh()
	return true

const DIM := Vector2(4,5)

const mod_block_scene : PackedScene = preload("res://module_blocks.tscn")

					# 1_-_2_-_3_-_4_-_5_-_
var shape : String = "00000000000000000000":
	get:
		shape = "00000000000000000000"
		for mod in modules:
			var shp : String = Global.translate_binary_string_bitwise(mod.shape, mod.backdrop_pos, true)
			for i in 20:
				if shp[i].to_int():
					if shape[i] == "1":
						print("overlap")
					shape[i] = "1"
		return shape

func get_total_indexed(shp:String)->int:
	var mx : int = 0
	for i in shp:
		mx = max(i.to_int(), mx)
	return mx

func get_combined(shp:String):
	#var index : int = get_total_indexed(shape) + 1
	if shp.length() < 20:
		return
	while shp.length() < 20:
		shp = shp + "0"
	var current_shape : String = shape
	for i in 20:
		if shp[i] != "0" and current_shape[i] != "0":
			return false
	return true

func refresh():
	for i in 20:
		get_node( str(i,"/tex") ).visible = not bool( shape[i].to_int() )
	var hp : int = 0
	var armor : int = 0
	var s_cap : int = 0
	var s_start : int = 0
	var s_regen : int = 0
	var movement : Array = []
	for blocks:Module_Blocks in modules:
		match blocks.module.id:
			1: #hull upgrade MK.I
				hp += 2
				continue
			2: #hull upgrade MK.II
				hp += 3
				continue
			3: #armor upgrade
				armor += 1
				continue
		if blocks.module is Module_Data.Shield_Data:
			s_cap += blocks.module.cap
			s_start += blocks.module.start
			s_regen += blocks.module.regen
		if blocks.module.type != "Module":
			continue
		movement.append_array(blocks.module.hex_shape)
	if !is_inside_tree():
		await ready
	$"../unit_props/v/stats".hp = hp
	$"../unit_props/v/stats".armor = armor
	$"../unit_props/v/stats".s_cap = s_cap
	$"../unit_props/v/stats".s_start = s_start
	$"../unit_props/v/stats".s_regen = s_regen

const textures : Array[Texture] = [
	preload("res://assets/processor.png"), #2
	preload("res://assets/shotgun.png"), #1
	preload("res://assets/grenade.png"), #3
	preload("res://assets/rifle.png"), #4
	preload("res://assets/laser-gun.png"), #5
	null, #6
	null, #7
	preload("res://assets/armor-upgrade.png"), #8
	preload("res://assets/shoulder-armor.png"), #9
	]

func global_to_vec(glo_pos:Vector2)->Vector2i:
	var loc : Vector2 = anchor.to_local(glo_pos)
	if loc.x < 0 or loc.y < 0 or loc.x > size.x or loc.y > size.y:
		return Vector2i(-1,-1)
	return Vector2i( ( (loc / size) * DIM ).floor() )
func vec_to_global(vec:Vector2)->Vector2:
	vec /= DIM
	vec *= size
	return anchor.global_position + vec

#func _ready():
	#unit = DataLoader.units_by_id[0]

func index_from(i_p)->int:
	if i_p is int:
		return i_p
	elif i_p is Vector2i:
		return i_p.x + ( i_p.y * 4 )
	return -1

func get_module_at(pos:Vector2i)->Module_Blocks:
	if pos.x < 0 or pos.y < 0 or pos.x > 3 or pos.y > 4:
		return null
	for mod in modules:
		var shp : String = Global.translate_binary_string_bitwise(mod.shape, mod.backdrop_pos, true)
		if shp[pos.x+(pos.y*4)] != "0":
			return mod
	return null
