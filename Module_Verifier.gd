extends Node
class_name Module_Verifier

@onready var host : Host_Controller = $"../Host_Controller"
@onready var server : Server_Controller = get_parent()

signal modules_validated(fails:Dictionary)

var modules_valid : bool = true
var mod_fails : Dictionary #iid:int : [mod_id:int, etc]
func server_verify_modules(call:bool=false):
	if server.instance_id != 1:
		return
	mod_fails = check_full_valid_mod()
	modules_valid = true
	for iid in mod_fails.keys():
		if mod_fails[iid].size():
			modules_valid = false
			break
	if modules_valid or !call:
		print("modules_valid")
		modules_validated.emit(mod_fails)
		return
	for iid in mod_fails.keys():
		next_mod(iid)

func next_mod(iid:int):
	var uid : int = host.iid_uid[iid]
	if mod_fails[iid].size():
		var mod : Module_Data = DataLoader.modules_by_id[mod_fails[iid].pop_front()]
		client_verify_mod.rpc_id(uid, JSON.stringify(mod._to_dictionary()))
		return
	for arr in mod_fails.values():
		if arr.size():
			return
	server_verify_modules(false)

var server_valid_mods : Dictionary #mod_id:int : Array[validated_iid] #ALL THE SAME
func check_full_valid_mod()->Dictionary:
	var fails : Dictionary #iid:int : [mod_id:int, etc]
	for iid in host.get_iids(false):
		fails[iid] = []
	for id in server_valid_mods.keys():
		for iid in host.get_iids(false):
			if !iid in server_valid_mods[id]:
				fails[iid].append(id)
	return fails

@rpc("authority", "call_remote", "reliable")
func client_verify_mod(json:String, final:bool=false):
	var mod = JSON.parse_string(json)
	var valid : bool = false
	if mod.id in DataLoader.modules_by_id:
		valid = DataLoader.modules_by_id[mod.id].check_duplicate(mod)
	_on_client_verify_mod.rpc_id(1, mod.id, valid, final)
@rpc("any_peer", "call_remote", "reliable")
func _on_client_verify_mod(id:int, valid:bool, final:bool=false):
	var uid : int = multiplayer.get_remote_sender_id()
	var iid : int = host.get_iid(uid)
	if !id in server_valid_mods:
		return
	var found : int = server_valid_mods[id].find(iid)
	if valid and found == -1:
		server_valid_mods[id].append(iid)
	elif !valid and found >= 0:
		server_valid_mods[id].remove_at(found)
	next_mod(iid)




