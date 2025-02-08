extends ScrollContainer

const mod_disp_scene : PackedScene = preload("res://module_display.tscn")

@export_enum("Modules","Shields","Weapons") var type : int = 0
func _ready():
	var dict : Dictionary
	if type == 1:
		dict = DataLoader.shields_by_id
	elif type == 2:
		dict = DataLoader.weapons_by_id
	else:
		dict = DataLoader.abilites_by_id
	var keys : Array = dict.keys().duplicate(true)
	keys.sort()
	for id in keys:
		var mod = dict[id]
		var disp : Container = mod_disp_scene.instantiate()
		disp.module = mod
		$v.add_child(disp)
		all_mods.append(disp)

func _on_mod_sel(disp:Container):
	if disp == null:
		return
	disp.module

var all_mods : Array

