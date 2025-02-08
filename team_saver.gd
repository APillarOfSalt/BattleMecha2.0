extends Container


var units_valid : bool = false
func _on_tile_map_full_valid(is_valid:bool):
	units_valid = is_valid
	title_disable_checker()


func title_disable_checker():
	var name_invalid : bool = name_valid == VALID.invalid
	var units_not_selected : bool = -1 in current_team.starting_units
	$title/save.disabled = name_invalid or !units_valid or !cost_done or units_not_selected

@export var palette_edit : Container = null
@export var unit_edit : Unit_Editor = null
@export var cursor : Cursor_Container = null
@onready var map : TileMap = $r/TileMap
func _ready():
	refresh_teams()
	map.set_units({})

func refresh_teams():
	$title/team.clear()
	$title/team.add_item("+ New Team")
	for t_name:String in DataLoader.teams_by_name.keys():
		$title/team.add_item(t_name)
		if t_name == current_team.name:
			$title/team.selected = $title/team.item_count-1


@onready var current_team : Team_Data = Team_Data.new():
	set(team):
		current_team = team._duplicate()
		map.set_units(team.units)
		palette_edit.base_color = team.base_color
		palette_edit.palette = team.palette
		cost_edit.set_vals(team.starting_resources)
		DataLoader.units_from_memory()
		for num in team.units.keys():
			for unit:Unit_Data in team.units[num]:
				DataLoader.units_by_id[unit.id] = unit
		for i in 3:
			var unit_sel = [$"../l/sel0", $"../l/sel1", $"../l/sel2"][i]
			var unit_id := int( team.starting_units[i] )
			var data : Unit_Data = null
			if unit_id > -1:
				data = DataLoader.units_by_id[unit_id]
			unit_sel.set_unit_data( data )
var og_team_name : String = "":
	set(text):
		og_team_name = text
		name_edit.text = text

func _on_team_item_selected(index):
	var team_name : String = $title/team.get_item_text(index)
	unit_edit.unit = null
	if index == 0:
		cursor.mod_manager.current_mod = null
		name_edit.text = ""
		DataLoader.global_team = null
		current_team = Team_Data.new()
		og_team_name = ""
	else:
		current_team = DataLoader.teams_by_name[team_name]
		DataLoader.global_team = current_team
		og_team_name = team_name
		name_edit.text = team_name
		name_valid = _is_name_valid(team_name)
	title_disable_checker()

@onready var name_edit : LineEdit = $title/h/LineEdit
var team_name : String:
	set(text):
		current_team.name = text
		name_valid = _is_name_valid(text)
		title_disable_checker()
	get: return current_team.name
var name_valid : VALID = VALID.invalid:
	set(val):
		name_valid = val
		$title/save.disabled = val == VALID.invalid or !units_valid
		$title/h/m/invalid.visible = val == VALID.invalid
		$title/h/m/valid.visible = val == VALID.valid
		$title/h/m/warning.visible = val == VALID.replace
		if val == VALID.replace:
			$title/h/m/warning.tooltip_text = str('There is already a team named "',team_name,'".')
func _on_line_edit_text_changed(new_text:String):
	if name_edit.caret_column > 1:
		new_text = new_text.strip_edges(true, false)
	if name_edit.text != new_text:
		name_edit.text = new_text
	team_name = new_text

enum VALID{invalid=0, valid=1, replace=2}
func _is_name_valid(new_name:String)->VALID:
	if new_name == "":
		return VALID.invalid
	elif new_name == og_team_name:
		return VALID.valid
	for t_name in DataLoader.teams_by_name.keys():
		if t_name == new_name:
			return VALID.replace
	return VALID.valid


func _on_line_edit_focus_exited():
	var text : String = name_edit.text
	text = name_edit.text.strip_edges()
	while "  " in text:
		text = text.replace("  "," ")
	name_edit.text = text

func _on_save_pressed():
	current_team.units = map.get_units()
	current_team.starting_resources = cost_edit.get_vals()
	current_team.base_color = palette_edit.base_color
	current_team.palette = palette_edit.palette
	DataLoader.save_team(current_team, false)
	refresh_teams()


@export var cost_edit : Container = null
var cost_done : bool = false
func _on_cost_editor_complete(is_done:bool):
	cost_done = is_done
	title_disable_checker()

func _on_sel_0_unit_selected(unit_id:int):
	if current_team == null:
		return
	current_team.starting_units[0] = unit_id
	title_disable_checker()
func _on_sel_1_unit_selected(unit_id:int):
	if current_team == null:
		return
	current_team.starting_units[1] = unit_id
	title_disable_checker()
func _on_sel_2_unit_selected(unit_id:int):
	if current_team == null:
		return
	current_team.starting_units[2] = unit_id
	title_disable_checker()



