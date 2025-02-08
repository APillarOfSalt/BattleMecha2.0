extends MarginContainer

@onready var butt : Button = $butt
@onready var check : CheckBox = $h/CheckBox
@onready var tex : TextureRect = $h/TextureRect
@onready var label : Label = $h/m/Label
@export var type : Global.types = Global.types.Module:
	set(val):
		type = val
		if tex == null:
			return
		tex.texture = Global.type_textures[type]
		label.text = Global.type_strings[type]

var sub_super : bool = true
var disabled : bool = false:
	set(toggle):
		disabled = toggle
		if butt != null:
			butt.disabled = toggle

func _ready():
	butt.disabled = disabled
	tex.texture = Global.type_textures[type]
	label.text = Global.type_strings[type]
	sub_super = type < 10

signal button_pressed(type)
var pressed : bool = false:
	set(toggle):
		if toggle == pressed:
			return
		pressed = toggle
		check.button_pressed = toggle
		butt.mouse_filter = int(toggle) * MOUSE_FILTER_IGNORE
		if pressed:
			button_pressed.emit(type)
func _on_butt_button_down():
	for nd in get_tree().get_nodes_in_group("type_disp"):
		if nd != self and nd.sub_super == sub_super:
			nd.pressed = false
	pressed = true
	
