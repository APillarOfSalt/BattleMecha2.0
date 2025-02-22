extends VBoxContainer

signal dir_changed(dir:DIR)

@onready var dir_sel = $top/dir_sel
@onready var align_spr = $disp/grid/h2/tile2/aligned
@onready var misalign_spr = $disp/grid/h3/tile/misaligned

var push_dir : DIR = DIR.None:
	set(dir):
		push_dir = dir
		if dir_sel.selected != dir+1:
			dir_sel.selected = dir+1
		_set_sprs(dir)
		dir_changed.emit(dir)
enum DIR{None=-1,
	Push_Back=0,Push_Right=1,Pull_Right=2,
	Pull_Forward=3,Pull_Left=4,Push_Left=5,MAX=6}
func _on_option_button_item_selected(index):
	push_dir = index-1


func _set_sprs(dir:DIR):
	var no_push : bool = dir == DIR.None
	align_spr.visible = !no_push
	misalign_spr.visible = !no_push
	if no_push:
		return
	var a_props : Vector3i = PROPS[dir]
	var prior : int = ( dir + DIR.MAX - 1 ) % DIR.MAX
	var m_props : Vector3i = PROPS[prior]
	#if we are at Vector2i(0,0)
	#then back for Vector2i(0,1) = Vector2i(0,2)
	align_spr.flip_h = a_props.x
	align_spr.flip_v = a_props.y
	align_spr.frame = a_props.z
	misalign_spr.flip_h = m_props.x
	misalign_spr.flip_v = m_props.y
	misalign_spr.frame = m_props.z

const PROPS : Array[Vector3i] = [
	#x==flip_h, y==flip_v, z==frame		if dir_to==Vector3i(0,-#)
	Vector3i(false,false,0), #0 	Push_Back		↑	Vector3i(0,-1)
	Vector3i(true,false,1), #1		Push_Right		↗
	Vector3i(true,true,1), #2		Pull_Right		↘
	Vector3i(false,true,0), #3		Pull_Forward	↓
	Vector3i(false,true,1), #4		Pull_Left		↙
	Vector3i(false,false,1), #5 	Push_Left		↖
]
