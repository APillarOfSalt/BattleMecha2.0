extends Node

const DEFAULT_GRAY : Color = Color(0.75,0.75,0.75,1.0)

var g2r : PackedColorArray
func _init():
	g2r = lerp_between(Color(0,1,0,1), Color(1,0,0,1), 4)

func fract(val:float)->float:
	return val - floor(val)
func lratio(val:float, total:float, scale:float):
	return ( val / total ) * scale

func compliment(col:Color)->Color:
	var hsv : Vector4 = rgb_to_hsv(col)
	hsv.x = fract(hsv.x + 0.5)
	return Color.from_hsv(hsv.x,hsv.y,hsv.z)

func adjacent(col:Color, weight_deg:int=0, dir:int=-1)->Color:
	var hsv : Vector4 = rgb_to_hsv(col)
	weight_deg = clamp(weight_deg,-15,15)
	var thirty : int = 30*sign(weight_deg)
	if thirty == 0:
		thirty = 30*dir
	hsv.x += float( thirty + weight_deg ) / 360.0
	return Color.from_hsv(hsv.x,hsv.y,hsv.z)

enum PALETTES{Monochromatic, Complimentary, Tricolor_Adjacent, Tricolor_Triad, Tetrad_0, Tetrad_1, MAX}
const PALETTE_NAMES : Array[String] = [
	"Monochromatic", "Complimentary", "Tricolor_Adjacent", "Tricolor_Triad", "Tetrad_0", "Tetrad_1"
]
func generate_palette(col:Color, pal:int, force_num:int=2, deg=null)->Array[Color]:
	var p : Array[Color] = [col]
	var r : int
	if deg is int or deg is float:
		r = int(deg)
	else:
		r = randi_range(0,15)
	match pal:
		PALETTES.Complimentary:
			p.append(compliment(col))
		PALETTES.Tricolor_Adjacent:
			for i in [-1.0,1.0]:
				p.append(adjacent(col, r*i, i))
		PALETTES.Tricolor_Triad:
			var c2 : Color = compliment(col)
			for i in [-1.0,1.0]:
				p.append(adjacent(c2, r*i, i))
		PALETTES.Tetrad_0:
			var c2 : Color = compliment(col)
			p.append(c2)
			for i in [col,c2]:
				p.append(adjacent(i, r, 1))
		PALETTES.Tetrad_1:
			var c2 : Color = compliment(col)
			p.append(c2)
			for i in [col,c2]:
				p.append(adjacent(i, -r, -1))
	var num : int = max(0, force_num - p.size() )+1 #example
	var step : float = 1.0 / float(num) 			#	step = 10
	var col_val : float = rgb_to_hsv(col).z			#	col_val =8
	var val_offset : float = fmod(col_val, step)	#	8%10=8
	if step - val_offset < val_offset:				#	10-8 < 8:
		val_offset = val_offset - step   			#		8 - 10 = -2
	for i in num: # t == PALETTES.Monochromatic
		var value : float = float(i+1) / float(num)
		value += val_offset
		if value >= col_val: #this is the current color
			col_val = 2.0
		else:
			var hsv : Vector4 = rgb_to_hsv(col)
			hsv.z = value
			p.append(Color.from_hsv(hsv.x,hsv.y,hsv.z))
	return p


func color_to_hex_string(color:Color)->String:
	var hex_str : String = "%08X" % color.to_rgba32()
	return hex_str


func even_hues(num:int, start:Color=Color.RED) -> Array[Color]:
	var arr : Array[Color] = []
	var s : Vector4 = rgb_to_hsv(start)
	var math : float = 1.0 / num
	for i in num:
		var h : float = s.x + (i*math)
		var newColor : Color = Color.from_hsv( fract(h), s.y, s.z )
		newColor.a = start.a
		arr.append(newColor)
	return arr

func rgb_to_hsv(c: Color) -> Vector4:
	var v = max(c.r, max(c.g, c.b))
	var delta = v - min(c.r, min(c.g, c.b))
	var h = 0.0
	if delta != 0.0:
		if v == c.r:
			h = (c.g - c.b) / delta
			h += 6.0 * float(c.g < c.b)
		elif v == c.g:
			h = ((c.b - c.r) / delta)
			h += 2.0
		elif v == c.b:
			h = ((c.r - c.g) / delta)
			h += 4.0
	h /= 6.0
	h += int(h < 0.0)
	return Vector4(h, delta / v, v, c.a)

