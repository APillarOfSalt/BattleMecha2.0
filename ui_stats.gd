extends GridContainer
class_name Unit_UI_Stats

var is_alive : bool = hp > 0
var unit_name : String = ""
func _on_hit()->bool: #false:dead ; true:Still alive
	print(unit_name, ": HP:",hp,",",next_hp,"; SH:",shield,",",next_shield)
	hp = next_hp
	shield = next_shield
	hp_nd.current = hp
	hp_nd._refresh()
	shield_nd.current = shield
	shield_nd._refresh()
	if hp <= 0:
		return false
	return true

func _setup_next_damage(val:int, type:Module_Data.DMG_TYPES)->bool: #true if shield broke
	var has_shield : bool = shield >= 1
	next_hp = hp
	next_shield = shield
	hit_logic[type].call(val)
	if next_shield <= 0 and has_shield:
		return true #shield break
	return false #either still has shield or never had

var next_hp : int = -1
var next_shield : int = -1

var hp : int = 0
@onready var hp_nd = $hp_num
var armor : int = 0
var half_armor : int = ceil(armor * 0.5)
@onready var armor_nd = $armor_num
var shield : int = 0
var shield_regen : int = 0
@onready var shield_nd = $shield_num
func clear():
	hp = 0
	armor = 0
	shield = 0
	shield_regen = 0
	$movement_display.clear()

func setup(unit:Unit_Data):
	hp = unit.hp
	unit_name = unit.name
	armor = unit.armor
	shield = unit.shield_start
	shield_regen = unit.shield_regen
	hp_nd.setup(unit.hp, unit.hp)
	armor_nd.setup(unit.armor, unit.armor)
	shield_nd.setup(unit.shield, unit.shield_start, unit.shield_regen)
	#$movement_display.setup(unit)

var hit_logic : Dictionary = {
	Module_Data.DMG_TYPES.untyped : _on_push_untyped,
	Module_Data.DMG_TYPES.percussive : _on_hit_p,
	Module_Data.DMG_TYPES.voltaic : _on_hit_v,
	Module_Data.DMG_TYPES.concussive : _on_hit_c,
}

func _on_push_untyped(_v:int=0):
	if !next_shield and !armor:
		next_hp -= 1

#1/2dmg to shields;-full armor; full remainder to hp
func _on_hit_p(dmg:int):
	while dmg and next_shield:
		next_shield -= 1
		dmg = max( 0, dmg - 2 )
	dmg = max( 0, dmg - armor )
	next_hp -= dmg

#full damage to shields ;-full armor; 1/2 of remainder to hp
func _on_hit_c(dmg:int):
	var diff : int = next_shield - dmg
	dmg = min( diff , 0 ) #-diff == -dmg remaining
	next_shield = max( 0, diff ) #+diff == +shield remaining
	dmg = min( dmg + armor, 0 )
	while dmg <= -1:
		next_hp -= 1
		dmg += 2

#starts with sheilds: 1/2armor; else: 0
#full dmg to shields ;^armor; 1/2 of remainder to hp 
func _on_hit_v(dmg:int):
	var gets_half : int = half_armor * int( next_shield >= 1 )
	var diff : int = next_shield - dmg
	dmg = min( 0, diff ) #-diff == -dmg remaining
	next_shield = max( 0, diff ) #+diff == +shield remaining
	dmg = min( dmg + gets_half, 0 )
	while dmg <= -1:
		next_hp -= 1
		dmg += 2

