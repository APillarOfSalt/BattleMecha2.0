extends Node2D
class_name Defensive_Animation_Controller

signal finished()
signal started(end_time_msec:int)

@onready var anim_p = $AnimationPlayer
@onready var unit : Unit_Node = get_parent().get_parent()
@onready var stats : Unit_UI_Stats = $"../unit_ui".stats

var dmg_type : int = Module_Data.DMG_TYPES.untyped
var weapon_size : int = 1
var subtype : String = "None"
var defenders : Array = []

func _setup_defense(type:Module_Data.DMG_TYPES, wep_size:int)->int:
	#true==shield break ; false==either still has shield or never had
	dmg_type = type
	weapon_size = wep_size
	var sheild_break : bool = stats._setup_next_damage(wep_size, type)
	if sheild_break:
		active_anim = ANIM.shield_break
	elif unit.stats.shield:
		active_anim = ANIM.shield_hit
	else:
		active_anim = ANIM.hit
	active_anim_name = ANIMS[active_anim].anim
	$p_hit.visible = type == Module_Data.DMG_TYPES.percussive
	$c_hit.visible = type == Module_Data.DMG_TYPES.concussive
	$v_hit.visible = type == Module_Data.DMG_TYPES.voltaic
	$mask/v_hit.visible = type == Module_Data.DMG_TYPES.voltaic
	return ANIMS[active_anim][STRS[type]]

func _play():
	if active_anim == 0:
		print("oop")
		return
	printerr(active_anim)
	_do_anim(0)

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
	if active_anim == ANIM.death:
		unit.map_obj.do_free(-1)
	stats._on_hit()
	finished.emit()

@rpc("any_peer", "call_remote", "reliable")
func _play_death(local:bool=true):
	active_anim = ANIM.death
	active_anim_name = ANIMS[active_anim].anim
	play_msec = Time.get_ticks_msec()+100
	if local:
		_play_death.rpc(false)


const STRS : Dictionary = {
	Module_Data.DMG_TYPES.untyped : "u",
	Module_Data.DMG_TYPES.percussive : "p",
	Module_Data.DMG_TYPES.concussive : "c",
	Module_Data.DMG_TYPES.voltaic : "v",
}
enum ANIM{death=4, hit=3, shield_break=2, shield_hit=1, none=0}
var active_anim_name : String = ""
var active_anim : int = 0
const ANIMS : Dictionary = {
	ANIM.death : {
		"anim" : "defense_lib/death",
		"msec" : 2500,
		"hit" : 1500,
	},
	ANIM.hit : {
		"anim" : "defense_lib/hit",
		"msec" : 1250,
		"u" : 250,
		"p" : 60,
		"c" : 210,
		"v" : 150,
	},
	ANIM.shield_break : {
		"anim" : "defense_lib/shield_break",
		"msec" : 1600,
		"u" : 400,
		"p" : 530,
		"c" : 380,
		"v" : 590,
	},
	ANIM.shield_hit : {
		"anim" : "defense_lib/shield_hit",
		"msec" : 1550,
		"u" : 250,
		"p" : 60,
		"c" : 210,
		"v" : 280,
	},
}





