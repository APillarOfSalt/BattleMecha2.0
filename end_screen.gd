extends PanelContainer


func _on_menu_pressed():
	Global.to_main_menu_scene()
#func _ready():
	#Global.player_info_by_num = {0:{"name":"Zero"},1:{"name":"One"},2:{"name":"Two"}}
	#_setup({0:0, 1:6, 2:3})

func _setup(scores:Dictionary):
	var vals : Array = scores.values()
	vals.sort_custom(func c(a,b)->bool:return a>b)
	var first : int
	var first_score : int
	var second : int
	var second_score : int
	var third : int
	var third_score : int
	first_score = vals[0]
	second_score = vals[1]
	third_score = vals[2]
	for p_num in scores.keys():
		var val : int = scores[p_num]
		if val == first_score:
			first = p_num
		elif val == second_score:
			second = p_num
		elif val == third_score:
			third = p_num
	_show_scores.rpc(first, first_score, second, second_score, third, third_score)

@rpc("authority", "call_local", "reliable")
func _show_scores(f:int,fs:int,s:int,ss:int,t:int,ts:int):
	show()
	$v/m/list/p1/Label.text = Global.player_info_by_num[f].name
	$v/m/list/p1/p/m/score.text = str(fs)
	$v/m/list/p2/Label.text = Global.player_info_by_num[s].name
	$v/m/list/p2/p/m/score.text = str(ss)
	$v/m/list/p3/Label.text = Global.player_info_by_num[t].name
	$v/m/list/p3/p/m/score.text = str(ts)
	tick = Time.get_ticks_msec()

var tick_speed_msec : int = 777
var tick : int = -1
func _process(delta):
	if tick < 0 or Time.get_ticks_msec() - tick < tick_speed_msec:
		return
	tick = Time.get_ticks_msec()
	for nd in [$v/m/list/p3,$v/m/list/p2,$v/m/list/p1,$v/m/list/menu]:
		if !nd.visible:
			nd.show()
			return
	tick = -1

