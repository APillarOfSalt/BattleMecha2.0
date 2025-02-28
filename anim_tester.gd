extends VBoxContainer

@onready var op : OptionButton = $OptionButton
@onready var atk_unit : Unit_Node = $p/center/atk
@onready var def_unit : Unit_Node = $p/def
@onready var fx_atk : Offensive_Animation_Controller = atk_unit.atk_anim_ctrl
@onready var fx_def : Defensive_Animation_Controller = def_unit.def_anim_ctrl

func _ready():
	for i in 2:
		var id : int = randi_range(0,19)
		[atk_unit, def_unit][i].unit_data = DataLoader.units_by_id[id]
	for wep in DataLoader.weapons_by_id.values():
		op.add_item(wep.name, wep.id)

var weapon : Module_Data.Weapon_Data
func _on_option_button_item_selected(index):
	weapon = DataLoader.weapons_by_id[ op.get_item_id(index) ]
	$queue.debug_create_attack(atk_unit, weapon, def_unit)

func _on_button_pressed():
	$queue._play()
func _on_p_gui_input(event):
	if !event is InputEventMouseMotion:
		var glo_pos : Vector2 = $p.get_global_mouse_position()
		def_unit.global_position = glo_pos
	

func _on_anims_finished():
	op.selected = 0

func _on_def_is_now_dead(node:Unit_Node, death_sale:bool):
	print("DEATH:",death_sale)
	if !death_sale:
		def_unit.queue_free()


