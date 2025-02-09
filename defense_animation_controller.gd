extends Node2D
class_name Defense_Animation_Controller

@onready var unit : Unit_Node

func _setup(atk:Offensive_Animation_Controller):
	pass

enum ANIM{none=-1,death=0,hit,shield_break,shield_hit}
var active_anim : ANIM = ANIM.none
var active_anim_name : String
const ANIMS : Dictionary = {
	"death" : {
		"msec" : 2500,
		"hit" : 1500,
	},
	"hit" : {
		"msec" : 1250,
		"p" : 60,
		"c" : 210,
		"v" : 150,
	},
	"shield_break" : {
		"msec" : 1600,
		"p" : 530,
		"c" : 380,
		"v" : 590,
	},
	"shield_hit" : {
		"msec" : 1550,
		"p" : 60,
		"c" : 210,
		"v" : 280,
	},
}
