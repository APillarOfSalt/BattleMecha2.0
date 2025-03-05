extends PanelContainer

var module : Module_Data = null: set = mod_setter
@onready var name_l : Label = $content/title/m/Label
func mod_setter(mod:Module_Data):
	module = mod
	name_l.text = mod.name
