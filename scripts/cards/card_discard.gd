extends TextureButton

var target_pos = Vector2(0,0)
var focus = false


func _input_event(ev):
	if (ev is InputEventMouseButton && ev.button_index==BUTTON_RIGHT):
		focus = ev.pressed
		get_node("Card").set_z_index(ev.pressed)

func _process(delta):
	var target_zoom = Vector2(1.0,1.0)*(1.0+1.0*float(focus))
	var zoom = get_scale()
	set_position(get_position()+delta*5*(target_pos-get_size()*get_scale()*Vector2(0.5,1.4)-get_position()))
	set_scale(zoom+delta*10*(target_zoom-zoom))
	
	if (has_node("Card")):
		get_node("Card").focus = focus
		get_node("Card/Description").set_visible(focus)

func _ready():
	set_process(true)
