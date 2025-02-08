extends GridContainer

var hp : int = 0
var hp_arg : int = 0
@onready var hp_nd = $hp_num
var armor : int = 0
var armor_arg : int = 0
@onready var armor_nd = $armor_num
var shield : int = 0
var shield_regen : int = 0
@onready var shield_nd = $shield_num
func clear():
	hp = 0
	hp_arg = 0
	armor = 0
	armor_arg = 0
	shield = 0
	shield_regen = 0
	$movement_display.clear()

func setup(unit:Unit_Data):
	hp = unit.hp
	armor = unit.armor
	shield = unit.shield_start
	shield_regen = unit.shield_regen
	hp_nd.setup(unit.hp, unit.hp)
	armor_nd.setup(unit.armor, unit.armor)
	shield_nd.setup(unit.shield, unit.shield_start, unit.shield_regen)
	
	#$movement_display.setup(unit)
