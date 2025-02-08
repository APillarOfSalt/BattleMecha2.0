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


func get_unit(id:int=-1)->Unit_Node:
	var offset : int = 0
	if id == -1:
		offset = randi_range(0,20)
	for i in 20:
		var index : int = (i + offset) % 20
		var cont = deck_cont.get_child(index)
		var toggle : bool = cont.unit.id == id or id == -1
		if toggle and cont.linked_node == null:
			return cont.take_node()
	return null

