extends Node2D

var focus = false
var move_to
var rotate_to
var ID

var explosion = preload("res://scenes/main/card_explosion.tscn")


func create_explosion():
	for i in range(16):
		var ei = explosion.instance()
		ei.set_global_position(Vector2(rand_range(-50,50),rand_range(-80,80)))
		ei.lv = Vector2(rand_range(300,400),0).rotated(2*PI*randf())
		add_child(ei)

func _process(delta):
	var target_zoom = Vector2(1.0,1.0)*(1.0+2.0*float(focus))
	var zoom = get_scale()
	if (get_global_position().distance_squared_to(move_to)>10.0):
		var offset = move_to-get_global_position()
		offset = offset*offset*offset/(offset.length_squared())
		set_global_position(get_global_position()+7.5*delta*offset)
	else:
		set_global_position(move_to)
	if (abs(get_rotation()-rotate_to)>0.1):
		set_rotation(get_rotation()+4.0*delta*sign(rotate_to-get_rotation()))
	else:
		set_rotation(rotate_to)
	set_scale(zoom+delta*10*(target_zoom-zoom))
	
	get_node("Description").set_visible(focus)
	if (focus):
		if (get_viewport_transform().get_origin().x>get_viewport().get_size().x/2-50):
			get_node("Description/ScrollContainer").set_position(Vector2(-650,-250))
		else:
			get_node("Description/ScrollContainer").set_position(Vector2(250,-250))

func _ready():
	set_process(false)
	move_to = get_global_position()
	rotate_to = get_rotation()
