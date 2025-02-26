extends PanelContainer

var first : int = -1
var first_score : int = -1
var second : int = -1
var second_score : int = -1
var third : int = -1
var third_score : int = -1

func _setup(scores:Dictionary):
	show()
	var vals : Array = scores.values()
	vals.sort_custom(func c(a,b)->bool:return a>b)
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
	$v/m/list/p1/Label.text = Global.player_info_by_num[first].name
	$v/m/list/p1/p/m/score.text = str("1st ", first_score )
	$v/m/list/p2/Label.text = Global.player_info_by_num[second].name
	$v/m/list/p1/p/m/score.text = str("2nd ",  second_score )
	$v/m/list/p3/Label.text = Global.player_info_by_num[third].name
	$v/m/list/p1/p/m/score.text = str("3rd ", third_score )
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



	
	
	
