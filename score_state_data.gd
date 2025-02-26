extends Resource
class_name Score_State_Data

func _init(dict:Dictionary={}):
	_from_dictionary(dict)
	_populate()

func _from_dictionary(dict:Dictionary):
	if !dict.size():
		return
	tile_score.clear()
	score_tiles = dict
	for score in score_tiles.keys():
		for vec in score_tiles[score]:
			var tile : Vector3i
			if vec is String:
				tile = Global.vec3_from_json(vec)
			elif vec is Vector3i:
				tile = vec
			tile_score[tile] = int(score)
func _to_dictionary()->Dictionary:
	_populate()
	return score_tiles

var tile_score : Dictionary = {} #tile:Vector3i : score:int,

var score_tiles : Dictionary = {} #score:int : [tile:vec3i, etc...],
func _populate():
	score_tiles.clear()
	for score:int in tile_score.values():
		if !score in score_tiles.keys():
			score_tiles[score] = []
	for tile:Vector3i in tile_score.keys():
		score_tiles[tile_score[tile]].append(tile)




