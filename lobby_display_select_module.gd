extends MarginContainer

func _on_team_sel_item_selected(index):
	team_name = sel.get_item_text(index)
	get_parent().team = DataLoader.teams_by_name[team_name]

@onready var sel : OptionButton = $team_sel
@onready var name_l : Label = $team_name

var team_name : String = ""
@rpc("any_peer", "call_local", "reliable")
func set_team_name(text:String):
	team_name
	name_l.text = text

