extends Node

enum COL{bg=0,text=1,fg=2}
const COL_STRINGS : Array = ["bgcolor", "color", "fgcolor"]
func color_text(text:String,color:Color,bg_text_fg:COL=COL.text)->String:
	var col_string : String = ColorHelper.color_to_hex_string(color)
	var access : String = COL_STRINGS[bg_text_fg]
	return str("[",access,"=#",col_string,"]",text,"[/",access,"]")
func outline_text(text:String, color:Color, width:int=1):
	var col_string : String = ColorHelper.color_to_hex_string(color)
	return str("[outline_size=",width,"][outline_color=#",col_string,"]",text,"[/outline_color][/outline_size]")
func bold_text(text:String)->String:
	return _bb_simple(text,"b")
func italic_text(text:String)->String:
	return _bb_simple(text,"i")
func underline_text(text:String)->String:
	return _bb_simple(text,"u")
func strikethrough_text(text:String)->String:
	return _bb_simple(text,"s")
func _bb_simple(text:String,i:String)->String:
	return str("[",i,"]",text,"[/",i,"]")

func unformat(bb_text:String):
	var result : String = ""
	var inside_bb_tag : bool = false
	for cha in bb_text:
		if cha == "[":
			inside_bb_tag = true
		elif cha == "]":
			inside_bb_tag = false
		elif !inside_bb_tag:
			result += cha
	return result.strip_edges()
