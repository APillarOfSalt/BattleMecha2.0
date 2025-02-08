extends Node

const is_debug : bool = false

var server_controller : Server_Controller
var cursor_controller : Cursor_Controller
func _init():
	server_controller = preload("res://server_controller.tscn").instantiate()
	add_child(server_controller)
	cursor_controller = preload("res://cursor_controller.tscn").instantiate()
	add_child(cursor_controller)

func to_main_menu_scene():
	get_tree().change_scene_to_file("res://main_menu.tscn")

var local_player : int = -1
var player_info_by_num : Dictionary = {}

enum types{ Module=1, Shield=2, Weapon=3,
	Untyped=10, Hull_up=11, Armor=12, Shield_up=13,
	Harmonic=20, Hardlight=21, Magnetic=22,
	None=30, Melee=31, Rifle=32, Cannon=33, Launcher=34, Laser=35, Coil=36 }
const type_strings : Dictionary = {
	types.Module:	"Module",
	types.Shield:	"Shield",
	types.Weapon:	"Weapon",
	types.Untyped:	"Untyped",
	types.Hull_up:	"Hull Upgrade",
	types.Armor:	"Armor",
	types.Shield_up:"Shield Mount",
	types.Harmonic: "Harmonic",
	types.Hardlight:"Hardlight",
	types.Magnetic: "Magnetic",
	types.None: 	"None",
	types.Melee:	"Melee",
	types.Rifle:	"Rifle",
	types.Cannon:	"Cannon",
	types.Launcher: "Launcher",
	types.Laser:	"Laser",
	types.Coil: 	"Coil",
}
func type_from_str(type_str:String)->int:
	for i in type_strings.keys():
		if type_strings[i] == type_str:
			return i
	return -1
const type_textures : Dictionary = {
	types.Module:		preload("res://assets/processor.png"),
	types.Shield:		preload("res://assets/armor-upgrade.png"),
	types.Weapon:		preload("res://assets/shotgun.png"),
	types.Untyped:		preload("res://assets/processor.png"),
	types.Hull_up:		preload("res://assets/hp.png"),
	types.Armor:		preload("res://assets/shoulder-armor.png"),
	types.Shield_up:	preload("res://assets/armor-upgrade.png"),
	types.Harmonic: 	preload("res://assets/shield-echoes.png"),
	types.Hardlight:	preload("res://assets/temporary-shield.png"),
	types.Magnetic: 	preload("res://assets/bolt-shield.png"),
	types.None: 		preload("res://assets/shotgun.png"),
	types.Melee:		preload("res://assets/pv.png"),
	types.Rifle:		preload("res://assets/rifle.png"),
	types.Cannon:		preload("res://assets/pc.png"),
	types.Launcher: 	preload("res://assets/grenade.png"),
	types.Laser:		preload("res://assets/laser-gun.png"),
	types.Coil: 		preload("res://assets/laser-gun.png"),
}

func vec_from_json(json:String):
	match json.count(","):
		1: return vec2_from_json(json)
		2: return vec3_from_json(json)
		3: return vec4_from_json(json)
	return null
func vec2_from_json(json:String)->Vector2:
	var arr : Array = json.replace("(","").replace(")","").strip_edges().split(",")
	var x = arr[0].to_float()
	var y = arr[1].to_float()
	return Vector2(x,y)
func vec3_from_json(json:String)->Vector3:
	var arr : Array = json.replace("(","").replace(")","").strip_edges().split(",")
	var x = arr[0].to_float()
	var y = arr[1].to_float()
	var z = arr[2].to_float()
	return Vector3(x,y,z)
func vec4_from_json(json:String)->Vector4:
	var arr : Array = json.replace("(","").replace(")","").strip_edges().split(",")
	var x = arr[0].to_float()
	var y = arr[1].to_float()
	var z = arr[2].to_float()
	var w = arr[3].to_float()
	return Vector4(x,y,z,w)

