extends Container

@export var button_accepts_input : bool = true
@export var mouse_display : bool = false
func _ready():
	if button_accepts_input:
		add_to_group("input")
		add_to_group("module_display")
	$Button.mouse_filter = [MOUSE_FILTER_STOP, MOUSE_FILTER_IGNORE][int(mouse_display)]

var module : Module_Data = null:
	set(mod):
		module = mod
		var mod_name = ""
		var mod_shape = "0000000000000000"
		visible = mod != null
		if mod != null:
			mod_name = mod.name
			mod_shape = mod.shape
			$h/tex.texture = Global.type_textures[Global.type_from_str(mod.subtype)]
		$h/name/m/Label.text = mod_name
		$h/shape_disp.data = mod_shape

func _cursor_accept(controller:Cursor_Container):
	controller.mod_manager.grab_module(module)

func _on_button_up():
	$Button.button_pressed = false

func _input(event):
	if event.is_action_released("lmb") and $Button.button_pressed:
		$Button.button_pressed = false

