extends Control

var focus = false
var target_pos = Vector2(0,0)

func _mouse_enter():
	focus = true

func _mouse_exit():
	focus = false

func _process(delta):
	var target_zoom = Vector2(0.5,0.5)*(1+focus)
	var zoom = get_scale()
	var pos = get_pos()
	set_scale(zoom+delta*10*(target_zoom-zoom))
	set_pos(pos+delta*10*(target_pos-get_size()*get_scale()*Vector2(0.5,1.0)-pos))

func _ready():
	set_process(true)
