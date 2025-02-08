extends GridContainer

@onready var color_rects : Array[ColorRect] = [$base/m/rect, $sec/m/rect, $ter/m/rect]
@onready var name_ls : Array[Label] = [$base_name, $sec_name, $ter_name]
var base_color : Color = Color.WHITE
var palette : ColorHelper.PALETTES = ColorHelper.PALETTES.Monochromatic

@rpc("any_peer", "call_local", "reliable")
func set_colors(base:Color, p:int):
	base_color = base
	palette = p
	var colors : Array = ColorHelper.generate_palette(base, p, 3)
	for i in 3:
		color_rects[i].color = colors[i]
		name_ls[i].text = get_closest_color_name(colors[i])

func get_closest_color_name(color:Color)->String:
	return ColorHelper.closest_color(color).to_lower().capitalize()
