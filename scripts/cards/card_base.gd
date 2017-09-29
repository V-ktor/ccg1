extends Node2D

var focus = false
var move_to
var rotate_to

var explosion = preload("res://scenes/cards/card_explosion.tscn")


func create_explosion():
	for i in range(16):
		var ei = explosion.instance()
		ei.set_pos(Vector2(rand_range(-50,50),rand_range(-80,80)))
		ei.lv = Vector2(rand_range(300,400),0).rotated(2*PI*randf())
		add_child(ei)

func _process(delta):
	var target_zoom = Vector2(1.0,1.0)*(1+2*focus)
	var zoom = get_scale()
	if (get_global_pos().distance_squared_to(move_to)>10.0):
		var offset = move_to-get_global_pos()
		offset = offset*offset*offset/(offset.length_squared())
		set_global_pos(get_global_pos()+7.5*delta*offset)
	else:
		set_global_pos(move_to)
	if (abs(get_rot()-rotate_to)>0.1):
		set_rot(get_rot()+4.0*delta*sign(rotate_to-get_rot()))
	else:
		set_rot(rotate_to)
	set_scale(zoom+delta*10*(target_zoom-zoom))

func _ready():
	move_to = get_global_pos()
	rotate_to = get_rot()
