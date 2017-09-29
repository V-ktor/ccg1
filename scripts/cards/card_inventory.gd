extends Control

var focus = false

func _mouse_enter():
	focus = true
	get_node("Card").set_z(1)

func _mouse_exit():
	focus = false
	get_node("Card").set_z(0)

func _input_event(ev):
	if (ev.type==InputEvent.MOUSE_BUTTON && ev.button_index==BUTTON_RIGHT):
		focus = ev.pressed
		get_node("Card").set_z(ev.pressed)

func _process(delta):
	var target_zoom = Vector2(0.5,0.5)*(1+focus)
	var zoom = get_scale()
	set_scale(zoom+delta*10*(target_zoom-zoom))
#	set_pos(-0.5*get_size()*(get_scale()-Vector2(0.5,0.5)))
	if (zoom==Vector2(1.0,1.0) && !focus):
		set_scale(Vector2(0.5,0.5))

func _ready():
	set_process(true)
