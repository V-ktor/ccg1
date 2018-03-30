extends Node

onready var music = get_node("Music")
onready var animation = get_node("Animation")


func play(file):
	var stream = load("res://music/"+file)
	if (music.get_stream()==stream):
		return
	if (music.is_playing()):
		if (!animation.is_playing() || animation.get_current_animation()!="fade_out"):
			animation.queue("fade_out")
		yield(animation,"animation_finished")
	
	music.set_stream(stream)
	music.play()
	animation.play("fade_in")
