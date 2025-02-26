extends Node

func _ready():
	await Global.create_wait_timer()
	Global.to_main_menu_scene()

func update_text():
	$screen/RichTextLabel.text = str(
		DataLoader.validated,"\n",
		DataLoader.shapes_by_id,"\n",
		DataLoader.modules_by_id,"\n",
		DataLoader.units_by_id,"\n",
		DataLoader.teams_by_name
	)

