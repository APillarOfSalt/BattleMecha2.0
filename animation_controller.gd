extends Path2D
class_name Animation_Controller

signal finished()
signal finished_defense()
signal started(end_time_msec:int)

@onready var anim_p = $AnimationPlayer
@onready var unit : Unit_Node = get_parent().get_parent()
@onready var stats : Unit_UI_Stats = $"../unit_ui".stats

var dmg_type : int = Module_Data.DMG_TYPES.untyped
var weapon_size : int = 1
var subtype : String = "None"
var weapon : Module_Data.Weapon_Data = null
var defenders : Array = []
func setup_atk(wep:Module_Data.Weapon_Data, defs:Array):
	defenders = defs
	weapon = wep
	dmg_type = Module_Data.DMG_TYPES.untyped
	weapon_size = 1
	subtype = "None"
	if wep != null:
		dmg_type = unit.get_dmg_type(wep)
		weapon_size = wep.size
		subtype = wep.subtype
	active_anim = ATK_STRS[subtype]
	active_anim_name = ATK_ANIMS[active_anim].anim
func _play():
	if active_anim == 0:
		print("oop")
		return
	printerr(active_anim)
	if active_anim < 0:
		_do_anim(0)
	if subtype == "Rifle" or subtype == "Cannon" or subtype == "Launcher":
		_play_next()
	else:
		_play_all()

func _play_all():
	var furthest : Vector2 = Vector2(0,0)
	for def in defenders:
		var pos : Vector2 = to_local(def.global_position)
		if pos.length() > furthest.length():
			furthest = pos
	curve = Curve2D.new()
	curve.add_point(Vector2(0,0))
	curve.add_point(furthest)
	$from.progress_ratio = 0.0
	$early.progress_ratio = 0.2
	$midpoint.progress_ratio = 0.35
	$to.progress_ratio = 1.0
	var sync_msec : int = Time.get_ticks_msec() + ( 200 * (defenders.size()+1) )
	while defenders.size():
		var def : Unit_Node = defenders.pop_front()
		var def_hit_msec : int = def.anim_ctrl._setup_defense(dmg_type, weapon_size)
		var atk_hit_msec : int = ATK_ANIMS[active_anim].hit
		#if def == 10 and atk == 20 ; then atk.play() ...wait(20-10=10)... def.play()
		var def_wait : int = min(0,atk_hit_msec - def_hit_msec) #20-10=10def
		var atk_wait : int = min(0,def_hit_msec - atk_hit_msec) #10-20=min(0,-10)=0atk
		var exit_count : int = 10
		play_msec = atk_wait+sync_msec
		def.anim_ctrl._do_anim(def_wait + sync_msec)
		print("sync@",Time.get_ticks_msec()," def:", def.anim_ctrl.play_msec,", off:",play_msec)

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
	var def_hit_msec : int = def.anim_ctrl._setup_defense(dmg_type, weapon_size)
	var atk_hit_msec : int = ATK_ANIMS[active_anim].hit
	#if def == 10 and atk == 20 ; then atk.play() ...wait(20-10=10)... def.play()
	var def_wait : int = min(0,atk_hit_msec - def_hit_msec) #20-10=10def
	var atk_wait : int = min(0,def_hit_msec - atk_hit_msec) #10-20=min(0,-10)=0atk
	var exit_count : int = 10
	var sync_msec : int = Time.get_ticks_msec() + 200
	play_msec = atk_wait + sync_msec
	def.anim_ctrl._do_anim(def_wait + sync_msec)
	print("sync@",Time.get_ticks_msec()," def:", def.anim_ctrl.play_msec,", off:",play_msec)

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
	if anim_name.begins_with("offense"):
		unit.attack_anim_started.emit(end_time_msec + Time.get_ticks_msec())
	if anim_name == "defense_lib/death":
		unit.is_now_dying.emit(unit)

func _on_animation_player_animation_finished(anim_name:String):
	print(anim_name, " :ANIM FINISHED")
	play_msec = -1
	if anim_name.begins_with("offense"):
		if defenders.size():
			_play_next()
		else:
			weapon = null
			dmg_type = -1
			active_anim = -1
			active_anim_name = ""
			finished.emit()
	else:
		finished_defense.emit()
		if anim_name == "defense_lib/death":
			unit._kill_me()
		elif !stats._on_hit():
			_play_death()




