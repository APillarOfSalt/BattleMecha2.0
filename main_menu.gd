extends Container


func _on_play_pressed():
	get_tree().change_scene_to_file("res://multiplayer_lobby.tscn")

func _on_exit_pressed():
	get_tree().quit()

func _on_edit_pressed():
	get_tree().change_scene_to_file("res://unit_customizer.tscn")


func _on_dev_pressed():
	get_tree().change_scene_to_file("res://dev_tools.tscn")
