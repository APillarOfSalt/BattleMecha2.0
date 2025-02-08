extends Sprite2D

func _physics_process(_delta):
	for node in get_tree().get_nodes_in_group("input"):
		if !node.is_visible_in_tree():
			continue
		if !( node is Module_Backdrop or node.is_in_group("module_display") ):
			continue
		var t : Transform2D = node.get_global_transform_with_canvas()
		var s = node.get("size")
		var rect = null
		if Rect2(t.origin, s).has_point(global_position):
			$module_manager.hovering_backdrop = true
			rect = node._get_input_rect(self.global_position)
		$Panel.visible = rect is Rect2
		if rect is Rect2:
			$Panel.global_position = rect.position
			$Panel.size = rect.size
