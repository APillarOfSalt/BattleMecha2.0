extends Sprite2D

const outline_shader : ShaderMaterial = preload("res://assets/outlineShader.tres")
const unit_sel_disp : PackedScene = preload("res://unit_sel_disp.tscn")
@onready var scroll : ScrollContainer = $s
var scroll_amount : int = 0
var unit : Unit_Data = null:
	set(data):
		unit = data
		$h/edit.visible = data != null
		if unit == null:
			frame = 20
		else:
			frame_coords = data.atlas

var selected : bool = false
func _ready():
	material = outline_shader.duplicate(true)
	for id in 20:
		var disp = unit_sel_disp.instantiate()
		$s/h.add_child(disp)
		disp.id = id
		disp.pressed.connect(_on_id_pressed)

func _process(delta):
	var is_hovered : bool = get_local_mouse_position().length() <= $h.size.x
	var width : int = max(int(is_hovered), 2*int(selected))
	material.set_shader_parameter("width", width)
	if scroll.visible and !is_hovered:
		_sync_scroll()
		scroll.visible = false
	$h.visible = is_hovered and !scroll.visible

func _on_id_pressed(id:int):
	unit = DataLoader.units_by_id[id]
	selected = get_parent().selected_id == id
	_sync_scroll()
	scroll.hide()
	get_parent().recalc()

func _on_resel_pressed():
	$h.hide()
	scroll.show()
	godot_sucks_ass.call_deferred()
func godot_sucks_ass():
	scroll.scroll_horizontal = scroll_amount
func _on_edit_pressed():
	get_parent().select(unit.id)

func hide_from_cap(ids:Array):
	for disp in $s/h.get_children():
		disp.visible = !disp.id in ids

func _sync_scroll():
	scroll_amount = scroll.scroll_horizontal
	for disp in get_tree().get_nodes_in_group("team_edit_unit_disp"):
		disp.scroll_amount = scroll_amount
