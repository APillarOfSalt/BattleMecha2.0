extends HBoxContainer

signal local_player_readied(data:Player_Data)
func _on_local_readied(is_ready):
	local_player_readied.emit(local_player.get_player_data())

@onready var local_player : Container = $local
var player_num : int:
	set(val): local_player.player_num = val
	get: return local_player.player_num
@onready var p1 : Container = $p0
@onready var p2 : Container = $p1

func check_ready()->bool:
	for i in [local_player, p1, p2]:
		if !i._check_ready():
			return false
	return true

@rpc("authority", "call_local", "reliable")
func _sync_player_num():
	var num : int = Global.server_controller.instance_id-1
	local_player.player_num = num
	local_player.name = str("Player",num)
	local_player._on_ready_toggled(false)
	p1.player_num = (num + 1) % 3
	p1.name = str("Player",(num + 1) % 3)
	p1._on_ready_toggled(false)
	p2.player_num = (num + 2) % 3
	p2.name = str("Player",(num + 2) % 3)
	p2._on_ready_toggled(false)

func get_player_disp(p_num:int):
	var index : int = (p_num - player_num + 3) % 3
	return [local_player, p1, p2][index]

func set_player_data(data:Player_Data):
	var disp = get_player_disp(data.num)
	disp.player_name = data.name
	disp.team = data.team
	disp.is_online = data.team != null



