extends CanvasLayer

var timer
var Main
var unit_used = false
var unit_moved = false
var unit_attacked = false
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
	Main = get_node("/root/Main")
	timer = Timer.new()
	timer.set_one_shot(true)
	add_child(timer)
	add_text(["TUTORIAL_START"])
	timer.set_wait_time(1.0)
	timer.start()
	while (!has_unit):
		Main.draw_init()
		Main.update_discard_cards()
		for ID in Main.hand[Main.main_player]:
			if (Data.data[ID]["level"]<=3 && Data.data[ID]["type"]=="unit"):
				has_unit = true
				break
	
	yield(timer,"timeout")
	add_text(["TUTORIAL_INIT_1","TUTORIAL_INIT_2"])
	get_node("DrawInit").show()
	get_node("DrawInit").update()
	
	Main.connect("init_discarded",self,"_discarded",[],CONNECT_ONESHOT)
	Main.connect("started",self,"_started",[],CONNECT_ONESHOT)

func _discarded():
	get_node("DrawInit").hide()

func _started():
	var has_unit = false
	while (!has_unit):
		for ID in Main.hand[Main.main_player]:
			if (Data.data[ID]["level"]<=3 && Data.data[ID]["type"]=="unit"):
				has_unit = true
		if (!has_unit):
			Main.hand[Main.main_player][0] = Main.deck[Main.main_player][randi()%(Main.deck[Main.main_player].size())]
	add_text(["TUTORIAL_POINTS"])
	get_node("DrawPoints").show()
	Main.connect("new_turn",self,"_next_hint")
	timer.set_wait_time(3.0)
	timer.start()
	
	yield(timer,"timeout")
	use_unit()

func _next_hint():
	get_node("DrawPoints").hide()
	get_node("DrawUnitsHand").hide()
	get_node("DrawDiscard").hide()
	get_node("DrawUnits").hide()
	get_node("DrawEnemy").hide()
	if (Main.player!=Main.main_player):
		if (get_node("TextBox").is_visible() && (!get_node("TextBox/Animation").is_playing() || get_node("TextBox/Animation").get_current_animation()=="fade_in")):
			get_node("TextBox/Animation").queue("fade_out")
		return
	
	if (!get_node("TextBox").is_visible() || get_node("TextBox/Animation").get_current_animation()=="fade_out"):
		get_node("TextBox/Animation").queue("fade_in")
	if (!unit_used):
		var can_use_unit = false
		for ID in Main.hand[Main.player]:
			var card = Data.data[ID]
			if (card["type"]=="unit" && card["level"]<=Main.player_points[Main.main_player][card["faction"]]-Main.player_used_points[Main.main_player][card["faction"]]):
				can_use_unit = true
				break
		if (can_use_unit):
			use_unit()
			return
	if (!unit_moved):
		var can_move_unit = false
		for unit in Main.cards[Main.main_player]:
			if (unit==null):
				continue
			if (unit.movement_points>0):
				can_move_unit = true
				break
		if (can_move_unit):
			move_unit()
			return
	if (!unit_attacked):
		var can_attack = false
		for x in range(Main.SIZE):
			for y in range(Main.POSITIONS):
				var pos = Main.POSITIONS*x+y
				if (Main.cards[Main.main_player][pos]!=null && Main.cards[Main.main_player][pos].attack_points>0):
					for z in range(Main.POSITIONS):
						if (Main.cards[int(!Main.main_player)][Main.POSITIONS*x+z]!=null):
							can_attack = true
							break
		
		if (can_attack):
			attack()
			return
	if (!unit_invaded):
		var can_invade = false
		var guarded = false
		for x in range(Main.SIZE):
			guarded = false
			for y in range(Main.POSITIONS):
				var pos = Main.POSITIONS*x+y
				if (Main.cards[Main.main_player][pos]!=null && Main.cards[Main.main_player][pos].attack_points>0 && Main.field[x].owner!=Main.PLAYER1):
					for z in range(Main.POSITIONS):
						if (Main.cards[int(!Main.main_player)][Main.POSITIONS*x+z]!=null):
							guarded = true
							break
					can_invade = true
					break
				if (guarded):
					break
		
		if (can_invade && !guarded):
			invade()
			return
	if (!discarded):
		var can_discard = Main.hand[Main.main_player].size()>1
		
		if (can_discard):
			discard()
			return
	if (!next_turn):
		_end_turn()
	
	get_node("TextBox").hide()
	get_node("TextBox/Animation").clear_queue()
	get_node("TextBox/Animation").stop()
	Main.connect("unit_moved",self,"_next_hint",[],CONNECT_ONESHOT)

func use_unit():
	if (Main.is_connected("unit_used",self,"_next_hint") || unit_used):
		return
	
	unit_used = true
	add_text(["TUTORIAL_UNITS_1","TUTORIAL_UNITS_2"])
	get_node("DrawUnitsHand").show()
	get_node("DrawUnitsHand").update()
	Main.connect("unit_used",self,"_next_hint",[],CONNECT_ONESHOT)

func move_unit():
	unit_moved = true
	add_text(["TUTORIAL_UNITS_MOVE"])
	get_node("DrawUnits").show()
	get_node("DrawUnits").move = true
	get_node("DrawUnits").attack = false
	get_node("DrawUnits").invade = false
	get_node("DrawUnits").update()
	Main.connect("unit_moved",self,"_next_hint",[],CONNECT_ONESHOT)
	yield(get_tree(),"idle_frame")
	get_node("DrawUnits").update()

func invade():
	unit_invaded = true
	add_text(["TUTORIAL_UNITS_BOMBARD_1","TUTORIAL_UNITS_BOMBARD_2","TUTORIAL_UNITS_BOMBARD_3"])
	get_node("DrawUnits").show()
	get_node("DrawUnits").move = false
	get_node("DrawUnits").attack = false
	get_node("DrawUnits").invade = true
	get_node("DrawUnits").update()
	Main.connect("unit_invaded",self,"_next_hint",[],CONNECT_ONESHOT)
	yield(get_tree(),"idle_frame")
	get_node("DrawUnits").update()

func attack():
	unit_attacked = true
	add_text(["TUTORIAL_UNITS_ATTACK_1"])
	get_node("DrawUnits").move = false
	get_node("DrawUnits").attack = false
	get_node("DrawUnits").invade = true
	get_node("DrawUnits").update()
	get_node("DrawUnits").show()
	get_node("DrawEnemy").update()
	get_node("DrawEnemy").show()
	Main.connect("unit_attacked",self,"_next_hint",[],CONNECT_ONESHOT)
	yield(get_tree(),"idle_frame")
	get_node("DrawUnits").update()
	get_node("DrawEnemy").update()

func discard():
	add_text(["TUTORIAL_RESOURCES_1","TUTORIAL_RESOURCES_2"])
	get_node("DrawDiscard").show()
	get_node("DrawDiscard").update()
	yield(Main,"discarded")
	Main.connect("discarded",self,"_next_hint",[],CONNECT_ONESHOT)
	discarded = true

func _end_turn():
	add_text(["TUTORIAL_END_TURN"])
	next_turn = true
	Main.connect("new_turn",self,"_next_hint")
