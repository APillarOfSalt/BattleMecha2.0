extends Node2D

class_name Cursor_Modules

@export var anchor : Node2D

@onready var cursor = get_parent()

var current_mod : Module_Data = null:
	set(mod):
		current_mod = mod
		mod_nd.module = mod
		mod_blocks.module = mod

@onready var mod_nd : Container = $module
@onready var mod_blocks : Module_Blocks = $blocks
enum PLACEMENT { invalid = 0, bounds = 1, valid = 2 }
var valid_placement : int = PLACEMENT.invalid: set = set_valid_placement
func set_valid_placement(val: int) -> void:
	if val == valid_placement:
		return
	if block_backdrop == null:
		valid_placement = PLACEMENT.invalid
		return
	valid_placement = val
	var v : float = [0.0, 0.125, 1.0/3.0][ val ]
	mod_blocks.border_color = Color.from_hsv(v,0.8,0.8,1.0)

@export var block_backdrop : Module_Backdrop
var hovering_backdrop : bool = false:
	set(toggle):
		mod_nd.visible = !toggle and current_mod != null
		mod_blocks.visible = toggle and current_mod != null
var backdrop_pos : Vector2i = Vector2i(-1,-1):
	set(vec):
		backdrop_pos = vec
		valid_placement = PLACEMENT.invalid
		var glo_pos : Vector2 = Vector2(0,0)
		if block_backdrop != null:
			block_backdrop.hover_at(vec)
			if check_valid_placement(block_backdrop.DIM, vec) != Vector2i(-1,-1):
				valid_placement = PLACEMENT.bounds
				var trans_shape : String = Global.translate_binary_string_bitwise(mod_blocks.shape, vec, true)
				if "Error" == trans_shape:
					valid_placement = PLACEMENT.invalid
				elif block_backdrop.get_combined(trans_shape):
					valid_placement = PLACEMENT.valid
			glo_pos = block_backdrop.vec_to_global(vec)
		mod_blocks.visible = vec != Vector2i(-1,-1)
		hovering_backdrop = vec != Vector2i(-1,-1)
		mod_blocks.global_position = glo_pos
func _process(_delta):
	if block_backdrop != null:
		backdrop_pos = block_backdrop.global_to_vec(global_position)
	elif backdrop_pos != Vector2i(-1,-1):
		backdrop_pos = Vector2i(-1,-1)

func _clamped(v:Vector2i, dim:Vector2i)->Vector2i:
	return v.clamp(Vector2i(0,0), dim)
func check_valid_placement(dim:Vector2i, vec:Vector2i, force:bool=false)->Vector2i:
	var min_dim : Vector2i = _clamped(vec, dim)
	if vec != min_dim:#too far negative, as long as all modules are normalized (AND THEY SHOULD BE) this should be the only check necessary
		if !force:
			return Vector2i(-1,-1)
	var max_dim : Vector2i = mod_blocks.get_extents() + min_dim
	var dim_diff : Vector2i = max_dim - _clamped(max_dim, dim)
	if !force and dim_diff != Vector2i(0,0): #too far positive
		return Vector2i(-1,-1)
	min_dim -= dim_diff #if !force and dim_diff == (0,0) then min_dim wont change and still be == to clamped(vec)
	if min_dim != _clamped(min_dim, dim): #if still out of bounds
		return Vector2i(-1,-1)
	return min_dim

func do_placement():
	if valid_placement != PLACEMENT.valid:
		print("fail1")
		return
	if block_backdrop == null:
		print("fail2")
		return
	if !mod_blocks.visible:
		print("fail3")
		return
	if backdrop_pos != _clamped(backdrop_pos, block_backdrop.DIM):
		print("fail4")
		return
	if current_mod == null:
		#print("fail5")
		return
	var success : bool = block_backdrop.add_module(current_mod._duplicate(), backdrop_pos)
	if success:
		grab_module(null)
	else:
		print("fail0")


func grab_module(mod:Module_Data):
	current_mod = mod
	if mod == null:
		anchor.show()
		mod_nd.hide()
		mod_blocks.hide()
	else:
		anchor.hide()
		mod_nd.show()

func _on_c_hover_refreshed():
	if current_mod != null:
		mod_nd.show()
		mod_blocks.hide()
		for nd in cursor.hovering:
			if nd is Module_Backdrop:
				block_backdrop = nd
				return
		block_backdrop = null
func _on_disp_accept_pressed():
	if valid_placement == PLACEMENT.valid:
		do_placement()
func _on_disp_cancel_pressed():
	if current_mod != null:
		grab_module(null)
