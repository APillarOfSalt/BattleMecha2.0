extends Sprite2D

class_name Cursor_Hover

var device : int = -1

const style : StyleBox = preload("res://styles/hover_outline_stylebox.tres")
func _ready():
	panel.add_theme_stylebox_override("panel", style.duplicate(true))
@export var panel : Panel

const HOVER_RADIUS : int = 4
var hovering : Array[Node]
func refresh_hover():
	hovering.clear()
	for node in get_tree().get_nodes_in_group("input"):
		if node == null:
			continue
		if !node is CanvasItem:
			continue
		if !node.is_visible_in_tree():
			continue
		var g = node.get("global_position")
		var t : Transform2D = node.get_global_transform_with_canvas()
		var s = node.get("size")
		var map = node.get("map")
		var pos = node.get("map_pos")
		var do_hover : bool = false
		var map_pos = null
		if map != null and pos != null: #map overlaps
			map_pos = map.local_to_map( map.to_local(global_position) )
			do_hover = node.map_pos == map_pos
		if s != null and !do_hover: #if the node has a size see if we are within the bounds
			do_hover = Rect2(t.origin, s ).has_point(global_position)
		if g != null and !do_hover:
			do_hover = global_position.distance_to(g) < HOVER_RADIUS
		if node.has_method("cursor_hover"):
			node.cursor_hover(do_hover)
		panel.hide()
		if do_hover:
			hovering.append(node)
	
	hover_refreshed.emit()
	
	var rect = null
	for i in hovering:
		if i.has_method("_get_input_rect") and i.is_visible_in_tree():
			rect = i._get_input_rect(self.global_position)
			break
	if rect == null:
		for i in hovering:
			var s = i.get("size")
			var g = i.get("global_position")
			if (s is Vector2 or s is Vector2i) and (g is Vector2 or g is Vector2i) and i.is_visible_in_tree():
				rect = Rect2(g,s)
				break
	panel.visible = rect is Rect2
	if rect is Rect2:
		panel.global_position = rect.position
		panel.size = rect.size

signal hover_refreshed()

