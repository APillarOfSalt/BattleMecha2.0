extends Container
class_name Unit_UI_Stats

var is_alive : bool:
	get: return hp > 0
var unit_name : String = ""
func _on_hit()->bool: #false:dead ; true:Still alive
	print(unit_name, ": HP:",hp,",",next_hp,"; SH:",shield,",",next_shield)
	hp = next_hp
	shield = next_shield
	await shield_nd.set_current(shield)
	hp_nd.set_current(hp)
	print(unit_name, ": HP:",hp,"; SH:",shield," @:",Time.get_ticks_msec())
	return is_alive

func _setup_next_damage(val:int, type:int)->bool: #true if shield broke
	print("dmg setup on peer:",multiplayer.get_unique_id(),":",unit_name,":",val,":",type)
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
var hp_max : int = 0
@onready var hp_nd = $hp
var armor : int = 0
var half_armor : int = ceil(armor * 0.5)
@onready var armor_nd = $armor
var shield : int = 0
var shield_max : int = 0
var shield_regen : int = 0
@onready var shield_nd = $shield
func clear():
	hp = 0
	armor = 0
	shield = 0
	shield_regen = 0
	hp_nd.clear()
	shield_nd.clear()
	armor_nd.clear()

func setup(unit:Unit_Data):
	hp = unit.hp
	hp_max = unit.hp
	unit_name = unit.name
	shield_max = unit.shield
	shield = unit.shield_start
	shield_regen = unit.shield_regen
	armor = unit.armor
func setup_disp():
	hp_nd.setup(hp)
	await hp_nd.finished
	shield_nd.setup(shield_max, shield, shield_regen)
	await shield_nd.finished
	armor_nd.setup(armor)
func duplicate_from(stats:Unit_UI_Stats):
	hp = stats.hp
	hp_nd.current = hp
	hp_nd.set_cur = hp
	hp_max = stats.hp_max
	hp_nd.max = hp_max
	hp_nd.set_max = hp_max
	shield = stats.shield
	shield_nd.current = shield
	shield_nd.set_cur = shield
	shield_max = stats.shield_max
	shield_nd.max = shield_max
	shield_nd.set_max = shield_max
	shield_regen = stats.shield_regen
	shield_nd.regen = shield_regen
	shield_nd.set_regen = shield_regen
	armor = stats.armor
	armor_nd.set_max = armor
	armor_nd.max = armor
	setup_disp()


var first : bool = false
func _start_turn():
	if !first:
		setup_disp()
		first = true
	else:
		shield_nd.do_regen()


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

