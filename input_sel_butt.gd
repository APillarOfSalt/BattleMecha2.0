extends Container

signal input_selected(device:int)

func _ready():
	Global.cursor_controller.pads_updated.connect(_refresh)
	_refresh()

const pip_true : Texture = preload("res://godot_sucks_ass/option_menu_pip_filled.png")
const pip_false : Texture = preload("res://godot_sucks_ass/option_menu_pip_empty.png")
@onready var pips : Dictionary = {
	SEL.mk: $list/mk/h/sel,
	SEL.m : $list/m/h/sel,
	SEL.k : $list/k/h/sel,
	1 : $list/g1/h/sel,
	2 : $list/g2/h/sel,
	3 : $list/g3/h/sel,
}

enum SEL{mk=-2,m=-1,k=0}
var selected : int = -3: set = sel_setter
func sel_setter(val:int):
	input_selected.emit(val)
	for sel in pips.keys():
		pips[sel].texture = [pip_false,pip_true][int(sel == val)]

@onready var pad_butts : Array = [$list/g1, $list/g2, $list/g3]
func _refresh():
	var num : int = Global.cursor_controller.pad_inputs.keys().size()
	for i in 3:
		var enabled : bool = i < num
		pad_butts[i].modulate = [Color.GRAY, Color.WHITE][int(enabled)]
		pad_butts[i].get_node("butt").disabled = !enabled

func _on_k_pressed():
	selected = 0
func _on_m_pressed():
	selected = -1
func _on_mk_pressed():
	selected = -2
func _on_g_1_pressed():
	selected = 1
func _on_g_2_pressed():
	selected = 2
func _on_g_3_pressed():
	selected = 3
