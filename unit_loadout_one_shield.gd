extends PanelContainer

var shield : Module_Data.Shield_Data = null: set = shield_setter
@onready var name_l : Label = $content/title/m/Label
@onready var subtype_l : Label = $content/subtype/p/m/Label
@onready var max_l : Label = $content/stats/max/m/h/Label
@onready var start_l : Label = $content/stats/start/m/h/Label
@onready var regen_l : Label = $content/stats/regen/m/h/Label
func shield_setter(mod:Module_Data.Shield_Data):
	shield = mod
	name_l.text = mod.name
	subtype_l.text = mod.subtype
	max_l.text = str(mod.cap)
	start_l.text = str(mod.start)
	regen_l.text = str(mod.regen)
