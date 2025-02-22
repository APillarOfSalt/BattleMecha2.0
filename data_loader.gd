extends Node

@onready var unitsjson : JSON = preload("res://units_data.json")
@onready var shapesjson : JSON = preload("res://shapes.json")
@onready var weaponsjson : JSON = preload("res://weapons.json")
@onready var shieldsjson : JSON = preload("res://shields.json")

const last_game_dir : String = "user://last_game"
const user_module_dir : String = "user://user_modules"
const default_module_dir : String = "res://data/default_modules"
const default_unit_dir : String = "res://data/default_units"
#const user_unit_dir : String = "user://user_units"
const user_team_dir : String = "user://user_teams"
var validated : Array = []

func _ready():
	validate_dir_exists()
	load_module_shapes()
	modules_from_memory()
	units_from_memory()
	teams_from_memory()

func validate_dir_exists():
	for dir in [default_module_dir, user_module_dir, default_unit_dir, user_team_dir, last_game_dir]:
		if !DirAccess.dir_exists_absolute(dir):
			DirAccess.make_dir_absolute(dir)
			dir += " Created"
		validated.append(dir)
func load_module_shapes():
	var data : Array = db_json_parse(shapesjson.data)
	for dict in data:
		save_shape(dict)


var shapes_by_id : Dictionary = {0:{},1:{},2:{},3:{},4:{},5:{}}
func save_shape(data:Dictionary):
	shapes_by_id[int(data.id)] = data.data

var modules_by_id : Dictionary = {}
func save_module(mod:Module_Data, overwrite:bool=false):
	var access : String = "abilite"
	if mod is Module_Data.Shield_Data:
		access = "shield"
	elif mod is Module_Data.Weapon_Data:
		access = "weapon"
	if mod.id in modules_by_id and !overwrite:
		return false
	var dict = self.get(str(access,"s_by_id"))
	if dict is Dictionary:
		dict[mod.id] = mod
		modules_by_id[mod.id] = mod
		return true
	return false

var abilites_by_id : Dictionary = {}
func save_ability(data:Dictionary):
	var mod := Module_Data.new(data)
	abilites_by_id[mod.id] = mod
	modules_by_id[mod.id] = mod

var shields_by_id : Dictionary = {}
func save_shield(data:Dictionary):
	var mod := Module_Data.Shield_Data.new(data)
	shields_by_id[mod.id] = mod
	modules_by_id[mod.id] = mod

var weapons_by_id : Dictionary = {}
func save_weapon(data:Dictionary):
	var mod := Module_Data.Weapon_Data.new(data)
	weapons_by_id[mod.id] = mod
	modules_by_id[mod.id] = mod

var units_by_id : Dictionary = {}
func save_unit(data:Dictionary):
	units_by_id[int(data.id)] = Unit_Data.new(data)

func db_json_parse(table:Dictionary)->Array: #table_name : {row_name: val, etc...}
	var data : Array = []
	var columns : Dictionary = {}
	for i in table.columns.size():
		var col : Dictionary = table.columns[i]
		columns[i] = col.name
	for row in table.rows:
		var row_data : Dictionary = {}
		for i in row.size():
			var col_name : String = columns[i]
			row_data[col_name] = row[i]
		data.append(row_data)
	return data

func units_to_memory():
	for id:int in units_by_id.keys():
		var file_name : String = str(default_unit_dir,"/",id,".json")
		var file := FileAccess.open(file_name, FileAccess.WRITE)
		var json : String = units_by_id[id]._to_json_string()
		file.store_line(json)
		file.close()

func units_from_memory():
	for file_s:String in DirAccess.get_files_at(default_unit_dir):
		var file_name : String = str(default_unit_dir,"/",file_s)
		var file := FileAccess.open(file_name, FileAccess.READ)
		var unit := Unit_Data.new(file.get_line())
		units_by_id[int(unit.id)] = unit
		file.close()

var global_team : Team_Data = null:
	set(team):
		units_from_memory()
		global_team = team
		if team != null:
			for i in team.units.keys():
				for unit in team.units[i]:
					units_by_id[unit.id] = unit

#var server_units : Dictionary #iid:int : { unit_id:int : Unit_Data }
#func set_server_unit(iid:int, unit:Unit_Data):
	#if !iid in server_units:
		#server_units[iid] = {}
	#server_units[iid][unit.id] = unit
	#if iid == 1:
		#print("OOP")
	#print(server_units)

var teams_by_name : Dictionary #team_name:String : Team_Data
func save_team(team:Team_Data, skip_file:bool=true):
	teams_by_name[team.name] = team
	if skip_file:
		return
	var file_name : String = str(user_team_dir,"/",team.name,".json")
	var file := FileAccess.open(file_name, FileAccess.WRITE)
	var json : String = team._to_json_string()
	file.store_line(json)
	file.close()
func teams_to_memory():
	for named:String in teams_by_name.keys():
		var file_name : String = str(user_team_dir,"/",named,".json")
		var file := FileAccess.open(file_name, FileAccess.WRITE)
		var json : String = teams_by_name[named]._to_json_string()
		file.store_line(json)
		file.close()
func teams_from_memory():
	for file_s:String in DirAccess.get_files_at(user_team_dir):
		var file_name : String = str(user_team_dir,"/",file_s)
		var file := FileAccess.open(file_name, FileAccess.READ)
		var team := Team_Data.new()
		team._from_json_string(file.get_line())
		save_team(team)
		file.close()
func modules_to_memory():
	for id:int in modules_by_id.keys():
		var file_name : String = str(default_module_dir,"/",id,".json")
		var file := FileAccess.open(file_name, FileAccess.WRITE)
		var json : String = JSON.stringify( modules_by_id[id]._to_dictionary() )
		file.store_line(json)
		file.close()

func modules_from_memory():
	for file_s:String in DirAccess.get_files_at(default_module_dir):
		var file_name : String = str(default_module_dir,"/",file_s)
		var file := FileAccess.open(file_name, FileAccess.READ)
		var data : Dictionary = JSON.parse_string(file.get_line())
		if data.type == "Shield":
			save_shield(data)
		elif data.type == "Weapon":
			save_weapon(data)
		else:
			save_ability(data)
		file.close()

func get_next_mod_id(type:int, size:int):
	var id : int = 1 #generic modules
	if type == Global.types.Shield: #shield modules
		id = 100 + (size*10)
	elif type == Global.types.Weapon: #weapon modules
		id = 1000 + (size*100)
	while id in modules_by_id:
		id += 1
	return id

func get_text_datetime(utc:bool, use_space:bool=true)->String:
	return Time.get_datetime_string_from_system(utc, use_space).replace("-",".").replace(":",".")

func save_game_start(data:Dictionary):
	var file_s : String = get_text_datetime(false, false).replace("T",str(".",Global.local_player,"."))
	var file := FileAccess.open( str(last_game_dir,"/",file_s,".json"), FileAccess.WRITE)
	file.store_line(JSON.stringify(data))
	for p_data:Player_Data in Global.player_info_by_num.values():
		var json : String = p_data._to_json_string()
		file.store_line(json)
	file.close()

func fetch_last_game()->Dictionary:
	var header : Dictionary
	var file_names : Array = DirAccess.get_files_at(last_game_dir)
	if file_names.size():
		var file_name : String = last_game_dir+"/"+file_names.pop_front()
		var file := FileAccess.open(file_name, FileAccess.READ)
		header = JSON.parse_string( file.get_line() )
		header.data = []
		var line : String = "Im placeholder text! See ya!"
		while line:
			line = file.get_line()
			header.data.append( Player_Data.new(line) )
	return header
