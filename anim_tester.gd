extends VBoxContainer

@onready var op : OptionButton = $OptionButton
@onready var fx_atk : Unit_Node = $p/center/unit_node
@onready var fx_def : Unit_Node = $p/unit_node

func _ready():
	for anim in fx_atk.ANIMS:
		op.add_item(anim, fx_atk.ANIMS[anim])


func _on_option_button_item_selected(index):
	fx_atk._play( op.get_item_id(index), fx_def.global_position)
	fx_def._play( op.get_item_id(index), fx_atk.global_position)


func _on_p_gui_input(event):
	if !event is InputEventMouseMotion:
		$p/from_loc.position = $p.get_local_mouse_position()


func _on_anims_finished():
	op.selected = 0
