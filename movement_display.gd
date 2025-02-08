extends Container

@onready var dir_sprs : Array = [$anchor/up,$anchor/ur,$anchor/dr,$anchor/down,$anchor/dl,$anchor/ul]
func setup(unit:Unit_Data):
	for i in 6:
		dir_sprs[i].frame = unit.movement[i]

func clear():
	for i in 6:
		dir_sprs[i].frame = 0
