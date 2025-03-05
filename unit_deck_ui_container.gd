extends Container

@onready var u_spr : Sprite2D = $m/unit
@onready var w_spr : Sprite2D = $m/wreck
@onready var ql : Label = $m/question_mark

const unit_outline_width : int = 4

const unit_node_scene : PackedScene  = preload("res://unit_node.tscn")
const detailed_unit_scene : PackedScene = preload("res://unit_detailed_display.tscn")

func get_is_in_deck()->bool:
	return linked_node == null and !get_is_dead()
func get_is_dead()->bool:
	return w_spr.visible
var linked_node : Unit_Node = null
func take_node()->Unit_Node:
	if linked_node != null or w_spr.visible:
		return null
	linked_node = unit_node_scene.instantiate()
	linked_node.unit_data = unit
	linked_node.is_now_dead.connect(_on_linked_death)
	linked_node.unit_hovered.connect(_on_unit_hovered)
	local_mat = linked_node.set_spr_mat()
	linked_node.player_color = base_color
	local_mat.set_shader_parameter("color",secondary_color)
	local_mat.set_shader_parameter("tint", Color(0.0,0.0,0.0,0.0) )
	u_spr.material = local_mat
	ql.hide()
	u_spr.show()
	return linked_node
func _on_linked_death(node:Unit_Node=null, death_return_sale:int=-1):
	print(node.name, node.map_obj.id, " dead")
	if node != linked_node:
		return
	node.hide()
	var is_in_deck : bool = death_return_sale != -1
	u_spr.visible = is_in_deck
	w_spr.visible = !is_in_deck
	local_mat.set_shader_parameter("tint", Color(0.0,0.0,0.0, int(is_in_deck) ))
	node.map_obj.queue_free()
	node.queue_free()

var unit : Unit_Data = null:
	set(data):
		unit = data
		u_spr.frame_coords = data.atlas
		create_detailed_display()
var base_color : Color = Color.WHITE:
	set(color):
		base_color = color
		ql.add_theme_color_override("font_color", base_color)
var secondary_color : Color
var tertiary_color : Color

var local_mat : ShaderMaterial = null
var is_emitting : bool = false
func _on_unit_hovered(unit:Unit_Node, is_hovered:bool):
	if unit != linked_node or is_emitting:
		return
	is_emitting = true
	local_mat.set_shader_parameter("width", int(is_hovered)*unit_outline_width)
	linked_node.map_obj.cursor.cursor_hover(is_hovered)
	is_emitting = false

func _on_button_mouse_entered():
	if linked_node != null:
		if linked_node.is_inside_tree():
			_on_unit_hovered(linked_node, true)

func _on_button_mouse_exited():
	if linked_node != null:
		if linked_node.is_inside_tree():
			_on_unit_hovered(linked_node, false)

var detailed_display : Detailed_Unit_Display = null
func create_detailed_display():
	detailed_display = detailed_unit_scene.instantiate()
	$PopupPanel.transient = false
	$PopupPanel.add_child(detailed_display)
	detailed_display.unit = unit

func _on_button_toggled(toggled_on:bool):
	if toggled_on:
		var rect : Rect2
		rect.size = detailed_display.size
		rect.position = Vector2( $PopupPanel.position )
		$PopupPanel.popup(rect)
	elif $PopupPanel.visible:
		$PopupPanel.hide()

func _on_popup_panel_popup_hide():
	$Button.button_pressed = false
