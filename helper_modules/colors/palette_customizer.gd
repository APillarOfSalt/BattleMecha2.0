extends Container

@export var preset_data := Vector4(0,0,0,-1)
func from_set_data(data:Vector4)->bool:
	if data.w <= -1 or data.w >= ColorHelper.PALETTES.MAX:
		return false
	palette = int(data.w)
	base_color = Color(data.x,data.y,data.z,1.0)
	return true
func to_set_data()->Vector4:
	return Vector4(base_color.r, base_color.g, base_color.b, palette)

@onready var vis_inst : Node2D = $g/base/vis_lims
func _ready():
	var pick : ColorPicker = base_butt.get_picker()
	vis_inst.show()
	vis_inst.reparent(pick, false)
	vis_inst.position = Vector2(0,0)
	pick.color_mode = pick.ColorModeType.MODE_HSV
	pick.picker_shape = pick.PickerShapeType.SHAPE_VHS_CIRCLE
	pick.edit_alpha = false
	pick.sampler_visible = false
	pick.color_modes_visible = false
	p_op.clear()
	for p:int in ColorHelper.PALETTES.MAX:
		p_op.add_item(ColorHelper.PALETTE_NAMES[p], p)
	p_op.selected = 0
	generate_palette()
	if !from_set_data(preset_data):
		base_color = Color(ColorHelper.color_names.pick_random())

func get_closest_color_name(color:Color)->String:
	return ColorHelper.closest_color(color).to_lower().capitalize()

@onready var p_op : OptionButton = $h/palette
var palette : ColorHelper.PALETTES = ColorHelper.PALETTES.Monochromatic:
	set(val):
		palette = val
		generate_palette()
		if p_op.selected != p_op.get_item_index(val):
			p_op.selected = val
func _on_palette_item_selected(index):
	var id : int = p_op.get_item_id(index)
	if palette != id:
		palette = id
		_on_color_color_changed(base_color)

@onready var base_butt : ColorPickerButton = $g/base/color
@onready var base_l : Label = $g/base/Label
var base_color : Color:
	set(color):
		var hsv : Vector4 = ColorHelper.rgb_to_hsv(color)
		hsv.z = max(0.5, hsv.z)
		base_color = Color.from_hsv(hsv.x, hsv.y, hsv.z, hsv.w)
		base_l.text = get_closest_color_name(base_color)
		generate_palette()
		if base_butt.color != base_color:
			base_butt.color = base_color
func _on_color_color_changed(color):
	if base_color != color:
		base_color = color

func generate_palette():
	var colors : Array[Color] = ColorHelper.generate_palette(base_color, palette, 3)
	secondary_color = colors[1]
	sec_rect.color = secondary_color
	sec_l.text = get_closest_color_name(secondary_color)
	tertiary_color = colors[2]
	ter_rect.color = tertiary_color
	ter_l.text = get_closest_color_name(tertiary_color)

var secondary_color : Color
@onready var sec_rect : ColorRect = $g/sec/p/m/rect
@onready var sec_l : Label = $g/sec/Label
var tertiary_color : Color
@onready var ter_rect : ColorRect = $g/ter/p/m/rect
@onready var ter_l : Label = $g/ter/Label
