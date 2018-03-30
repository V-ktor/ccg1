extends CanvasLayer

var timer
var main
var unit_used = false
var unit_moved = false
var unit_invaded = false
var discarded = false
var next_turn = false


func add_text(texts):
	if (!get_node("TextBox").is_visible() || (get_node("TextBox/Animation").is_playing() && get_node("TextBox/Animation").get_current_animation()=="fade_in")):
		if (get_node("TextBox/Animation").is_playing()):
			yield(get_node("TextBox/Animation"),"animation_finished")
		get_node("TextBox/Animation").queue("fade_in")
	
	var old = get_node("TextBox/Text").get_text()
	get_node("TextBox/Text").clear()
	get_node("TextBox/Text").push_color(Color(0.6,0.6,0.6))
	get_node("TextBox/Text").add_text(old)
	get_node("TextBox/Text").add_text("\n\n\n")
	get_node("TextBox/Text").push_color(Color(1.0,1.0,1.0))
	for text in texts:
		get_node("TextBox/Text").add_text(tr(text))
		get_node("TextBox/Text").newline()

func _ready():
	var has_unit = false
	main = get_node("/root/Main")
	timer = Timer.new()
	timer.set_one_shot(true)
	add_child(timer)
	add_text(["TUTORIAL_START"])
	timer.set_wait_time(1.0)
	timer.start()
	while (!has_unit):
		main.draw_init()
		main.update_discard_cards()
		for ID in main.hand[main.main_player]:
			if (Data.data[ID]["level"]<=3 && Data.data[ID]["type"]=="unit"):
				has_unit = true
				break
	
	yield(timer,"timeout")
	add_text(["TUTORIAL_INIT_1","TUTORIAL_INIT_2"])
	get_node("DrawInit").show()
	get_node("DrawInit").update()
	
	main.connect("init_discarded",self,"_discarded",[],CONNECT_ONESHOT)
	main.connect("started",self,"_started",[],CONNECT_ONESHOT)

func _discarded():
	get_node("DrawInit").hide()

func _started():
	var has_unit = false
	while (!has_unit):
		for ID in main.hand[main.main_player]:
			if (Data.data[ID]["level"]<=3 && Data.data[ID]["type"]=="unit"):
				has_unit = true
		if (!has_unit):
			main.hand[main.main_player][0] = main.deck[main.main_player][randi()%(main.deck[main.main_player].size())]
	add_text(["TUTORIAL_POINTS"])
	get_node("DrawPoints").show()
	main.connect("new_turn",self,"_next_hint")
	timer.set_wait_time(3.0)
	timer.start()
	
	yield(timer,"timeout")
	use_unit()

func _next_hint():
	printt("next hint")
	get_node("DrawPoints").hide()
	get_node("DrawUnitsHand").hide()
	get_node("DrawDiscard").hide()
	get_node("DrawUnits").hide()
	printt(main.player,main.main_player)
	if (main.player!=main.main_player):
		if (get_node("TextBox").is_visible() && (!get_node("TextBox/Animation").is_playing() || get_node("TextBox/Animation").get_current_animation()=="fade_in")):
			get_node("TextBox/Animation").queue("fade_out")
		return
	
	if (!unit_used):
		var can_use_unit = false
		for ID in main.hand[main.player]:
			var card = Data.data[ID]
			if (card["type"]=="unit" && card["level"]<=main.player_points[main.main_player][card["faction"]]-main.player_used_points[main.main_player][card["faction"]]):
				can_use_unit = true
				break
		if (can_use_unit):
			use_unit()
			return
	if (!unit_moved):
		var can_move_unit = false
		for unit in main.cards[main.main_player]:
			if (unit==null):
				continue
			if (!unit.moved && !("unmoveable" in Data.data[unit.type]["effects"])):
				can_move_unit = true
				break
		if (can_move_unit):
			unit_used = true
			move_unit()
			return
	if (!unit_invaded):
		var can_invade = false
		for x in range(main.SIZE):
			for y in range(main.POSITIONS):
				var pos = main.POSITIONS*x+y
				if (main.cards[main.main_player][pos]!=null && !main.cards[main.main_player][pos].attacked && main.field[x].owner!=main.PLAYER1):
					can_invade = true
					break
		
		if (can_invade):
			unit_moved = true
			invade()
			return
	if (!discarded):
		var can_discard = main.hand[main.main_player].size()>1
		
		if (can_discard):
			discard()
			return
	if (!next_turn):
		_end_turn()

func use_unit():
	if (main.is_connected("unit_used",self,"_next_hint")):
		return
	
	add_text(["TUTORIAL_UNITS_1","TUTORIAL_UNITS_2"])
	get_node("DrawUnitsHand").show()
	get_node("DrawUnitsHand").update()
	main.connect("unit_used",self,"_next_hint",[],CONNECT_ONESHOT)

func move_unit():
	add_text(["TUTORIAL_UNITS_MOVE"])
	get_node("DrawUnits").show()
	get_node("DrawUnits").move = true
	get_node("DrawUnits").attack = false
	get_node("DrawUnits").invade = false
	get_node("DrawUnits").update()
	main.connect("unit_moved",self,"_next_hint",[],CONNECT_ONESHOT)
	yield(get_tree(),"idle_frame")
	get_node("DrawUnits").update()

func invade():
	add_text(["TUTORIAL_UNITS_BOMBARD_1","TUTORIAL_UNITS_BOMBARD_2","TUTORIAL_UNITS_BOMBARD_3"])
	get_node("DrawUnits").show()
	get_node("DrawUnits").move = false
	get_node("DrawUnits").attack = false
	get_node("DrawUnits").invade = true
	get_node("DrawUnits").update()
	main.connect("unit_invaded",self,"_next_hint",[],CONNECT_ONESHOT)
	yield(get_tree(),"idle_frame")
	get_node("DrawUnits").update()

func discard():
	unit_invaded = true
	add_text(["TUTORIAL_RESOURCES_1","TUTORIAL_RESOURCES_2"])
	get_node("DrawDiscard").show()
	get_node("DrawDiscard").update()
	yield(main,"discarded")
	main.connect("discarded",self,"_next_hint",[],CONNECT_ONESHOT)
	discarded = true

func _end_turn():
	add_text(["TUTORIAL_END_TURN"])
	next_turn = true
