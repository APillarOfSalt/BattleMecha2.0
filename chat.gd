extends VBoxContainer

@onready var controller : Chat_Controller = Global.server_controller.chat
var player_num:int:
	get:return Global.server_controller.instance_id-1
var player_name : String = ""
var player_color : Color = Color.WHITE
@export var hide_title : bool = false
func _ready():
	controller.chat_added.connect(_on_chat_added)
	for c in controller.log:
		add_chat(c)
	$title.visible = !hide_title
	$disp/list/START.text = str(Time.get_ticks_msec())
@onready var list : Container = $disp/list
@onready var edit : TextEdit = $h/TextEdit
func send_chat(text:String):
	print('sending chat: "',text,'"; from:',player_name,".",player_num)
	controller.send_chat(text, player_num, player_name, player_color)
func _on_chat_added():
	var chat = controller.log.back()
	print('on controller chat added: "',chat.text,'"; from:',chat.player_name,".",chat.player_num)
	add_chat( chat )
func add_chat(chat:Chat_Controller.Chat):
	list.add_child( chat.get_label() )

func _on_send_pressed():
	send_chat(edit.text.strip_edges())
	edit.text = ""

func _on_conn_host_client_joined(iid):
	send_chat(str("Player ",iid," has joined the lobby"))
func _on_conn_host_client_left(iid):
	send_chat(str("Player ",iid," has left the lobby"))
func _on_conn_host_server_left():
	send_chat(str("Disconnected from lobby"))
