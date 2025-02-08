extends MarginContainer

signal pressed(id:int)

var unit : Unit_Data = null
var id : int = -1:
	set(val):
		id = val
		if val == -1:
			return
		unit = DataLoader.units_by_id[id]
		$Sprite2D.frame_coords = unit.atlas

func _on_button_pressed():
	pressed.emit(id)
