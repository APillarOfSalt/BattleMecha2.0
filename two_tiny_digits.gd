extends Container
class_name Tiny_Digit_Display

var hide_tens : bool = true:
	set(toggle):
		$tens.visible = val > 9 or !hide_tens

var val : int:
	set(i):
		val = clamp(i,0,99)
		var frames := Vector2i(0, str(val)[0].to_int())
		$tens.visible = val > 9 or !hide_tens
		if val > 9:
			frames.x = str(val)[0].to_int()
			frames.y = str(val)[1].to_int()
		$tens/sprite.frame = frames.x
		$ones/sprite.frame = frames.y
