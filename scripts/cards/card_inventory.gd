extends Control

var focus = false


func _mouse_entered():
	focus = true
	get_node("Card").set_z_index(1)

func _mouse_exited():
	focus = false
	get_node("Card").set_z_index(0)

func _input_event(ev):
	if (ev is InputEventMouseButton && ev.button_index==BUTTON_RIGHT):
		focus = ev.pressed
		get_node("Card").set_z_index(ev.pressed)

func _process(delta):
	var target_zoom = Vector2(0.5,0.5)*(1.0+float(focus))
	var zoom = get_scale()
	set_scale(zoom+delta*10*(target_zoom-zoom))
	if (zoom==Vector2(1.0,1.0) && !focus):
		set_scale(Vector2(0.5,0.5))
	
	if (has_node("Card")):
		get_node("Card").focus = focus
		get_node("Card/Description").set_visible(focus)
		if (focus):
			if (get_global_position().x>OS.get_window_size().x/2-250):
				get_node("Card/Description/ScrollContainer").set_position(Vector2(-650,-250))
			else:
				get_node("Card/Description/ScrollContainer").set_position(Vector2(250,-250))
