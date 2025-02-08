extends Container

var hp : int = 0:
	set(val):
		hp = val
		$hl.text = str(val,"/",val)
var armor : int:
	set(val):
		armor = val
		$al.text = str(val)
var s_start : int:
	set(val):
		s_start = val
		$v/start_cap.text = str(val,"/",s_cap)
var s_regen : int:
	set(val):
		s_regen = val
		$v/regen.text = str("+",val)
var s_cap : int:
	set(val):
		s_cap = val
		$v/start_cap.text = str(s_start,"/",val)
