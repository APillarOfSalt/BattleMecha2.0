extends Button

class_name Option_Button

signal item_selected(index:int)

@export var items : Array[String] = []
@export var colors : Array[Color] = []

@export var default_item_text_color : Color = Color.WHITE

@onready var anchor = $anchor
@onready var anchor_panel = $anchor/p
@onready var list : Container = $anchor/p/list:
	set(nd):
		list = nd

var data : Array[item_data]
var item_count : int:
	get:
		return data.size()
var selected_id : int: #generated value
	set(val):
		selected = get_item_index(val)
	get: return get_item_id(selected)


func get_item_id(index:int):
	if index < 0  or data.size() <= index:
		return -1
	return data[index].id
func get_item_index(id:int):
	for i in data.size():
		if data[i].id == id:
			return i
	return -1
func get_item_text(index:int):
	return data[index].text

@export var min_size := Vector2(0,0)
func _ready():
	#Cursors.control_focus_changed.connect(_on_focus_changed)
	skip_refresh = -1
	for i in items.size():
		var color : Color = default_item_text_color
		if colors.size() > i:
			color = colors[i]
		else:
			colors.append(color)
		add_item(items[i],i, color)
	skip_refresh = 0
	min_sizing.call_deferred()
	set_focus_neighbors.call_deferred()

func clear():
	skip_refresh = 0
	while data.size():
		remove_item(0)
	selected = -1
	anchor_panel.custom_minimum_size = Vector2(0,0)
	size = Vector2(0,0)
	anchor_panel.size = Vector2(0,0)

@export var selected : int = -1:
	set(val):
		if data.size() == 0:
			selected = -1
		if selected != -1:
			data[selected].button.icon = data[selected].icon_off
		if get_is_popped():
			grab_focus.call_deferred()
			hide_popup()
		if selected == val:
			return
		selected = val
		item_selected.emit(val)
		text = " "
		if selected != -1 and data.size():
			data[selected].button.icon = data[selected].icon_on
			text = data[selected].text
			var hsv : Vector4 = Global.rgb_to_hsv(data[selected].color)
			var color_dark : Color = Color.from_hsv(hsv.x, hsv.y, hsv.z-0.1, hsv.w)
			add_theme_color_override("font_color", color_dark)
			add_theme_color_override("font_hover_color", data[selected].color)
			add_theme_color_override("font_focus_color", data[selected].color)

func get_is_popped()->bool:
	return anchor.visible

var no_doubles : bool = false
func hide_popup():
	anchor.hide()
	no_doubles = true
	await Global.create_wait_timer(0)
	no_doubles = false
func _on_pressed():
	show_popup()
func show_popup():
	if no_doubles:
		no_doubles = false
		return
	anchor.global_position = global_position
	if item_count == 0:
		return false
	if highlighted_index == -1:
		highlighted_index = 0
	data[highlighted_index].button.grab_focus()
	anchor.show()
func dont_size_down():
	custom_minimum_size.x = max(anchor_panel.size.x, size.x)
	self.text = " "

var highlighted_index : int = -1:
	set(index):
		if highlighted_index != -1:
			highlight_item(highlighted_index, false)
		highlighted_index = index
		if index != -1:
			highlight_item(index, true)
	get:
		for i in item_count:
			if data[i].button.icon == data[i].icon_on:
				return i
		return -1

func set_focused_item(index:int):
	highlighted_index = index
func get_focused_item()->int:
	return highlighted_index

func highlight_item(index:int, _on:bool):
	var butt : Button = data[index].button
	if butt.button_pressed:
		butt.add_theme_stylebox_override("hovered", press_hover_stylebox)
	else:
		butt.add_theme_stylebox_override("hovered", hovered_stylebox)


