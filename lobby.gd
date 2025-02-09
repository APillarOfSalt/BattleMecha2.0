#extends Container
#
#
#const player_scene : PackedScene = preload("res://lobby_player.tscn")
#@onready var players : Array[Container] = [$v/players/player1, $v/players/player2, $v/players/player3]
#
#func _ready():
	#DataLoader.units_from_memory()
#
#func _on_network_manager_update_iid(new:int):
	#for player in players:
		#player.local_instance_id = new
		#player._refresh_iids.call_deferred()
#
#
#func _on_network_manager_client_joined(iid:int):
	#if Global.server_controller.instance_id != 1:
		#return
	#for i in 3:
		#players[i]._refresh_iids.rpc()
		#var index : int = max(0,players[i].iid-1)
		#players[i]._on_host_item_selected.rpc(index, true)
		#players[i].pid_setter.rpc(players[i].host_num_op.get_item_id(index))
#
#var all_data : Array = [{},{},{}]
#func _on_player_1_readied(data:Dictionary):
	#all_data[0] = data
	##print("player1:", data)
	#check_go()
#func _on_player_2_readied(data:Dictionary):
	#all_data[1] = data
	##print("player2:", data)
	#check_go()
#func _on_player_3_readied(data:Dictionary):
	#all_data[2] = data
	##print("player3:", data)
	#check_go()
#
#func check_go()->bool:
	#for i in players:
		#if !i.is_ready:
			#return false
	#if $custom_timer.tick < 0:
		#$custom_timer.tick = Time.get_ticks_msec()
		#$center.show()
	#return true
#
#func _process(_delta):
	#if $custom_timer.tick > 0:
		#if !check_go():
			#$center/anchor/countdown.text = "3"
			#$center.hide()
			#$custom_timer.tick = -1
			#$custom_timer.tick_num = 0
#func _on_custom_timer_one_tick(num):
	#$center/anchor/countdown.text = str(3-num)
	#if num == 3 and multiplayer.get_unique_id() == 1:
		#start_the_game.rpc()
#
#@rpc("authority", "call_local", "reliable")
#func start_the_game():
	#Global.local_player = Global.server_controller.instance_id -1
	#DataLoader.save_game_start(all_data)
	#if Global.local_player == 0:
		#await get_tree().create_timer(0.5).timeout
	#get_tree().change_scene_to_file("res://main_map.tscn")
#
#
#func _on_main_menu_butt_pressed():
	#Global.to_main_menu_scene()
