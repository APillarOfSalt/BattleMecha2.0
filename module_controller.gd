extends Node2D

class_name Module_Controller

@export var mod_disp : Container
@export var mod_blocks : Module_Blocks

func _on_mod_sel(disp):
	if disp == null:
		module = null
		mod_disp.hide()
	else:
		module = disp.module
		mod_disp.global_position = disp.global_position
		mod_disp.show()
var module : Module_Data:
	set(mod):
		module = mod
		mod_blocks.visible = mod is Module_Data
		if mod != null:
			mod_disp.module = mod
			mod_blocks.module = mod