#-1 dont refresh on add
#0 default behavior
#1 skip next 1 add then decrement
var skip_refresh : int = 0
func add_item(txt:String, id:int=-1, text_color:Color=default_item_text_color, icon_on_override:Texture=default_icon_on, icon_off_override:Texture=default_icon_off):
	var butt : Button = Button.new()
	butt.toggle_mode = true
	butt.toggled.connect(_on_butt_pressed)
	butt.mouse_entered.connect(_on_butt_hovered)
	butt.focus_entered.connect(_on_butt_focused)
	butt.text = txt
	butt.add_theme_color_override("font_color", text_color)
	butt.add_theme_color_override("font_hover_color", text_color)
	butt.add_theme_color_override("font_pressed_color", text_color)
	list.add_child(butt)
	butt.add_to_group("input")
	if id == -1:
		id = item_count
	data.append( item_data.new(id, txt, text_color, butt, icon_on_override, icon_off_override) )
	butt.icon = icon_off_override
	if item_count-1 == selected:
		butt.button_pressed = true
		butt.icon = icon_on_override
	if skip_refresh == 0:
		min_sizing()
		set_focus_neighbors()
	elif skip_refresh > 0:
		skip_refresh -= 1
func remove_item(index:int):
	if item_count:
		index = index_modulo(index)
		data[index].button.name = "oh_no"
		data[index].button.queue_free()
		data.remove_at(index)

func index_modulo(index:int):
	if item_count:
		return (index + item_count) % item_count
	return 0

const default_icon_on : Texture = preload("res://godot_sucks_ass/option_menu_pip_filled.png")
const default_icon_off : Texture = preload("res://godot_sucks_ass/option_menu_pip_empty.png")
const normal_stylebox : StyleBox = preload("res://godot_sucks_ass/normal.tres")
const hovered_stylebox : StyleBox = preload("res://godot_sucks_ass/hovered.tres")
const pressed_stylebox : StyleBox = preload("res://godot_sucks_ass/pressed.tres")
const press_hover_stylebox : StyleBox = preload("res://godot_sucks_ass/pressed_hovered.tres")

func min_sizing():
	var fuck_godot : int = anchor_panel.size.x
	if icon != null:
		fuck_godot += icon.get_width()
	var m : int = max( min_size.x, max(size.x, fuck_godot) )
	custom_minimum_size.y = max(custom_minimum_size.y, min_size.y)
	custom_minimum_size.x = m
	anchor_panel.custom_minimum_size.x = m
	hide_popup.call_deferred()
	anchor.set_modulate.call_deferred(Color.WHITE)
	hide_popup()

class item_data:
	extends Resource
	var id : int = -1
	var text : String = ""
	var color : Color
	var button : Button = null
	var icon_on : Texture = null
	var icon_off : Texture = null
	func _init(i:int, txt:String, col:Color, butt:Button, on:Texture, off:Texture):
		id = i
		text = txt
		color = col
		button = butt
		icon_on = on
		icon_off = off

func _on_butt_hovered():
	if item_count == 0:
		return -1
	for i in item_count:
		if data[i].button.get_rect().has_point(data[i].button.get_local_mouse_position()):
			highlighted_index = i

func _on_butt_pressed(toggle:bool):
	if item_count == 0 or !toggle:
		return -1
	for i in item_count:
		if data[i].button.button_pressed:
			data[i].button.button_pressed = false
			selected = i

func _on_butt_focused():
	if item_count == 0:
		return
	for i in item_count:
		if data[i].button.has_focus():
			highlighted_index = i

func _on_focus_changed(control:Control):
	if has_focus():
		return
	for butt:Button in list.get_children():
		if butt.has_focus():
			return
	if control == self or get_is_popped():
		if item_count:
			text = data[selected].text
		hide_popup()

func set_focus_neighbors():
	var count : int = list.get_child_count()
	for i in count:
		var above : Button = list.get_child( (i + count-1) % count )
		var this : Button = list.get_child(i)
		var below : Button = list.get_child( (i + 1) % count )
		above.focus_neighbor_bottom = this.get_path()
		above.focus_next = this.get_path()
		this.focus_previous = above.get_path()
		this.focus_neighbor_bottom = below.get_path()
		this.focus_neighbor_top = above.get_path()
		this.focus_next = below.get_path()
		below.focus_previous = this.get_path()
		below.focus_neighbor_top = this.get_path()

