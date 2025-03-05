extends HBoxContainer

const mod_scene : PackedScene = preload("res://unit_loadout_one_module.tscn")
const wep_scene : PackedScene = preload("res://unit_loadout_one_weapon.tscn")
const shield_scene : PackedScene = preload("res://unit_loadout_one_shield.tscn")
@onready var wep_cont : Container = $weps
@onready var shield_cont : Container = $shields
@onready var mod_cont : Container = $mods
var weapons : Array = []
var shields : Array = []
var modules : Array = []
func clear():
	for arr in [weapons,shields,modules]:
		for nd in arr:
			nd.queue_free()
		arr.clear()
func setup(data:Unit_Data):
	clear()
	for arr in [data.set_modules, data.modules]:
		for mods in arr: #arr == [ [pos:Vector2i,mod:Module_Data], [etc...] ]
			var mod : Module_Data = mods[1]
			if mod is Module_Data.Weapon_Data:
				setup_weapon(mod)
			elif mod is Module_Data.Shield_Data:
				setup_shield(mod)
			else:
				setup_module(mod)
func setup_weapon(mod:Module_Data.Weapon_Data):
	var wep = wep_scene.instantiate()
	wep_cont.add_child(wep)
	weapons.append(wep)
	wep.weapon = mod
func setup_shield(mod:Module_Data.Shield_Data):
	var shield = shield_scene.instantiate()
	shield_cont.add_child(shield)
	shields.append(shield)
	shield.shield = mod
func setup_module(mod:Module_Data):
	var module = mod_scene.instantiate()
	mod_cont.add_child(module)
	modules.append(module)
	module.module = mod