#										up			up right	down right		down		down left		up left
const directions_evenx : Array = [Vector2i(0,-1), Vector2i(1,-1),Vector2i(1,0),Vector2i(0,1),Vector2i(-1,0),Vector2i(-1,-1)]
const directions_oddx : Array = [Vector2i(0,-1), Vector2i(1,0),Vector2i(1,1),Vector2i(0,1),Vector2i(-1,1),Vector2i(-1,0)]

func get_relative(x:float,dir:int)->Vector2i:
	return [directions_evenx,directions_oddx][int(x) % 2][dir]
#directions : 0up, 1ur, 2dr, 3down, 4dl, 5ul
func dir_from_vec(vec:Vector2)->float:
	var angle : float = vec.angle() #0rad == Vec2(1,0)
	return ( angle+PI ) / ( PI/3.0 )


enum WRAPS{
	up  	=0xF0000,	#0b 1111 0000 0000 0000,
	right 	=0x11110,	#0b 0001 0001 0001 0001,
	down	=0x000F0,	#0b 0000 0000 0000 1111,
	left	=0x88880,	#0b 1000 1000 1000 1000,
	down5	=0x0000F,	#0b 0000 0000 0000 0000 1111
}
func translate_binary_string_bitwise(binary_string: String, trans: Vector2i, y5:bool=false) -> String:
	assert(binary_string.length() == 16 or binary_string.length() == 20, "Binary string must have exactly 16 or 20 digits.")
	for i in 20 - binary_string.length():
		binary_string += "0"
	var binary_number = binary_string.bin_to_int()
	for _i in abs(trans.x):
		# Check if right shift causes wrap-around
		if trans.x > 0 and binary_number & WRAPS.right != 0:  # Right shift
			return "Error"  # Bits in the leftmost column would be lost
		# Check if left shift causes wrap-around
		elif trans.x < 0 and binary_number & WRAPS.left != 0:  # Left shift
			return "Error"  # Bits in the rightmost column would be lost
		binary_number >>= int(trans.x > 0)
		binary_number <<= int(trans.x < 0)
	# Vertical Translation (Up or Down)
	for _i in abs(trans.y):
		# Check if down shift causes wrap-around
		if trans.y > 0 and y5 and binary_number & WRAPS.down5 != 0:
			return "Error"
		elif trans.y > 0 and !y5 and binary_number & WRAPS.down != 0:  # Down shift
			return "Error"
		# Check if up shift causes wrap-around
		elif trans.y < 0 and binary_number & WRAPS.up != 0:
			return "Error" # Bottom row would be lost
		binary_number >>= 4 * int(trans.y > 0)
		binary_number <<= 4 * int(trans.y < 0) # Up shift
	var bin : String = to_binary(binary_number)
	var leng : int = 16 + ( int(y5) * 4 )
	while bin.length() < leng:
		bin = bin+"0"
	return bin

func to_binary(intValue: int) -> String:
	var bin_str: String = ""
	for i in 20:
		bin_str += str(intValue & 1)
		if intValue > 0:
			intValue = intValue >> 1
	return bin_str.reverse()

func isolate_in_shape(shape:String, isolate:String)->String:
	assert(isolate.length() == 1, "Isolated character must be singluar.")
	var pulled_shape : String = ""
	for i in shape.length():
		if shape[i] != isolate:
			pulled_shape += isolate
		else:
			pulled_shape += "0"
	return pulled_shape

func get_shape_without(shape:String, isolate:String)->String:
	assert(isolate.length() == 1, "Isolated character must be singluar.")
	shape = shape.replace(isolate,"0")
	var final : String = ""
	for i in shape.length():
		final += str(shape[i].to_int() - int(shape[i].to_int() > isolate.to_int()))
	return final


func int_to_hex(val:int)->String:
	return ("%02x" % val).to_upper()

func color_from_json(col_string:String, default:Color=Color.BLACK)->Color:
	var color : Color = default
	var split : Array = col_string.split(",")
	for i in min(split.size(),4):
		color[i] = split[i].replace("(","").replace(")","").to_float()
	return color

