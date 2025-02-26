extends HBoxContainer

class_name Combat_Display

signal attacks_complete()

@onready var push_ctrl : Combat_Push_Controller = $push_controller

const one_atk_scene : PackedScene = preload( "res://attack_queue_one_attack.tscn" )
const two_scene : PackedScene = preload( "res://attack_queue_two_overlap.tscn" )
const three_scene : PackedScene = preload( "res://attack_queue_three_overlap.tscn" )
@export var map : TileMap = null
@export var obj_ctrl : Object_Controller = null
@export var turn_tracker : Turn_Tracker = null
@export var sniffer : Combat_Sniffer = null

func debug_create_attack(atk:Unit_Node, wep:Module_Data.Weapon_Data, def:Unit_Node):
	var atk_node = one_atk_scene.instantiate()
	add_child(atk_node)
	atk_node.setup(atk, wep, [def])
	atk_node.animation_finished.connect(_on_anim_finished)
	attacks.append(atk_node)

@rpc("authority", "call_local", "reliable")
func _play():
	print("RPC:attack_queue._play()[]\n",
		"from:",multiplayer.get_remote_sender_id(),
		", p:",Global.server_controller.instance_id,
		", on:",multiplayer.get_unique_id(),"\n","@:",Time.get_ticks_msec())
	if !attacks.size():
		print("out of attacks")
		return false
	attacks.front().play()
	return true
func _on_anim_finished():
	await Global.create_wait_timer(0.1)
	var atk = attacks.pop_front()
	for obj in obj_ctrl.get_all_combat_objs():
		if obj.dying:
			print("unit is dying...")
			await obj.unit_node.is_now_dead
	atk.queue_free()
	sniffer.update_tiles(attacks)
	if attacks.size():
		print("playing next attack")
		attacks.front().play()
	else:
		attacks_complete.emit()
		print("attacks completed; emitting...")


var attacks : Array
@rpc("authority", "call_local", "reliable")
func create_atk_node(atk_id:int,mod_id:int,def_ids:Array):
	print("RPC:create_atk_node(atk_id:int,mod_id:int,def_ids:Array):._play()[",atk_id,",",mod_id,",",def_ids,"]\n",
		"from:",multiplayer.get_remote_sender_id(),
		", p:",Global.server_controller.instance_id,
		", on:",multiplayer.get_unique_id(),"\n","@:",Time.get_ticks_msec())
	var obj:Map_Object = obj_ctrl.all_objects[atk_id]
	var attacker:Unit_Node = obj.unit
	var weapon:Module_Data.Weapon_Data = attacker.unit_data.get_module(mod_id)
	var defense:Array[Unit_Node] = []
	for id in def_ids:
		var defender : Unit_Node = obj_ctrl.all_objects[id].unit
		if attacker.player_num != defender.player_num: #dont attack friendly mechs
			defense.append(defender)
	var atk_node = one_atk_scene.instantiate()
	atk_node.animation_finished.connect(_on_anim_finished)
	atk_node.obj_ctrl = obj_ctrl
	add_child(atk_node)
	atk_node.setup(attacker, weapon, defense)
	attacks.append(atk_node)

@rpc("authority", "call_local", "reliable")
func create_overlap_push(a_id:int,b_id:int,c_id:int=-1):
	print("create_overlap_push(a_id:int,b_id:int,c_id:int=-1):[",a_id,",",b_id,",",c_id,"],\n",
		"from:",multiplayer.get_remote_sender_id(),", p:",Global.server_controller.instance_id,
		", on:",multiplayer.get_unique_id(),"\n","@:",Time.get_ticks_msec())
	var a_unit : Unit_Node = obj_ctrl.all_objects[a_id].unit
	var a_obj_id : int = a_unit.map_obj.id
	var b_unit : Unit_Node = obj_ctrl.all_objects[b_id].unit
	var b_obj_id : int = b_unit.map_obj.id
	var no_c : bool = c_id <= -1 #false:ABC ; true:AB 
	var atk_node = [three_scene, two_scene][int(no_c)].instantiate()
	atk_node.animation_finished.connect(_on_anim_finished)
	atk_node.obj_ctrl = obj_ctrl
	add_child(atk_node)
	attacks.append(atk_node)
	if no_c:
		atk_node.setup(a_unit, null, b_unit, null)
		push_ctrl.resolve_overlap_abc(a_obj_id, -1, b_obj_id, -1)
	else:
		var c_unit : Unit_Node = obj_ctrl.all_objects[c_id].unit
		var c_obj_id : int = c_unit.map_obj.id
		atk_node.setup(a_unit, null, b_unit, null, c_unit, null)
		push_ctrl.resolve_overlap_abc(a_obj_id, -1, b_obj_id, -1, c_obj_id, -1)

