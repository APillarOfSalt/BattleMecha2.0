extends Node

func _ready():
	await get_tree().create_timer(0.01).timeout
	Global.to_main_menu_scene()

func update_text():
	$screen/RichTextLabel.text = str(
		DataLoader.validated,"\n",
		DataLoader.shapes_by_id,"\n",
		DataLoader.modules_by_id,"\n",
		DataLoader.units_by_id,"\n",
		DataLoader.teams_by_name
	)

