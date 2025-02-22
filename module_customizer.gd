extends Container

@onready var op_sel : OptionButton = $title/sizing/sel_op
func _ready():
	refresh_from_dataloader()
	module = null
func refresh_from_dataloader():
	op_sel.clear()
	var keys : Array = DataLoader.modules_by_id.keys().duplicate(true)
	keys.sort()
	for mod_id in keys:
		var mod : Module_Data = DataLoader.modules_by_id[mod_id]
		op_sel.add_item(str(mod_id," : ",mod.name), mod_id)
		var tex : Texture = Global.type_textures[ Global.type_from_str(mod.type) ]
		op_sel.get_popup().set_item_icon(op_sel.item_count-1, tex)
		op_sel.get_popup().set_item_indent(op_sel.item_count-1, 0)

const mod_tex : Texture = preload("res://assets/processor.png")
const shl_tex : Texture = preload("res://assets/armor-upgrade.png")
const wep_tex : Texture = preload("res://assets/shotgun.png")
const arm_tex : Texture = preload("res://assets/shoulder-armor.png")
const hul_tex : Texture = preload("res://assets/hp.png")

var id : int = 0:
	set(val):
		id = val
		refresh()
const EDIT_STR : String = "ID : "
var named : String = "":
	set(text):
		named = text
		refresh()
@onready var shape_editor : Container = $h/l/shape_edit
var subtype : String
func _on_sub_type_selected(type):
	if type == -1:
		return
	subtype = Global.type_strings[type]

var shape : String = "0000000000000000":
	set(text):
		shape_editor.load_shape(text)
	get:
		return shape_editor.shape

@onready var title_l : Label = $title/sizing/Label
func refresh():
	title_l.text = str(named," - ",EDIT_STR,id)
	shield_props.visible = mode == MODES.shl
	weapon_props.visible = mode == MODES.wep

@onready var move_atk = $h/r/move_atk
var hex_shape : Array[Vector2i]:
	get: return move_atk.get_data()

var module : Module_Data = null:
	set(mod):
		module = mod
		super_butt.disabled = mod != null
		save_butt.icon = save_icon_old
		if mod == null:
			sub_butt.disabled = false
			save_butt.icon = save_icon_new
			id = -1
			named = ""
			name_edit.text = ""
			shape = "0000000000000000"
			mode = MODES.mod
			if op_sel != null:
				op_sel.selected = -1
			refresh_save_butt()
			return
		var is_weapon : bool = mod.type == "Weapon"
		if mod.type == "Shield":
			mode = MODES.shl
		elif is_weapon:
			mode = MODES.wep
		else:
			mode = MODES.mod
		move_atk.mode = is_weapon
		move_atk.visible = mod.type != "Shield"
		move_atk.push_dir = -1
		if is_weapon:
			move_atk.push_dir = mod.push
		move_atk.tiles = mod.hex_shape
		subtype = mod.subtype
		var sub : int = Global.type_from_str(subtype)
		sub_butt.selected_type = sub
		sub_butt.disabled = sub > -1
		shield_props.setup(mod)
		weapon_props.setup(mod)
		id = mod.id
		named = mod.name
		name_edit.text = named
		shape = mod.shape
		refresh_save_butt()
@onready var shield_props : Container = $h/r/shield
@onready var weapon_props : Container = $h/r/weapon

func get_current_mod()->Module_Data:
	var data : Dictionary = {
		"id" : id,
		"name" : named,
		"subtype" : subtype,
		"size" : shape.count("1"),
		"shape" : shape,
		"hex_shape" : hex_shape,
	}
	if mode == MODES.shl:
		data.type = "Shield"
		data.merge( shield_props.get_dict() )
		return Module_Data.Shield_Data.new(data)
	elif mode == MODES.wep:
		data.type = "Weapon"
		data.merge( weapon_props.get_dict() )
		return Module_Data.Weapon_Data.new(data)
	#elif mode == MODES.mod:
	data.type = "Module"
	return Module_Data.new(data)

func _on_super_type_selected(type):
	if type == -1:
		return
	mode = type

enum MODES{mod=1,shl=2,wep=3}
var mode : int = MODES.mod:
	set(val):
		mode = val
		super_butt.selected_type = mode
		if module == null:
			id = DataLoader.get_next_mod_id(mode, shape.count("1"))
		refresh()

@onready var super_butt : Container = $h/l/h/super
@onready var sub_butt : Container = $h/l/h/sub
@onready var name_edit : LineEdit = $h/r/name

func _on_name_text_changed(new_text):
	named = new_text
	refresh_save_butt()

func _on_sel_op_item_selected(index):
	module = DataLoader.modules_by_id[ op_sel.get_item_id(index) ]

func _on_new_pressed():
	module = null
func _on_save_pressed():
	shape_editor._on_normalize_pressed()
	var mod : Module_Data = get_current_mod()
	print( DataLoader.save_module(mod, true) )
	refresh_from_dataloader()
	for i in op_sel.item_count:
		if op_sel.get_item_id(i) == mod.id:
			op_sel.selected = i
			break
			#_on_option_button_item_selected(i)
@onready var save_butt : Button = $title/m/anchor/title/save
var save_icon_new : Texture = preload("res://assets/new.png")
var save_icon_old : Texture = preload("res://assets/sav.png")
func refresh_save_butt():
	if !"1" in shape:
		save_butt.disabled = true
		return
	elif named == "":
		save_butt.disabled = true
		return
	elif module == null:
		for mod in DataLoader.modules_by_id.values():
			if mod.name == named:
				save_butt.disabled = true
				return
	save_butt.disabled = false

func _on_shape_edit_shape_changed():
	refresh_save_butt()
	if module == null:
		id = DataLoader.get_next_mod_id(mode, shape.count("1"))


func _on_batch_save_pressed():
	DataLoader.modules_to_memory()


