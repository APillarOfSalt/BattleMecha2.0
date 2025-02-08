extends HBoxContainer

@onready var uis : Array[Unit_Ui] = [$unit0, $unit1, $unit2]
var units : Array[Unit_Data] = [null, null, null]

func setup(ids:Array, units:Dictionary)->Array[Unit_Data]:
	var all_units : Array[Unit_Data]
	for i in 4:
		if !i in units.keys():
			continue
		for unit:Unit_Data in units[i]:
			all_units.append(unit)
			var found : int = ids.find(unit.id)
			if found > -1:
				set_unit(found,unit)
	return all_units

func set_unit(index:int, unit:Unit_Data):
	units[index] = unit
	uis[index].unit = unit
