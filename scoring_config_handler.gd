extends Container

@onready var ft : Container = $from_to
@onready var from_spin : SpinBox = $from_to_title/from_val
@onready var to_spin : SpinBox = $from_to_title/to_val

var scoring := Full_Score_State_Data.new():
	set(data):
		scoring = data
		states = scoring.states
		steps = scoring.steps
		from_spin.max_value = states+1
		to_spin.max_value = states+1
		ft.step_setter(steps)
		_refresh()

var states : int = 3
func _on_states_val_value_changed(value:int):
	if $title/states_val.value != value:
		$title/states_val.value = value
		return
	states = value
	scoring._dim_setter( value, steps )
	from_spin.max_value = value+1
	to_spin.max_value = value+1
	_refresh()
var steps : int = 3
func _on_steps_val_value_changed(value:int):
	if $title/steps_val.value != value:
		$title/steps_val.value = value
		return
	steps = value
	scoring._dim_setter( states, value )
	ft.step_setter(value)
	_refresh()

func _ready():
	$"from_to/h/h/0".step = 1
	_on_to_val_value_changed(2)
func _on_from_val_value_changed(value:int):
	if value == 0:
		value = states
	elif value == states+1:
		value = 1
	if !ft.state_setter(value, true):
		value = ft.state_from
	from_spin.value = value
	_refresh()
func _on_to_val_value_changed(value:int):
	if value == 0:
		value = states
	elif value == states+1:
		value = 1
	if !ft.state_setter(value, false):
		value = ft.state_to
	to_spin.value = value
	_refresh()

func _refresh():
	for nd in get_tree().get_nodes_in_group("score_state_disp"):
		var to_val : int = scoring.data_states.keys()[ft.state_to-1]
		var from_val : int = scoring.data_states.keys()[ft.state_from-1]
		var state : int = to_val
		if nd.to_from: #from
			state = from_val
		if nd.step > 0: #step
			var key : int = nd.step
			if from_val > to_val:
				key = steps - 1 - nd.step
			nd.setup( state, scoring.data_steps[to_val+from_val][key] )
		elif nd.to_from: #from
			nd.setup( state, scoring.data_states[ from_val ] )
		else: #to
			nd.setup( state, scoring.data_states[ to_val ] )