func _play_death():
	active_anim = DEF_ANIM.death
	active_anim_name = DEF_ANIMS[active_anim].anim
	play_msec = Time.get_ticks_msec()+100

func _setup_defense(type:Module_Data.DMG_TYPES, wep_size:int)->int:
	#true==shield break ; false==either still has shield or never had
	var sheild_break : bool = stats._setup_next_damage(wep_size, type)
	if sheild_break:
		active_anim = DEF_ANIM.shield_break
	elif unit.stats.shield:
		active_anim = DEF_ANIM.shield_hit
	else:
		active_anim = DEF_ANIM.hit
	active_anim_name = DEF_ANIMS[active_anim].anim
	$to/p_hit.visible = type == Module_Data.DMG_TYPES.percussive
	$to/c_hit.visible = type == Module_Data.DMG_TYPES.concussive
	$to/v_hit.visible = type == Module_Data.DMG_TYPES.voltaic
	$to/mask/v_hit.visible = type == Module_Data.DMG_TYPES.voltaic
	return DEF_ANIMS[active_anim][DEF_STRS[type]]

const DEF_STRS : Dictionary = {
	Module_Data.DMG_TYPES.untyped : "u",
	Module_Data.DMG_TYPES.percussive : "p",
	Module_Data.DMG_TYPES.concussive : "c",
	Module_Data.DMG_TYPES.voltaic : "v",
}
const ATK_STRS : Dictionary = {
	"None":ATK_ANIM.untyped,
	"Melee":ATK_ANIM.melee_p,
	"Rifle":ATK_ANIM.ranged_p,
	"Cannon":ATK_ANIM.ranged_c,
	"Launcher":ATK_ANIM.ranged_c,
	"Laser":ATK_ANIM.coil,
	"Coil":ATK_ANIM.coil,
}

enum ATK_ANIM{untyped=-1,none=0, coil=1, melee_p=2, melee_v=3, ranged_c=4, ranged_p=5}
enum DEF_ANIM{death=-4, hit=-3, shield_break=-2, shield_hit=-1, none=0}

var active_anim_name : String = ""
var active_anim : int = 0:
	set(val):
		active_anim = val
const ATK_ANIMS : Dictionary = {
	ATK_ANIM.untyped : {
		"anim" : "offense_lib/push",
		"msec" : 1000,
		"hit" : 250,
	},
	ATK_ANIM.coil : {
		"anim" : "offense_lib/coil",
		"msec" : 2400,
		"hit" : 1440,
	},
	ATK_ANIM.melee_p : {
		"anim" : "offense_lib/melee_p",
		"msec" : 650,
		"hit" : 240,
	},
	ATK_ANIM.melee_v : {
		"anim" : "offense_lib/melee_v",
		"msec" : 1000,
		"hit" : 400,
	},
	ATK_ANIM.ranged_c : {
		"anim" : "offense_lib/ranged_c",
		"msec" : 1550,
		"hit" : 300,
	},
	ATK_ANIM.ranged_p : {
		"anim" : "offense_lib/ranged_p",
		"msec" : 850,
		"hit" : 400,
	},
	#"laser", "launcher"
}
const DEF_ANIMS : Dictionary = {
	DEF_ANIM.death : {
		"anim" : "defense_lib/death",
		"msec" : 2500,
		"hit" : 1500,
	},
	DEF_ANIM.hit : {
		"anim" : "defense_lib/hit",
		"msec" : 1250,
		"u" : 250,
		"p" : 60,
		"c" : 210,
		"v" : 150,
	},
	DEF_ANIM.shield_break : {
		"anim" : "defense_lib/shield_break",
		"msec" : 1600,
		"u" : 400,
		"p" : 530,
		"c" : 380,
		"v" : 590,
	},
	DEF_ANIM.shield_hit : {
		"anim" : "defense_lib/shield_hit",
		"msec" : 1550,
		"u" : 250,
		"p" : 60,
		"c" : 210,
		"v" : 280,
	},
}





