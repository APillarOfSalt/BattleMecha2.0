extends Line2D
class_name Offensive_Animation_Controller

var linked_defs : Array[Defense_Animation_Controller]

enum ANIM{none=-1,coil=0,melee_p,melee_v,ranged_c,ranged_p}
var active_anim : ANIM = ANIM.none
var active_anim_name : String
const ANIMS : Dictionary = {
	"coil" : {
		"msec" : 2400,
		"hit" : 1440,
	},
	"melee_p" : {
		"msec" : 650,
		"hit" : 240,
	},
	"melee_v" : {
		"msec" : 1000,
		"hit" : 400,
	},
	"ranged_c" : {
		"msec" : 1550,
		"hit" : 300,
	},
	"ranged_p" : {
		"msec" : 850,
		"hit" : 400,
	},
	#"laser", "launcher"
}


