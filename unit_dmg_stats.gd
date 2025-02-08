extends GridContainer

func setup(unit:Unit_Data):
	for i in ["p","v","c"]:
		for j in ["a","r"]:
			get_node(i+j).text = str(unit.damage_types[i][j])
