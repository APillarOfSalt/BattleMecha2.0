extends Container
class_name Turn_Tracker

#func _input(event):
	#if event.is_action_pressed("lmb"):
		#advance()

@export var anim_curve : Curve = preload("res://main_text_anim_curve.tres")

@export_range(250,2000) var play_time_msec : int = 2000

var setup : int = 0:
	set(val):
		setup = val
		if val == 9 and first:
			advance()

var round : int = 0
func get_round_text()->String:
	return str("Round ",round)
const PHASE : Array[String] = ["Action","Move","Melee","Ranged"]
enum PHASES{action=0,move=1,melee=2,ranged=3,MAX}
var phase : PHASES = -1
func get_phase_text()->String:
	return str( PHASE[phase]," Phase" )

func advance():
	phase = ( phase + 1 ) % PHASES.MAX
	phase_ll.text = get_phase_text()
	if phase == PHASES.action:
		round += 1
		round_ll.text = get_round_text()
	play()

@onready var round_ls : Label = $h/s_l_cont/round_s
@onready var round_ll : Label = $l_l_cont/round_l
@onready var phase_ls : Label = $h/s_l_cont/phase_s
@onready var phase_ll : Label = $l_l_cont/phase_l

func first_swap():
	halfway.disconnect(first_swap)

#animation stuff
signal anim_complete()
func play():
	anim_msec = play_time_msec
	half_sent = false
@onready var deploy_l : Label = $deploy
@onready var l_cont : Control = $l_l_cont #  0->1:hold:1->0 #uses ratio(normal)
@onready var s_cont : Control = $h/s_l_cont #1->0:hold:0->1 #uses 1-ratio(inverse)
var anim_msec : int = 0
var first : bool = true
func _on_halfway():
	first = false
	round_ls.text = get_round_text()
	phase_ls.text = get_phase_text()
signal halfway()
var half_sent : bool = false
func _process(delta):
	if anim_msec == 0:
		return
	var delta_msec : int = floor(delta * 1000)
	anim_msec -= delta_msec
	if anim_msec <= 0:
		anim_msec = 0
		anim_complete.emit()
		return
	var ratio : float = float(anim_msec) / float(play_time_msec)
	if ratio <= 0.5 and !half_sent:
		half_sent = true
		halfway.emit()
	var val : float = anim_curve.sample(ratio)
	var inverse : float = 1.0 - val
	l_cont.modulate.a = val
	if first:
		deploy_l.modulate.a = inverse
	else:
		s_cont.modulate.a = inverse







