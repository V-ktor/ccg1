extends Sprite


func _input_event(ev):
	if (ev is InputEventMouseButton && ev.button_index==BUTTON_RIGHT):
		if (has_node("Card")):
			get_node("Card").focus = ev.pressed
			get_node("Card").set_z_index(ev.pressed)
			get_node("/root/Main").hand_offset = 200.0*float(ev.pressed)

func _mouse_exit():
	if (has_node("Card")):
		get_node("Card").focus = false
		get_node("Card").set_z_index(0)
		get_node("/root/Main").hand_offset = 0
