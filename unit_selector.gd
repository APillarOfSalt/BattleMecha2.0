extends Container

var disabled : bool = false: set = disable_setter
func disable_setter(toggle:bool):
	disabled = toggle
	team_op.disabled = toggle
	op.disabled = toggle
	prev_unit.disabled = toggle
	next_unit.disabled = toggle
	for check in checks:
		check.disabled = toggle

func _refresh_teams():
	var sel_save : int = team_op.selected
	team_op.clear()
	team_net_l.modulate.a = int(team_op.disabled)
	if !team_op.disabled:
		team_op.add_item("Select Team")
		for team_name:String in DataLoader.teams_by_name.keys():
			team_op.add_item(team_name)
		team_op.selected = sel_save
@onready var team_op : OptionButton = $team/local
@onready var team_net_l : Label = $team/network
@onready var prev_unit : Button = $h/l
@onready var next_unit : Button = $h/r

func _on_local_item_selected(index):
	if index == -1:
		return
	var team_name:String = team_op.get_item_text(index)
	team = DataLoader.teams_by_name[team_name]
	set_team.rpc(team._to_json_string())
	team_units.clear()
	for num:int in team.units.keys():
		for unit in team.units[num]:
			team_units.append(unit)
	_refresh_units()

var team : Team_Data = null:
	set(data):
		team = data
		if team_op.item_count:
			team_op.get_popup().set_item_disabled(0, true)
@rpc("any_peer", "call_remote", "reliable")
func set_team(json:String):
	team = Team_Data.new()
	team._from_json_string(json)
	team_net_l.text = team.name
	team_units.clear()
	for num:int in team.units.keys():
		for unit in team.units[num]:
			team_units.append(unit)
	_refresh_units()
	_refresh_teams()

var team_units : Array[Unit_Data] = []
func _refresh_units():
	var first_three: Array[Unit_Data] = []
	for unit:Unit_Data in team_units:
		if first_three.size() < 3:
			first_three.append(unit)
		op.add_item(unit.name, unit.id)
	current_sel = -1
	if !first_three.size():
		return
	for i in 3:
		units[i].unit = first_three[i]
	current_sel = 0

func get_team_unit(id:int)->Unit_Data:
	for i in team_units.size():
		if team_units[i].id == id:
			return team_units[i]
	return null

func clear():
	set_checks(-1)
	for i in units:
		i.unit = null

@onready var op : Option_Button = $h/OptionButton
func _on_l_pressed():
	op.selected = (op.selected+op.item_count - 1) % op.item_count
func _on_r_pressed():
	op.selected = (op.selected + 1) % op.item_count

func _on_option_button_item_selected(index):
	if current_sel == -1:
		if index == -1:
			return
		current_sel = 0
	var unit_id : int = op.get_item_id(index)
	units[current_sel].unit = get_team_unit(unit_id)
	set_unit.rpc(current_sel, unit_id)

@onready var units : Array = [$m/units/unit0, $m/units/unit1, $m/units/unit2]
@rpc("any_peer", "call_remote", "reliable")
func set_unit(index:int, id:int):
	units[index].unit = get_team_unit(id)
@onready var checks : Array = [$m/units/check0, $m/units/check1, $m/units/check2]
var current_sel : int = 0: set = set_checks
var ignore_check_signals : bool = false
func _on_check_0_toggled(_on):
	set_checks(0)
func _on_check_1_toggled(_on):
	set_checks(1)
func _on_check_2_toggled(_on):
	set_checks(2)
func set_checks(index:int):
	if ignore_check_signals or current_sel == index:
		return
	ignore_check_signals = true
	current_sel = index
	if index == -1:
		op.selected = -1
	elif units[index].unit != null:
		op.selected = op.get_item_index(units[index].unit.id)
	for i in 3:
		checks[i].button_pressed = index == i
	ignore_check_signals = false

