extends HBoxContainer

class_name Deck_Manager

@onready var deck_cont : GridContainer = $deck
var team_name : String = ""
var unit_data : Dictionary #unit_id:int : {"data":Unit_Data, "num":int}
func setup(team:Team_Data): #->Array[Unit_Node]:
	team_name = team.name
	var raw_units : Array[Unit_Data] = []
	for i in team.units.keys():
		if i > 4:
			continue
		for unit:Unit_Data in team.units[i]:
			unit_data[unit.id] = {"data":unit,"num":i}
			for j in i:
				raw_units.append(unit)
	if raw_units.size() != 20:
		print("oop")
		return []
	for i in 20:
		deck_cont.get_child(i).unit = raw_units.pop_front()

func set_base_color(color:Color):
	for i in 20:
		deck_cont.get_child(i).base_color = color
func set_secondary_color(color:Color):
	for i in 20:
		deck_cont.get_child(i).secondary_color = color
func set_tertiary_color(color:Color):
	for i in 20:
		deck_cont.get_child(i).tertiary_color = color

func rand_unit_id()->int:
	var offset : int = randi_range(0,19)
	for i in 20:
		var index : int = ( i + offset ) % 20
		var cont = deck_cont.get_child(index)
		if !cont.get_is_dead() and cont.linked_node == null:
			return cont.unit.id
	return -1
func get_unit(id:int)->Unit_Node:
	for i in 20:
		var cont = deck_cont.get_child(i)
		var toggle : bool = cont.unit.id == id
		var has_deployed : bool = cont.get_is_dead() or cont.linked_node != null
		if toggle and !has_deployed:
			return cont.take_node()
	return null

func refresh():
	var total_deployed : int = 0
	for i in 20:
		var cont = deck_cont.get_child(i)
		if cont.get_is_dead() or cont.linked_node != null:
			total_deployed += 1
	$left/cur/m/Label.text = str(total_deployed)
	$left/re/m/Label.text = str(20 - total_deployed)

func has_ran_out()->bool:
	return rand_unit_id() == -1
