extends Path2D
class_name Offensive_Animation_Controller

signal finished()
signal started(end_time_msec:int)

@onready var anim_p = $AnimationPlayer
@onready var unit : Unit_Node = get_parent().get_parent()
@onready var stats : Unit_UI_Stats = $"../unit_ui".stats

var dmg_type : int = Module_Data.DMG_TYPES.untyped
var weapon_size : int = 1
var subtype : String = "None"
var weapon : Module_Data.Weapon_Data = null
var ap : bool = false
var sp : bool = false
var defenders : Array = []
func setup_atk(wep:Module_Data.Weapon_Data, defs:Array):
	defenders = defs
	weapon = wep
	ap = "ap" in wep.abilities
	sp = "sp" in wep.abilities
	dmg_type = Module_Data.DMG_TYPES.untyped
	weapon_size = 1
	subtype = "None"
	if wep != null:
		dmg_type = wep.get_dmg_type()
		weapon_size = wep.size
		subtype = wep.subtype
	if dmg_type == Module_Data.DMG_TYPES.healing or dmg_type == Module_Data.DMG_TYPES.shielding:
		active_anim = -1
		active_anim_name = ""
	else:
		active_anim = STRS[subtype]
		active_anim_name = ANIMS[active_anim].anim
func _play():
	if active_anim == 0:
		print("oop")
		return
	printerr(active_anim)
	if dmg_type == Module_Data.DMG_TYPES.healing or dmg_type == Module_Data.DMG_TYPES.shielding:
		while defenders.size():
			var def : Unit_Node = defenders.pop_front()
			def.def_anim_ctrl._setup_defense(dmg_type, weapon_size)
			def.def_anim_ctrl._do_anim(0)
		_on_animation_player_animation_finished("Healing")
	elif subtype == "Rifle" or subtype == "Cannon" or subtype == "Launcher":
		_play_next()
	else:
		_play_all()

func _play_all():
	var furthest : Vector2 = Vector2(0,0)
	for def in defenders:
		var pos : Vector2 = to_local(def.global_position)
		if pos.length() > furthest.length():
			furthest = pos
	if active_anim < 0:
		print("how??")
	curve = Curve2D.new()
	curve.add_point(Vector2(0,0))
	curve.add_point(furthest)
	$from.progress_ratio = 0.0
	$early.progress_ratio = 0.2
	$midpoint.progress_ratio = 0.35
	$to.progress_ratio = 1.0
	var sync_msec : int = Time.get_ticks_msec() + ( 200 * (defenders.size()+1) )
	while defenders.size():
		if active_anim < 0:
			print("how??")
		var def : Unit_Node = defenders.pop_front()
		var def_hit_msec : int = def.def_anim_ctrl._setup_defense(dmg_type, weapon_size, ap, sp)
		var atk_hit_msec : int = ANIMS[active_anim].hit
		#if def == 10 and atk == 20 ; then atk.play() ...wait(20-10=10)... def.play()
		var def_wait : int = min(0,atk_hit_msec - def_hit_msec) #20-10=10def
		var atk_wait : int = min(0,def_hit_msec - atk_hit_msec) #10-20=min(0,-10)=0atk
		var exit_count : int = 10
		play_msec = atk_wait+sync_msec
		def.def_anim_ctrl._do_anim(def_wait + sync_msec)
		print("sync@",Time.get_ticks_msec()," def:", def.def_anim_ctrl.play_msec,", off:",play_msec)

func _play_next():
	var def : Unit_Node = defenders.pop_front()
	if def == null:
		return
	var cur := Curve2D.new()
	cur.add_point(Vector2(0,0))
	cur.add_point(to_local(def.global_position))
	curve = cur
	$from.progress_ratio = 0.0
	$early.progress_ratio = 0.2
	$midpoint.progress_ratio = 0.35
	$to.progress_ratio = 1.0
	var def_hit_msec : int = def.def_anim_ctrl._setup_defense(dmg_type, weapon_size, ap, sp)
	var atk_hit_msec : int = ANIMS[active_anim].hit
	#if def == 10 and atk == 20 ; then atk.play() ...wait(20-10=10)... def.play()
	var def_wait : int = min(0,atk_hit_msec - def_hit_msec) #20-10=10def
	var atk_wait : int = min(0,def_hit_msec - atk_hit_msec) #10-20=min(0,-10)=0atk
	var exit_count : int = 10
	var sync_msec : int = Time.get_ticks_msec() + 200
	play_msec = atk_wait + sync_msec
	def.def_anim_ctrl._do_anim(def_wait + sync_msec)
	print("sync@",Time.get_ticks_msec()," def:", def.def_anim_ctrl.play_msec,", off:",play_msec)

var play_msec : int = -1
func _do_anim(wait:int):
	play_msec = wait

var last_tick : int = 0
func _process(delta):
	if play_msec == -1:
		return
	last_tick = Time.get_ticks_msec()
	if last_tick >= play_msec:
		anim_p.play(active_anim_name)
		play_msec = -1

func _on_animation_player_animation_started(anim_name):
	var sec : float = anim_p.current_animation_length - anim_p.current_animation_position
	var end_time_msec : float = sec * 1000
	started.emit(end_time_msec + Time.get_ticks_msec())

func _on_animation_player_animation_finished(anim_name:String):
	print(anim_name, " :ANIM FINISHED")
	play_msec = -1
	if defenders.size() and active_anim > 0:
		_play_next()
	else:
		weapon = null
		dmg_type = -1
		active_anim = -1
		active_anim_name = ""
	finished.emit()

const STRS : Dictionary = {
	"None":ANIM.untyped,
	"Melee":ANIM.melee_p,
	"Rifle":ANIM.ranged_p,
	"Cannon":ANIM.ranged_c,
	"Launcher":ANIM.ranged_c,
	"Laser":ANIM.coil,
	"Coil":ANIM.coil,
}

enum ANIM{untyped=-1,none=0, coil=1, melee_p=2, melee_v=3, ranged_c=4, ranged_p=5}

var active_anim_name : String = ""
var active_anim : int = 0:
	set(val):
		active_anim = val
const ANIMS : Dictionary = {
	ANIM.untyped : {
		"anim" : "offense_lib/push",
		"msec" : 1000,
		"hit" : 250,
	},
	ANIM.coil : {
		"anim" : "offense_lib/coil",
		"msec" : 2400,
		"hit" : 1440,
	},
	ANIM.melee_p : {
		"anim" : "offense_lib/melee_p",
		"msec" : 650,
		"hit" : 240,
	},
	ANIM.melee_v : {
		"anim" : "offense_lib/melee_v",
		"msec" : 1000,
		"hit" : 400,
	},
	ANIM.ranged_c : {
		"anim" : "offense_lib/ranged_c",
		"msec" : 1550,
		"hit" : 300,
	},
	ANIM.ranged_p : {
		"anim" : "offense_lib/ranged_p",
		"msec" : 850,
		"hit" : 400,
	},
	#"laser", "launcher"
}
