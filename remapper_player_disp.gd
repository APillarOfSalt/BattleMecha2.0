extends HBoxContainer

signal selected(node)

var num : int:
	set(val):
		num = val
		$butt.text = str("Player ",num+1)

@onready var col_picker : ColorPickerButton = $ColorPickerButton
@onready var anchor : Node2D = $anchor/point
var connected : Container = null

func _on_butt_pressed():
	selected.emit(self)

var color : Color:
	set(col):
		color = col
		if col_picker.color != col:
			col_picker.color = col
func _on_color_picker_button_color_changed(col:Color):
	color = col
