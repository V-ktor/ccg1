extends Control

var focus = false
var target_pos = Vector2(0,0)


func _input_event(ev):
	if (ev is InputEventMouseButton && ev.button_index==BUTTON_RIGHT):
		focus = ev.pressed
		get_node("Card").set_z_index(ev.pressed)

func _process(delta):
	var target_zoom = Vector2(0.5,0.5)*(1.0+float(focus))
	var zoom = get_scale()
	var pos = get_position()
	set_scale(zoom+delta*10*(target_zoom-zoom))
	set_position(pos+delta*10*(target_pos-get_size()*get_scale()*Vector2(0.5,1.4)-pos))
	
	if (has_node("Card")):
		get_node("Card").focus = focus
		
		get_node("Card/Description").set_visible(focus)
		if (focus):
			if (get_position().x>OS.get_window_size().x/2):
				get_node("Card/Description/ScrollContainer").set_position(Vector2(-650,-250))
			else:
				get_node("Card/Description/ScrollContainer").set_position(Vector2(250,-250))

func _ready():
	set_process(true)
