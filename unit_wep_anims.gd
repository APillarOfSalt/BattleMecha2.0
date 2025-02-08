extends Node2D

@export var projectile_time_msec : int = 500

func animate_atk(wep:Module_Data.Weapon_Data, defense:Array[Unit_Node]):
	if wep.subtype == "Laser" or wep.subtype == "Coil" or wep.subtype == "Melee": #only do 1 animation
		pass
	else: #do an anim for all of the defenders #Rifle, Cannon, Launcher
		for unit in defense:
			unit.animate_defend(wep, get_parent())
	await get_tree().create_timer(projectile_time_msec * 0.001).timeout
	get_parent().attack_anim_complete.emit()
func animate_defend(wep:Module_Data.Weapon_Data, attacker:Unit_Node):
	var dmg_type : Module_Data.DMG_TYPES = -2
	if wep.subtype == "Melee":
		dmg_type = -1
	elif wep.subtype == "Rifle":
		dmg_type = Module_Data.DMG_TYPES.percussive
	elif wep.subtype == "Laser" or wep.subtype == "Coil":
		dmg_type = Module_Data.DMG_TYPES.voltaic
	elif wep.subtype == "Cannon" or wep.subtype == "Launcher":
		dmg_type = Module_Data.DMG_TYPES.concussive
	var shield_break: bool = _on_hit(0, dmg_type)
	var still_has : bool = shield < 0
	var arg : int = int(still_has) - int(shield_break) #-1:shield_break, 0:hit, +1:shield_hit
	$defense_anim.setup(dmg_type, arg)
	var dead : bool = hp <= 0

var hp : int
var shield : int
var armor : int:
	get: return get_parent().armor

func _on_hit(dmg:int, type:Module_Data.DMG_TYPES)->bool: #true if shield broke
	hp = get_parent().hp
	shield = get_parent().shield
	var has_shield : bool = shield > 0
	match type:
		Module_Data.DMG_TYPES.percussive:
			_on_hit_p(dmg)
		Module_Data.DMG_TYPES.voltaic:
			_on_hit_v(dmg)
		Module_Data.DMG_TYPES.concussive:
			_on_hit_c(dmg)
	if has_shield and shield <= 0:
		return true
	return false

func _on_hit_p(dmg:int):
	var half : int = floor(dmg * 0.5)
	if half >= shield: #if 1/2 damage puts shield to 0
		hp -= max(0, dmg - (half - shield) - armor) #deal the full rest to hp (full armor)
	shield = max(0, shield - half) #1/2 dmg to shield
func _on_hit_v(dmg:int):
	hp -= max(0, dmg - shield - floor(armor * 0.5) ) #deal full rest to hp ( 1/2 armor )
	shield = max(0, shield - dmg) #full dmg to shield
func _on_hit_c(dmg:int):
	hp -= max(0, dmg - shield - floor(armor * 0.5) ) #deal full rest to hp ( 1/2 armor )
	shield = max(0, shield - floor(dmg * 0.5) ) #1/2 dmg to shield
