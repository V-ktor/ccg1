extends Sprite


func _input_event(ev):
	if (ev.type==InputEvent.MOUSE_BUTTON && ev.button_index==BUTTON_RIGHT):
		if (has_node("Card")):
			get_node("Card").focus = ev.pressed
			get_node("Card").set_z(ev.pressed)
			get_node("/root/Main").hand_offset = 200*ev.pressed

func _mouse_exit():
	if (has_node("Card")):
		get_node("Card").focus = false
		get_node("Card").set_z(0)
		get_node("/root/Main").hand_offset = 0
