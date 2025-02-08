#extends Node
#class_name Unit_Verifier
#
#@onready var host : Host_Controller = $"../Host_Controller"
#@onready var server : Server_Controller = get_parent()
#
#signal units_validated(fails:Dictionary)
#
#var units_valid : bool
#var unit_fails : Dictionary #iid:int : [unit_id:int]
#func server_verify_units(call:bool=false):
	#if server.instance_id != 1:
		#return
	#else:
		#print(get_viewport().get_window())
	#if call:
		#server_valid_units.clear()
		#for iid in host.get_iids():
			#server_valid_units[iid] = {}
	#unit_fails = check_full_valid_unit()
	#units_valid = true
	#for iid in unit_fails.keys():
		#if unit_fails[iid].size():
			#units_valid = false
			#break
	#if units_valid or !call:
		#print("units_valid")
		#units_validated.emit(unit_fails)
		#return
	#for iid in unit_fails.keys():
		#next_unit(iid)
#func next_unit(iid:int):
	#var uid : int = host.iid_uid[iid]
	#if unit_fails[iid].size():
		#var unit_id : int = unit_fails[iid].pop_front()
		#client_verify_unit.rpc_id(uid, unit_id)
		#return
	#for arr in unit_fails.values():
		#if arr.size():
			#return
	#server_verify_units(false)
#
#var server_valid_units : Dictionary #iid:int : {unit_id:int, :Unit_Data} #DIFFERENT
#func check_full_valid_unit()->Dictionary:
	#var fails : Dictionary #iid:int : [unit_id:int]
	#for iid in host.get_iids(false):
		#fails[iid] = []
	#for id in DataLoader.units_by_id.keys():
		#for iid in fails:
			#if !id in server_valid_units[iid]:
				#fails[iid].append(id)
	#return fails
#
#@rpc("authority", "call_remote", "reliable")
#func client_verify_unit(id:int):
	#if !id in DataLoader.units_by_id:
		#_on_server_unit_fail.rpc_id(1)
		#return
	#var json : String = DataLoader.units_by_id[id]._to_json_string()
	##print("pre : ",unit_dict)
	#_on_server_verify_unit.rpc_id(1, json)
	##print("verifying #",id)
#
#@rpc("any_peer", "call_remote", "reliable")
#func _on_server_verify_unit(json:String):
	#var uid : int = multiplayer.get_remote_sender_id()
	#var iid : int = host.get_iid(uid)
	##print("iid #",iid)
	#var unit := Unit_Data.new(json)
	##print("post_unit : ",unit is Unit_Data,":",unit)
	#if unit is Unit_Data:
		#server_valid_units[iid][unit.id] = unit
	#next_unit(iid)
#
#@rpc("any_peer", "call_remote", "reliable")
#func _on_server_unit_fail():
	#var uid : int = multiplayer.get_remote_sender_id()
	#var iid : int = host.get_iid(uid)
	#print("iid #",iid," fail")
	#next_unit(iid)
#
#
#func validate_unit(data:Dictionary)->Unit_Data:
	### PUT VALIDATION CODE HERE
	#var new_unit := Unit_Data.new(data)
	#return new_unit
#
#var distributed_units : Dictionary #unit_id:int : [iid_to]
#func distribute_units():
	##print("distribute start")
	#server_valid_units[1] = {}
	#distributed_units.clear()
	#for id in DataLoader.units_by_id.keys():
		#distributed_units[id] = []
		#var dict : Dictionary = DataLoader.units_by_id[id]._to_dictionary()
		#var unit = validate_unit(dict)
		#if unit is Unit_Data:
			#server_valid_units[1][id] = unit
	#next_dist()
#var last : int = 0
#func _process(delta):
	#if !distributed_units.size():
		#return
	#var now : int = Time.get_ticks_msec()
	#if now - last > 100:
		#last = now
	#else:
		#return
	#next_dist()
#func next_dist():
	#var unit_id : int = distributed_units.keys().front()
	#var next : bool = true
	#for iid:int in host.iid_uid.keys():
		#if !iid in distributed_units[unit_id]:
			#distributed_units[unit_id].append(iid)
			#var unit : Unit_Data = server_valid_units[iid][unit_id]
			##print(unit)
			#for other_iid in host.get_iids():
				#if iid == other_iid:
					#continue
				#var peer_id : int = host.iid_uid[other_iid]
				#if other_iid == 1:
					#DataLoader.set_server_unit(iid, unit)
				#else:
					#receive_unit.rpc_id(peer_id, iid, unit._to_json_string())
			##print("distributing unit #",unit_id," from iid #",iid)
			#next = false
			#break
	#if next_unit:
		#distributed_units.erase(unit_id)
		#if distributed_units.size():
			#unit_id = distributed_units.keys().front()
			##print("next unit", unit_id)
		##else:
			##print("Last Dist")
#
#@rpc("authority", "call_remote", "reliable")
#func receive_unit(iid:int, json:String):
	#var unit := Unit_Data.new(json)
	##print(server.instance_id,":",iid,":\n ",unit)
	#DataLoader.set_server_unit(iid, unit)
