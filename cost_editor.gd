extends VBoxContainer

var is_complete : bool = false
signal complete(is_done:bool)
signal new_value(s:String)

var disabled : bool = false:
	set(toggle):
		disabled = toggle
		$Label.text = str(toggle)
		if disabled:
			for i in VAR_NAMES:
				get_node(str("input/butts/",i,"_m")).disabled = true
				get_node(str("input/butts/",i,"_p")).disabled = true
		else:
			refresh()

#0+ limits -1, means no limits
@export var allow_inverted : bool = false
@export var total_allowed : int = 0:
	set(val):
		total_allowed = val
		refresh()
@export var individual_total_limit : int = 0
var no_limit : bool = false
var lim_is_pos : bool = true

func _ready():
	refresh()
func refresh():
	if data == null:
		return
	individual_total_limit = abs(individual_total_limit)
	no_limit = total_allowed == 0
	lim_is_pos = total_allowed >= 0
	$title/remaining/total.visible = total_allowed != 0
	$title/remaining/total/p/m/Label.text = str(total_allowed - total)
	$title/max.visible = bool(individual_total_limit)
	$title/max/m/Label.text = str("Max : ",individual_total_limit)
	if individual_total_limit or total == total_allowed:
		if total == total_allowed:
			complete.emit(true)
			is_complete = true
		for i in VAR_NAMES:
			var s : String = "_m"
			if lim_is_pos:
				s = "_p"
			var disable : bool = abs(self[i]) == individual_total_limit or total == total_allowed
			get_node(str("input/butts/",i,s)).disabled = disable or disabled
	if total < total_allowed and is_complete:
		complete.emit(false)
		is_complete = false
	if !allow_inverted:
		for i in VAR_NAMES:
			var s : String = "_p"
			if lim_is_pos:
				s = "_m"
			var disable : bool = abs(self[i]) == 0
			get_node(str("input/butts/",i,s)).disabled = disable or disabled

const VAR_NAMES : Array[String] = ["ti","ga","al","co"]
@onready var data : Cost_Data = $cost
@export var ti : int:
	set(val):
		if not is_inside_tree():
			await ready
		data.titanium = val
	get: return data.titanium
@export var ga : int:
	set(val):
		if not is_inside_tree():
			await ready
		data.gallium = val
	get: return data.gallium
@export var al : int:
	set(val):
		if not is_inside_tree():
			await ready
		data.aluminum = val
	get: return data.aluminum
@export var co : int:
	set(val):
		if not is_inside_tree():
			await ready
		data.cobalt = val
	get: return data.cobalt
var total : int:
	get: return  ti + ga + al + co

func set_vals(res:Dictionary):
	data.set_cost(res)
	refresh()
func get_vals()->Dictionary:
	return {
		"titanium" : ti,
		"gallium" : ga,
		"aluminum" : al,
		"cobalt" : co,
	}

#dir == false:-1, true:+1
func set_val(id:int, dir:bool):
	var current : int = [ti,ga,al,co][id]
	var operand : int = int(dir)-int(!dir)
	var new : int = current + operand
	#if range is up to +#A
	if lim_is_pos:
		if dir and total >= total_allowed:
			return
		elif !dir and total < 0 and !allow_inverted:
			return
		if new < 0 and !allow_inverted:
			return
		elif dir and new > individual_total_limit and individual_total_limit:
			return
	#if range is down to -#B
	elif !lim_is_pos:
		if !dir and total <= total_allowed:
			return
		elif dir and total > 0 and !allow_inverted:
			return
		if new > 0 and !allow_inverted:
			return
		elif !dir and new < -individual_total_limit and individual_total_limit:
			return
	self[VAR_NAMES[id]] += operand
	refresh()
	new_value.emit(VAR_NAMES[id])

func _on_ti_m_pressed():
	set_val(0,false)
func _on_ti_p_pressed():
	set_val(0,true)

func _on_ga_m_pressed():
	set_val(1,false)
func _on_ga_p_pressed():
	set_val(1,true)

func _on_al_m_pressed():
	set_val(2,false)
func _on_al_p_pressed():
	set_val(2,true)

func _on_co_m_pressed():
	set_val(3,false)
func _on_co_p_pressed():
	set_val(3,true)
