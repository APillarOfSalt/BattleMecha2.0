extends HBoxContainer

var scoring : Full_Score_State_Data:
	set(data): get_parent().scoring = data
	get: return get_parent().scoring
func _saved_data_names()->Array:
	return DataLoader.score_data_by_name.keys()

func _ready():
	_refresh()
func _refresh():
	var save_sel : int = $op.selected
	$op.clear()
	$op.add_item("+ New Score Config")
	$op.selected = 0
	var names : Array = _saved_data_names()
	for i in names.size():
		$op.add_item(names[i])
		if names[i] == data_name:
			$op.selected = i+1
	if !$op.selected and save_sel > 0 and save_sel < $op.item_count -1:
		$op.selected = save_sel
func _on_op_item_selected(index:int):
	if index > 0:
		var named : String = $op.get_item_text(index)
		scoring = DataLoader.score_data_by_name[named]
	else:
		scoring = Full_Score_State_Data.new()
	var named : String = scoring.name
	data_name = named
	$name_edit.text = named

var data_name : String = ""
func _on_name_edit_text_changed(new_text:String):
	new_text = new_text.strip_edges(true, false)
	while "  " in new_text:
		new_text = new_text.replace("  "," ")
	if new_text in _saved_data_names() and scoring.name != new_text:
		new_text = scoring.name
	if new_text == "New Score Config":
		new_text = ""
	if $name_edit.text != new_text:
		$name_edit.text = new_text
		return
	$save.disabled = new_text == ""
	data_name = new_text

func _on_save_pressed():
	$name_edit.text = $name_edit.text.strip_edges()
	scoring.name = data_name
	DataLoader.save_score_data(scoring)
	_refresh()

func _on_save_batch_pressed():
	DataLoader.score_data_to_memory()


