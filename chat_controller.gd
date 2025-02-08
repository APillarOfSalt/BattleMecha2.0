extends Node
class_name Chat_Controller

class Chat:
	var text : String = ""
	var peer_id : int = -1
	var player_num : int = -1
	var player_name : String = ""
	var player_color : Color = Color.WHITE
	var local_send_time : String = ""
	var utc_send_time : String = ""
	var local_receive_time : String = "Sender"
	var utc_receive_time : String = "Sender"
	func _init(txt:String,uid:int,num:int,named:String,color:Color,send_recieve:bool,local:String="Sender",utc:String="Sender"):
		text = txt
		peer_id = uid
		player_num = num
		player_name = named
		player_color = color
		if send_recieve: #true: recieve
			local_send_time = local
			utc_send_time = utc
			local_receive_time = Time.get_datetime_string_from_system(false, true)
			utc_receive_time = Time.get_datetime_string_from_system(true, true)
		else: #false: send
			local_send_time = Time.get_datetime_string_from_system(false, true)
			utc_send_time = Time.get_datetime_string_from_system(true, true)
	func get_label()->RichTextLabel:
		var l := RichTextLabel.new()
		l.bbcode_enabled = true
		l.fit_content = true
		l.scroll_active = false
		l.text = BBcode.color_text( str(player_num,player_name,":"), player_color)
		l.text += " "+text
		return l



var log : Array[Chat]
func add_to_log(c:Chat):
	log.append(c)
	var chat_node = get_tree().get_first_node_in_group("is_chat")
	if chat_node != null:
		chat_node.add_chat(c.get_label())

func send_chat(txt:String,player_num:int=-1,player_name:String="",player_color:Color=Color.WHITE):
	var uid : int = multiplayer.get_unique_id()
	var c := Chat.new(txt, uid, player_num, player_name, player_color, false)
	add_to_log(c)
	_remote_chat.rpc(txt, uid, player_num, player_name, player_color, true, c.local_send_time, c.utc_send_time)

@rpc("any_peer", "call_remote", "reliable")
func _remote_chat( text:String, player_num:int, player_name:String, player_color:Color,
		local_send_time:String, utc_send_time:String):
	var c := Chat.new(text, multiplayer.get_remote_sender_id(), player_num,
		player_name, player_color, true, local_send_time, utc_send_time)
	add_to_log(c)
