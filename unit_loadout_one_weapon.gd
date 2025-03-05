extends Container

var weapon : Module_Data.Weapon_Data = null: set = wep_setter
func wep_setter(wep:Module_Data.Weapon_Data):
	weapon = wep
	name_l.text = wep.name
	prio_l.text = str(wep.priority)
	subtype_l.text = wep.subtype
	dmg_l.text = str(wep.size)
	var type : Module_Data.DMG_TYPES = wep.get_dmg_type()
	dmg_rects.p.visible = type == Module_Data.DMG_TYPES.percussive
	dmg_rects.v.visible = type == Module_Data.DMG_TYPES.voltaic
	dmg_rects.c.visible = type == Module_Data.DMG_TYPES.concussive
	var cols : Array[Color] = [Color.DIM_GRAY, Color.WHITE]
	ap_l.modulate = cols[int("ap" in wep.abilities)]
	sp_l.modulate = cols[int("sp" in wep.abilities)]
	ref_l.modulate = cols[int("ref" in wep.abilities)]
	heal_l.modulate = cols[int("heal" in wep.abilities)]
	push_l.modulate = cols[int(wep.push > -1)]
	push_l.text = "Push"
	push_l.text += [""," 🡑"," 🡕"," 🡖"," 🡓"," 🡗"," 🡔"][wep.push+1]
@onready var name_l : Label = $content/title/m/Label
@onready var prio_l : Label = $content/subtitle/prio/m/h/Label
@onready var subtype_l : Label = $content/subtitle/subtype/p/m/Label
@onready var dmg_l : Label = $content/subtitle/dmg/m/h/Label
@onready var dmg_rects : Dictionary = {
	"p" : $content/subtitle/dmg/m/h/p,
	"v" : $content/subtitle/dmg/m/h/v,
	"c" : $content/subtitle/dmg/m/h/c,
}
@onready var ap_l : Label = $content/abilites/ap/m/Label
@onready var sp_l : Label = $content/abilites/sp/m/Label
@onready var ref_l : Label = $content/abilites/ref/m/Label
@onready var push_l : Label = $content/abilites/push/m/Label
@onready var heal_l : Label = $content/abilites/heal/m/Label