const color_names : Array = ["ALICE_BLUE","ANTIQUE_WHITE","AQUA","AQUAMARINE","AZURE","BEIGE","BISQUE","BLACK","BLANCHED_ALMOND","BLUE","BLUE_VIOLET","BROWN","BURLYWOOD","CADET_BLUE","CHARTREUSE","CHOCOLATE","CORAL","CORNFLOWER_BLUE","CORNSILK","CRIMSON","CYAN","DARK_BLUE","DARK_CYAN","DARK_GOLDENROD","DARK_GRAY","DARK_GREEN","DARK_KHAKI","DARK_MAGENTA","DARK_OLIVE_GREEN","DARK_ORANGE","DARK_ORCHID","DARK_RED","DARK_SALMON","DARK_SEA_GREEN","DARK_SLATE_BLUE","DARK_SLATE_GRAY","DARK_TURQUOISE","DARK_VIOLET","DEEP_PINK","DEEP_SKY_BLUE","DIM_GRAY","DODGER_BLUE","FIREBRICK","FLORAL_WHITE","FOREST_GREEN","FUCHSIA","GAINSBORO","GHOST_WHITE","GOLD","GOLDENROD","GRAY","GREEN","GREEN_YELLOW","HONEYDEW","HOT_PINK","INDIAN_RED","INDIGO","IVORY","KHAKI","LAVENDER","LAVENDER_BLUSH","LAWN_GREEN","LEMON_CHIFFON","LIGHT_BLUE","LIGHT_CORAL","LIGHT_CYAN","LIGHT_GOLDENROD","LIGHT_GRAY","LIGHT_GREEN","LIGHT_PINK","LIGHT_SALMON","LIGHT_SEA_GREEN","LIGHT_SKY_BLUE","LIGHT_SLATE_GRAY","LIGHT_STEEL_BLUE","LIGHT_YELLOW","LIME","LIME_GREEN","LINEN","MAGENTA","MAROON","MEDIUM_AQUAMARINE","MEDIUM_BLUE","MEDIUM_ORCHID","MEDIUM_PURPLE","MEDIUM_SEA_GREEN","MEDIUM_SLATE_BLUE","MEDIUM_SPRING_GREEN","MEDIUM_TURQUOISE","MEDIUM_VIOLET_RED","MIDNIGHT_BLUE","MINT_CREAM","MISTY_ROSE","MOCCASIN","NAVAJO_WHITE","NAVY_BLUE","OLD_LACE","OLIVE","OLIVE_DRAB","ORANGE","ORANGE_RED","ORCHID","PALE_GOLDENROD","PALE_GREEN","PALE_TURQUOISE","PALE_VIOLET_RED","PAPAYA_WHIP","PEACH_PUFF","PERU","PINK","PLUM","POWDER_BLUE","PURPLE","REBECCA_PURPLE","RED","ROSY_BROWN","ROYAL_BLUE","SADDLE_BROWN","SALMON","SANDY_BROWN","SEA_GREEN","SEASHELL","SIENNA","SILVER","SKY_BLUE","SLATE_BLUE","SLATE_GRAY","SNOW","SPRING_GREEN","STEEL_BLUE","TAN","TEAL","THISTLE","TOMATO","TRANSPARENT","TURQUOISE","VIOLET","WEB_GRAY","WEB_GREEN","WEB_MAROON","WEB_PURPLE","WHEAT","WHITE","WHITE_SMOKE","YELLOW","YELLOW_GREEN"]
func closest_color(color:Color, include_dist:bool=false)->String:
	var n : Vector3 = Vector3(color.r, color.g, color.b)
	var closest : String
	var min_dist : float = 2.0
	for color_name in color_names:
		var col : Color = Color(color_name)
		var c : Vector3 = Vector3(col.r, col.g, col.b)
		var dist = n.distance_to(c)
		if dist < min_dist:
			min_dist = dist
			closest = color_name
	if include_dist:
		return str(closest,",",min_dist)
	return closest

func lerp_between(col0:Color, col1:Color, num:int)->PackedColorArray:
	var hsva0 : Vector4 = rgb_to_hsv(col0)
	var hsva1 : Vector4 = rgb_to_hsv(col1)
	var sat_range : float = hsva1.y - hsva0.y
	var val_range : float = hsva1.z - hsva0.z
	var alp_range : float = hsva1.w - hsva0.w
	var diff0 : float = abs(hsva0.x - hsva1.x) #always negative
	var diff1 : float = abs(1 - hsva0.x - hsva1.x) #always positive
	var hue_range : float = min(diff0,diff1)
	if diff0 < diff1: #false: cw↻ add hue, true: ccw↺ subtract hue
		hue_range = -hue_range
	var cols : Array[Color] = []
	for i in num:
		var h : float = fract(1 + lratio(i, num-1, hue_range) + hsva0.x )
		var s : float = lratio(i, num-1, sat_range) + hsva0.y
		var v : float = lratio(i, num-1, val_range) + hsva0.z
		var a : float = lratio(i, num-1, alp_range) + hsva0.w
		cols.append(Color.from_hsv(h,s,v,a))
	return PackedColorArray( cols )
