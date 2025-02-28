extends MarginContainer

class_name Cursor_Container

const textures : Array[Texture] = [
	preload("res://assets/mouse.png"),
	preload("res://assets/keyboard.png"),
	preload("res://assets/console-controller.png"),
	]


@onready var cursor : Cursor_Hover = $c
@onready var mod_manager : Cursor_Modules = $c/module_manager
signal new_map_pos(pos:Vector2i)

@export var map : TileMap = null:
	set(tilemap):
		map = tilemap
		if !is_inside_tree():
			await ready
var map_pos : Vector2i = Vector2i(-1,-1):
	set(pos):
		map_pos = pos
		new_map_pos.emit(pos)

var linked : Sprite2D = null #selected item or last item selected for return_to purposes
func _ready():
	for node in get_tree().get_nodes_in_group("input"):
		if node.get("num") == null:
			return
		if node.num == num:
			node.cursor.visible = node.input < input
			cursor.visible = !node.cursor.visible
			if node.cursor.visible:
				linked = node.cursor
			else:
				node.linked = cursor
@export var input : int:
	set(val):
		input = val
		if !is_inside_tree():
			await ready
		$tex.texture = textures[clamp(val,-1,1)+1]
		cursor.device = val
@export var num : int:
	set(val):
		num = val
		if !is_inside_tree():
			await ready
		$l.text = str(val)
var color : Color:
	set(col):
		color = col
		$tex.modulate = color
		cursor.self_modulate = color
		$anchor/Panel.self_modulate = color

const cursor_speed : float = 2.5
func _physics_process(_delta):
	cursor.refresh_hover()
	if linked != null:
		cursor.position = linked.position
	if input == -1:
		cursor.global_position = get_global_mouse_position()
	else:
		cursor.global_position += Vector2(input_map[2], input_map[3]) * cursor_speed
	#if map is TileMap:
		#map_pos = map.local_to_map( map.to_local( cursor.global_position ) )
		#$c/hex.global_position = map.to_global( map.map_to_local(map_pos) )

var input_map : Dictionary = {
	JOY_AXIS_LEFT_X : 0.0, #L-Stick X
	JOY_AXIS_LEFT_Y : 0.0, #L-Stick Y
	JOY_AXIS_RIGHT_X : 0.0, #R-Stick X
	JOY_AXIS_RIGHT_Y : 0.0, #R-Stick Y
	JOY_AXIS_TRIGGER_LEFT : 0.0, #L Trigger
	JOY_AXIS_TRIGGER_RIGHT : 0.0, #R Trigger
}

var ui_accept : bool = false:
	set(toggle):
		ui_accept = toggle
		accept(toggle)
func accept(is_pressed:bool):
	if is_pressed:
		for nd in cursor.hovering:
			if nd is Button:
				nd.button_pressed = !nd.button_pressed
				return
			elif nd.has_method("_cursor_accept"):
				if nd._cursor_accept(self):
					return
		accept_pressed.emit()
	else:
		accept_released.emit()
signal accept_pressed()
signal accept_released()


var ui_cancel : bool = false:
	set(toggle):
		ui_cancel = toggle
		cancel(toggle)
func cancel(is_pressed:bool):
	if is_pressed:
		for nd in cursor.hovering:
			if nd.has_method("_cursor_cancel"):
				nd._cursor_cancel(self)
				return
		cancel_pressed.emit()
	else:
		cancel_released.emit()
signal cancel_pressed()
signal cancel_released()




func _input(event):
	if event is InputEventJoypadMotion and event.device + 1 == input:
		input_map[event.axis] = event.axis_value
	elif event is InputEventJoypadButton and event.device + 1 == input:
		handle_joy(event)
	elif event is InputEventKey and input == 0:
		handle_key(event)
	elif event is InputEventMouseButton and input == -1:
		handle_mouse(event)
func handle_joy(event:InputEventJoypadButton):
	if event.button_index == JOY_BUTTON_A and event.pressed != ui_accept:
		ui_accept = event.pressed
	elif event.button_index == JOY_BUTTON_B and event.pressed != ui_cancel:
		ui_cancel = event.pressed
func handle_key(event:InputEventKey):
	if event.keycode == KEY_E and event.pressed != ui_accept:
		ui_accept = event.pressed
	elif event.keycode == KEY_Q and event.pressed != ui_cancel:
		ui_cancel = event.pressed
func handle_mouse(event:InputEventMouseButton):
	if event.button_index == MOUSE_BUTTON_LEFT and event.pressed != ui_accept:
		ui_accept = event.pressed
	elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed != ui_cancel:
		ui_cancel = event.pressed
