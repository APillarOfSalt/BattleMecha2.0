extends VBoxContainer

const type_data : Dictionary = {
	0 : [1,2,3],
	1 : [10,11,12],
	2 : [20,21,22],
	3 : [30,31,32,33,34,35,36],
}
const butt_scene : PackedScene = preload("res://type_button.tscn")
@export_enum("Supertype:0","Module:1","Shield:2","Weapon:3") var supertype : int = 0: set = _set_super
func _set_super(val:int):
	if supertype == val:
		return
	supertype = val
	for i in get_children():
		if i.name != "title":
			i.name = "oh_no"
			i.queue_free()
	for i in type_data[val]:
		add_type(i)
func _ready():
	var text : String = "Type"
	if !supertype:
		text = "Catagory"
		for i in type_data[supertype]:
			add_type(i)
	$title/m/Label.text = text

var disabled : bool = false:
	set(toggle):
		disabled = toggle
		for i in get_children():
			if i.name != "title":
				i.disabled = toggle


signal type_selected(type:int)
var selected_type : int = -1: set = _on_type_sel
func _on_type_sel(type:int):
	if type == selected_type:
		return
	selected_type = type
	for i in get_children():
		if i.name != "title":
			i.pressed = i.name == str(type)
	type_selected.emit(type)

func add_type(type:int):
	var butt = butt_scene.instantiate()
	butt.name = str(type)
	butt.type = type
	add_child(butt)
	butt.button_pressed.connect(_on_type_sel)
	butt.disabled = disabled
