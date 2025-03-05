extends Container
class_name Unit_UI_Stats

signal finished()

var first : bool = false
func _start_turn():
	if !first:
		setup_disp()
		first = true
	else:
		shield_nd.do_regen()

var is_alive : bool:
	get: return hp > 0
var unit_name : String = ""

func _on_hit():
	print(unit_name, ": HP:",hp,"; SH:",shield," @:",Time.get_ticks_msec())
	if shield != shield_nd.set_cur:
		await shield_nd.set_current(shield)
	if hp != hp_nd.set_cur:
		await hp_nd.set_current(hp)
	return null


func _on_push_untyped(_v:int=0):
	if !shield and !armor:
		hp -= 1

const MULTIS : Dictionary = { 		#armor against *,  * vs shield,  *'s vs hp
	#[0] == shield & armor; [1] == no_shield & armor ; [2] == no_shield & no_armor
	#Vector2i(x,y) == ratio:x/y ;e.g. 1/2=0.5,  3/2=1.5
	Module_Data.DMG_TYPES.untyped :
		{"armor":1.0, "shield":Vector2i(0,1), "hp":[Vector2i(0,1),Vector2i(0,1),Vector2i(1,1)]},
	Module_Data.DMG_TYPES.percussive :
		{"armor":1.5, "shield":Vector2i(2,3), "hp":[Vector2i(1,1),Vector2i(3,2),Vector2i(2,1)]},
	Module_Data.DMG_TYPES.concussive :
		{"armor":2.0, "shield":Vector2i(1,1), "hp":[Vector2i(1,1),Vector2i(3,2),Vector2i(2,1)]},
	Module_Data.DMG_TYPES.voltaic :
		{"armor":1.0, "shield":Vector2i(3,2), "hp":[Vector2i(3,2),Vector2i(1,2),Vector2i(1,1)]}
}
func _setup_next_damage(type:int=Module_Data.DMG_TYPES.untyped,val:int=1,ap:bool=false,sp:bool=false)->bool: #true if shield broke
	print("dmg setup on peer:",multiplayer.get_unique_id(),":",unit_name,":",val,":",type)
	if type == Module_Data.DMG_TYPES.healing:
		hp = min(hp+val, hp_max)
		return false
	elif type == Module_Data.DMG_TYPES.shielding:
		var has := bool(shield)
		shield += val
		return !has and val #-shield break(shield back)
	elif type == Module_Data.DMG_TYPES.untyped:
		_on_push_untyped()
		return false
	val *= 2
	var hp_index : int = 2
	if shield:
		hp_index = 0
	elif armor:
		hp_index = 1
	if !sp:
		var re : Vector2i = do_calc( shield*2, val, MULTIS[type].shield )
		shield = ceil(re.x * 0.5)
		val = re.y 
	if !ap:
		val = max(0, val - ceil(armor * MULTIS[type].armor) )
	hp = ceil( do_calc( hp*2, val, MULTIS[type].hp[hp_index] ).x * 0.5)
	if shield <= 0 and hp_index == 0:
		return true #shield break
	return false #either still has shield or never had

func do_calc(current:int, value:int, steps:Vector2i)->Vector2i:
	while current and value:
		for i in steps.x:
			current = max(0, current-1)
		for i in steps.y:
			value = max(0, value-1)
	return Vector2i(current, value)

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