# Function to convert RGB to HSV
func rgb_to_hsv(color : Color) -> Vector4:
	var r : float = color.r
	var g : float = color.g
	var b : float = color.b
	var v : float = max(r, g, b)
	var min_c : float = min(r, g, b)
	var delta : float = v - min_c
	var h : float = 0.0
	if delta:
		if v == r:
			h = (g - b) / delta
		elif v == g:
			h = 2.0 + (b - r) / delta
		else:
			h = ( 4.0 + (r - g) / delta )
		h *= 60.0
		if h < 0.0:
			h += 360.0
	var s : float = ( delta / v ) * sign(v)
	return Vector4(h/360.0, s, v, color.a)

func hue_shift(color:Color, deg:float) -> Color:
	var hsv = rgb_to_hsv(color)
	hsv[0] += deg
	return Color.from_hsv(hsv[0], hsv[1], hsv[2], hsv[3])

func even_colors(num:int, start:Color=Color.RED) -> PackedColorArray:
	var hsv : Vector4 = rgb_to_hsv(start)
	var ret : Array = []
	for i in num:
		var ii : float = float(i) / float(num)
		var hsv2 : Vector4 = hsv + Vector4(ii,0.0,0.0,0.0)
		ret.push_back( Color.from_hsv(hsv2[0], hsv2[1], hsv2[2], hsv2[3]) )
	return PackedColorArray(ret)

func mix_colors(a:Color, b:Color)->Color:
	var ahsv : Vector4 = rgb_to_hsv(a)
	var bhsv : Vector4 = rgb_to_hsv(b)
	var hue_diff : float = ahsv.x - bhsv.x
	if hue_diff > 0.5: #a.hue < b.hue
		ahsv.x += 1.0
	elif hue_diff < -0.5: #b.hue < a.hue
		bhsv.x += 1.0
	var hsv := (ahsv+bhsv) * 0.5
	return Color.from_hsv(hsv.x-floor(hsv.x), hsv.y, hsv.z, hsv.w)

func col_to_hex(col:Color)->String:
	var r : int = floor(col.r * 255.0)
	var g : int = floor(col.g * 255.0)
	var b : int = floor(col.b * 255.0)
	return str( "#", int_to_hex(r), int_to_hex(g), int_to_hex(b) )

func get_contrasting_greyscale_text_color(input_color:Color)->Color:
	var threshold : float = 0.03928
	var lum := Vector3(0,0,0)
	for i in 3:
		if input_color[i] <= threshold:
			lum[i] = input_color[i] / 12.92
		else:
			lum[i] = pow((input_color[i] + 0.055) / 1.055, 2.4)
	lum *= Vector3(0.2126, 0.7152, 0.0722)
	var luminance : float = lum.x + lum.y + lum.z
	var a : float = luminance + 0.5 - int(luminance > 0.5)
	return Color(a,a,a, 1.0)



func get_absolute_z_index(node)->int:
	var z : int = 0
	while node:
		if !node.get("z_index") is int:
			return z
		z += node.z_index
		if !node.z_as_relative:
			break
		node = node.get_parent()
	return z

func get_unique(arr:Array)->Array:
	var unique : Array = []
	for i in arr:
		if !i in unique:
			unique.append(i)
	return unique
func get_uniquev(arr_arr:Array, include_upper:bool=false)->Array:
	var unique : Array = []
	for arr in arr_arr:
		if arr is Array:
			for i in arr:
				if !i in unique:
					unique.append(i)
		elif include_upper:
			if !arr in unique:
				unique.append(arr)
	return unique

func arr_max(arr:Array):
	var m = null
	for i in arr:
		if i is int or i is float:
			if m == null:
				m = i
			else:
				m = max(m,i)
	return m
func arr_min(arr:Array):
	var m = null
	for i in arr:
		if i is int or i is float:
			if m == null:
				m = i
			else:
				m = min(m,i)
	return m
