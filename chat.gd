extends VBoxContainer

@onready var controller : Chat_Controller = Global.server_controller.chat
var player_num:int:
	get:return Global.server_controller.instance_id-1
var player_name : String = ""
var player_color : Color = Color.WHITE

func _ready():
	$disp/list/START.text = str(Time.get_ticks_msec())
@onready var list : Container = $disp/list
@onready var edit : TextEdit = $h/TextEdit
func send_chat(text:String):
	controller.send_chat(text, player_num, player_name, player_color)

func add_chat(l:RichTextLabel):
	list.add_child(l)

func _on_send_pressed():
	send_chat(edit.text.strip_edges())
	edit.text = ""