@rpc("authority", "call_local", "reliable")
func create_overlap_node(a_id:int,a_wep_id:int, b_id:int,b_wep_id:int,c_id:int=-1,c_wep_id:int=-1):
	print("create_overlap_node(a_id:int,a_wep_id:int, b_id:int,b_wep_id:int,c_id:int=-1,c_wep_id:int=-1):[\n",
		a_id,",",a_wep_id,",",b_id,b_wep_id,",",c_id,",",c_wep_id,"],\n",
		"from:",multiplayer.get_remote_sender_id(),", p:",Global.server_controller.instance_id,
		", on:",multiplayer.get_unique_id(),"\n","@:",Time.get_ticks_msec())
	var a_unit : Unit_Node = obj_ctrl.all_objects[a_id].unit
	var a_wep : Module_Data.Weapon_Data = a_unit.unit_data.get_module(a_wep_id)
	var a_obj_id : int = a_unit.map_obj.id
	var b_unit : Unit_Node = obj_ctrl.all_objects[b_id].unit
	var b_wep : Module_Data.Weapon_Data = a_unit.unit_data.get_module(b_wep_id)
	var b_obj_id : int = b_unit.map_obj.id
	var no_c : bool = c_id <= -1 or c_wep_id <= -1 #false:ABC ; true:AB 
	var atk_node = [three_scene, two_scene][int(no_c)].instantiate()
	atk_node.animation_finished.connect(_on_anim_finished)
	atk_node.obj_ctrl = obj_ctrl
	add_child(atk_node)
	attacks.append(atk_node)
	if no_c:
		atk_node.setup(a_unit, a_wep, b_unit, b_wep)
		push_ctrl.resolve_overlap_abc(a_obj_id, a_wep_id, b_obj_id, b_wep_id)
	else:
		var c_unit : Unit_Node = obj_ctrl.all_objects[c_id].unit
		var c_wep : Module_Data.Weapon_Data = a_unit.unit_data.get_module(c_wep_id)
		var c_obj_id : int = c_unit.map_obj.id
		atk_node.setup(a_unit, a_wep, b_unit, b_wep, c_unit, c_wep)
		push_ctrl.resolve_overlap_abc(a_obj_id, a_wep_id, b_obj_id, b_wep_id, c_obj_id, c_wep_id)

#false:Melee, true:Ranged
func gather_weapons(objs:Array[Map_Object], melee_ranged:bool)->Dictionary:
	var obj_weps : Dictionary = {} #obj_id:int : [wep_id:int, etc...]
	for obj in objs:
		obj_weps[obj.id] = []
		for wep_id:int in obj.unit.cubic_weapons.keys():
			var weapon : Module_Data.Weapon_Data = obj.unit.unit_data.get_module(wep_id)
			if weapon.subtype != "Melee" and !melee_ranged:
				continue
			elif weapon.subtype == "Melee" and melee_ranged:
				continue
			obj_weps[obj.id].append(wep_id)
	return obj_weps


func create_combat_at(cube:Vector3i):
	var objs : Array[Map_Object] = obj_ctrl.get_objs_at(cube)
	var weapons : Dictionary = {}
	if objs.size() > 1: #overlap
		weapons = gather_weapons(objs, false) #only melee
	else:
		weapons = gather_weapons(objs, turn_tracker.phase == turn_tracker.PHASES.ranged)
	if weapons.keys().size() > 1: #overlap
		queue_overlap_attacks(weapons)
		return
	elif weapons.size() == 0: #no units error
		print("oop")
		return
	var atk_id : int = weapons.keys()[0]
	var atk : Map_Object = null
	var def : Array[int] = []
	for obj in objs:
		if obj.id == atk_id:
			atk = obj
		else:
			def.append(obj.id)
	for wep_id:int in weapons[atk_id]:
		create_atk_node.rpc(atk_id, wep_id, def)

func queue_overlap_attacks(obj_weps:Dictionary):
	var max_num : int = 0
	for key in obj_weps.keys():
		if obj_weps[key] is Module_Data.Weapon_Data:
			max_num = max(obj_weps[key].size, max_num)
	if max_num == 0:
		var obj_ids : Array = obj_weps.keys()
		match obj_ids.size():
			3:
				create_overlap_push.rpc(obj_ids[0], obj_ids[1], obj_ids[2])
			2:
				create_overlap_push.rpc(obj_ids[0], obj_ids[1])
			_:
				print("oop")
		return
	
	for i in max_num:
		i = max_num - i - 1
		var this_atk : Dictionary = {} #obj_id:int : weapon_id:int
		for obj_id:int in obj_weps.keys():
			this_atk[obj_id] = -1
			if obj_weps[obj_id].size() > i:
				this_atk[obj_id] = obj_weps[obj_id][i]
		#number of mechs with melee weapons on the tile
		var num_melee_overlap : int = this_atk.keys().size() - this_atk.values().count(-1)
		if num_melee_overlap == 1:
			var this_def : Array = []
			var atk_id : int = -1
			var wep_id : int = -1
			for obj_id:int in this_atk.keys():
				if this_atk[obj_id] == -1:
					this_def.append(obj_id)
				else:
					atk_id = obj_id
					wep_id = this_atk[obj_id]
			if atk_id == -1 or wep_id == -1:
				print("oop")
				return
			create_atk_node.rpc(atk_id, wep_id, this_def)
			return
		var a_id : int = this_atk.keys()[0]
		var a_wep : int = this_atk[a_id]
		var b_id : int = this_atk.keys()[1]
		var b_wep : int = this_atk[b_id]
		var c_id : int = -1
		var c_wep : int = -1
		if this_atk.keys().size() == 3:
			c_id = this_atk.keys()[2]
			c_wep = this_atk[c_id]
		create_overlap_node.rpc(a_id, a_wep, b_id, b_wep, c_id, c_wep)
		
		#else: # num_melee_overlap == 0
			#for obj_id:int in this_atk.keys():
				#var obj : Map_Object = obj_ctrl.all_objects[obj_id]
				#var old_pos : Vector3i = obj.to_pos
				#obj.to_pos = obj.cubic
				#obj.cubic = old_pos
	
