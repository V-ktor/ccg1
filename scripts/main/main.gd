extends Node

# constants #

var SIZE = 4
var POSITIONS = 2
const NUM_PLAYERS = 2
const PLANET_GAS = -1
const PLANET_BARREN = 0
const PLANET_TUNDRA = 1
const PLANET_DESERT = 2
const PLANET_TERRAN = 3
const PLANET_OCEAN = 4
const PLANET_TOXIC = 5
const PLANET_INFERNO = 6
const PLANET_ASTEROID = 7
const PLANET_TEXT = {
PLANET_GAS:"GAS_GIANT",PLANET_ASTEROID:"ASTEROID_BELT",
PLANET_BARREN:"BARREN",PLANET_TUNDRA:"TUNDRA",PLANET_DESERT:"DESERT",
PLANET_TERRAN:"TERRAN",PLANET_OCEAN:"OCEAN",PLANET_TOXIC:"TOXIC",PLANET_INFERNO:"INFERNO"}
const NEUTRAL = -1
const PLAYER1 = 0
const PLAYER2 = 1
const COLOURS = {NEUTRAL:Color(1.0,1.0,1.0),PLAYER1:Color(0.2,0.4,1.0),PLAYER2:Color(1.0,0.3,0.2)}
const NONE = -1
const CARD = 0
const EMPTY = 1
const ENEMY = 2
const FRIENDLY = 3
const PLANET_FRIENDLY = 4
const PLANET_ENEMY = 5
const EMPTY_OR_ENEMY = 6


# variables #

var planets = []
var player_is_ai = [false,true]
var deck = [[],[]]
var hand = [[],[]]
var player = NEUTRAL
var player_points = [0,0]
var player_prod = [0,0]
var player_cost = [0,0]
var selected_hand
var selected_field
var cards = []
var field = []
var turn = -1
var select = NONE
var ai_phase = 0
var selected_target


class Card:
	var structure
	var damage
	var shield
#	var production
	var level
	var type
	var node
	var root

class Unit:
	extends Card
	var attacked
	var moved
	
	func _init(_root,_type,_structure,_damage,_shield,_level,player,pos,pos0):
		root = _root
		node = Cards.create_card(_type)
		structure = _structure
		damage = _damage
		shield = _shield
		level = _level
		type = _type
		
		node.set_name("Card")
		node.set_rot(player*PI)
		root.get_node("Card_"+str(pos)+"_"+str(player)).add_child(node)
		node.set_process(true)
		node.set_pos(pos0)
		
		update()
	
	func update():
		if (structure<0):
			structure = 0
		Cards.update_values(node,level,structure,damage,shield)
		node.get_node("VBoxContainer/Structure").show()

class Planet:
	extends Card
	var production
	var owner
	var planet
	var image
	
	func _init(_root,_type,_structure,_damage,_shield,_level,_production,_owner,_image,pos):
		var img = Sprite.new()
		root = _root
		node = Cards.base.instance()
		node.set_name("Card")
		img.set_name("Image")
		node.get_node("Image").add_child(img)
		structure = _structure
		damage = _damage
		shield = _shield
		level = _level
		production = _production
		planet = _type
		type = ""
		owner = _owner
		image = _image
		
		root.get_node("Planet_"+str(pos)).add_child(node)
		
		update()
	
	func update():
		Cards.update_values(node,level,structure,damage,shield,production)
		if (level==0):
			node.get_node("VBoxContainer/Level").hide()
		node.get_node("VBoxContainer/Structure").show()
		node.get_node("Header").set_modulate(COLOURS[owner])
		node.get_node("Image/Image").set_texture(root.get_node("/root/Menu").planet_icons[planet][image])
		if (type==""):
			node.get_node("Name").set_text(tr(PLANET_TEXT[planet]))
			node.get_node("Desc").set_text("")
		else:
			var text = ""
			node.get_node("Name").set_text(tr(Data.data[type]["name"]))
			for i in range(Data.data[type]["effects"].size()):
				text += tr(Data.data[type]["effects"][i]+"-"+Data.data[type]["targets"][i]+"-"+Data.data[type]["events"][i])+"\n"
			node.get_node("Desc").set_text(text)


# other graphics #

var select_outline = preload("res://images/ui/card_select.png")
var select_green = preload("res://images/ui/card_select_green.png")
var card_back = preload("res://images/cards/card_back.png")


# AI functions #

var ai_class = preload("res://scripts/ai/ai_base.gd")
var ai

func ai_timer():
	get_node("AiTimer").set_wait_time(0.25)
	ai_phase += 1
	if (ai_phase>9):
		get_node("TimerNextTurn").start()
		return
	
	var action
	ai.gather_available_actions(player_points[player],player_prod[player])
	action = ai.get_best_action()
	if (action==null):
		get_node("TimerNextTurn").start()
		return
	var f = action["function"]
	callv(f,action["arguments"])
	
	if (f=="move_card_unit"):
		get_node("AiTimer").set_wait_time(1.0)
	elif (f=="attack_card_unit"):
		get_node("AiTimer").set_wait_time(2.0)
	elif (f=="bombard_card_unit"):
		get_node("AiTimer").set_wait_time(1.0)
	
	get_node("AiTimer").start()


# card functions #

func get_card_targets(x,player,enemy):
	var targets = []
	if (cards[player][x]==null):
		return targets
	
	for y in range(floor(x/POSITIONS)*POSITIONS,(floor(x/POSITIONS)+1)*POSITIONS):
		if (cards[enemy][y]!=null):
			targets.push_back(y)
	
	return targets

func remove_card_planet(pos):
	if (field[pos].type==""):
		return
	
	field[pos].production -= Data.calc_value(field[pos].type,"production")
	field[pos].shield -= Data.calc_value(field[pos].type,"shield")
	field[pos].type = ""
	field[pos].update()

func add_card_planet(pos,ID):
	field[pos].production += Data.calc_value(ID,"production")
	field[pos].shield += Data.calc_value(ID,"shield")
	field[pos].type = ID
	field[pos].update()

func end_turn():
	player = NEUTRAL
	select = NONE
	get_node("TimerNextTurn").start()

func use_card_effect(targets,ID,player):
	var effects = Data.data[hand[player][ID]]["effects"]
	var enemy = PLAYER1
	if (player==PLAYER1):
		enemy = PLAYER2
	for i in range(effects.size()):
		if (typeof(targets[i])==TYPE_STRING):
			if (targets[i]=="player"):
				apply_effect(player,effects[i])
			elif (targets[i]=="opposite"):
				apply_effect(enemy,effects[i])
		else:
			if (effects[i]=="direct damage 6"):
				var pi = load("res://scenes/effects/"+Data.data[hand[player][ID]]["file"]+".tscn").instance()
				targets[i].node.add_child(pi)
				targets[i].structure -= 6
				targets[i].update()
				if (targets[i].structure<=0):
					var x
					for y in range(SIZE*POSITIONS):
						if (cards[enemy][y]==targets[i]):
							x = y
							break
					if (x!=null):
						destroy_unit(x,enemy)
			elif (effects[i]=="increase dmg 2"):
				targets[i].damage += 2
			elif (effects[i]=="armor 2"):
				targets[i].structure += 2
			elif (effects[i]=="shield 1"):
				targets[i].shield += 1
			elif (effects[i]=="repair 4"):
				targets[i].structure = min(targets[i].structure+4,max(targets[i].structure,Data.calc_value(targets[i].type,"structure")))
			elif (effects[i]=="repair 6"):
				targets[i].structure = min(targets[i].structure+6,max(targets[i].structure,Data.calc_value(targets[i].type,"structure")))
			elif (effects[i]=="terraform"):
				targets[i].planet += sign(PLANET_TERRAN-targets[i].planet)
			elif (effects[i]=="production 1"):
				targets[i].production += 1
			elif (effects[i]=="production 2"):
				targets[i].production += 2
			elif (effects[i]=="defense 4"):
				targets[i].structure += 4
			elif (effects[i]=="defense 6"):
				targets[i].structure += 6
			if (targets[i]!=null):
				targets[i].update()
	
	player_points[player] -= Data.calc_value(hand[player][ID],"level")
	unselect_hand()
	hand[player].remove(ID)
	calc_prod()
	
	remove_card(ID,player)
	update_cards()

func use_card_planet(x,ID,player):
	var targets = Data.data[hand[player][ID]]["targets"]
	var effects = Data.data[hand[player][ID]]["effects"]
	var enemy = PLAYER1
	if (player==PLAYER1):
		enemy = PLAYER2
	if (targets[0]=="friendly planet"):
		if (field[x]==null || field[x].owner!=player):
			return
		
		remove_card_planet(x)
		add_card_planet(x,hand[player][ID])
	elif (targets[0]=="enemy planet"):
		if (field[x]==null || field[x].owner==player):
			return
		
		remove_card_planet(x)
		add_card_planet(x,hand[player][ID])
	
	player_points[player] -= Data.calc_value(hand[player][ID],"level")
	unselect_hand()
	hand[player].remove(ID)
	calc_prod()
	
	remove_card(ID,player)

func use_card_unit(x,ID,player):
	var card = Data.data[hand[player][ID]]
	if (cards[player][x]!=null || field[floor(x/POSITIONS)].owner!=player || Data.calc_value(hand[player][ID],"level")>player_points[player]):
		return
	
	add_unit(x,hand[player][ID],player)
	
	for i in range(card["events"].size()):
		if (card["events"][i]=="spawn"):
			if (card["targets"][i]=="player"):
				apply_effect(player,card["effects"][i])
			elif (card["targets"][i]=="opposite"):
				for p in range(NUM_PLAYERS):
					if (p!=player):
						apply_effect(player,card["effects"][i])
	
	player_points[player] -= Data.calc_value(hand[player][ID],"level")
	unselect_hand()
	hand[player].remove(ID)
	calc_prod()
	
	remove_card(ID,player)
	update_cards()

func apply_effect(player,effect):
	if (effect=="draw 2"):
		for k in range(2):
			draw_card(player)
	elif (effect=="draw 3"):
		for k in range(3):
			draw_card(player)
	elif (effect=="points 2"):
		player_points[player] += 2
	elif (effect=="points 3"):
		player_points[player] += 3
	elif (effect=="remove 2"):
		remove_cards(player,2)
	elif (effect=="remove 3"):
		remove_cards(player,3)
	

func remove_cards(player,num):
	for k in range(min(num,hand[player].size())):
		hand[player].remove(randi()%(hand[player].size()))

func apply_effect_unit(effect,player,target):
	if (effect=="reduce dmg 1"):
		cards[player][target].damage -= 1
	elif (effect=="reduce dmg 2"):
		cards[player][target].damage -= 2


func attack_card_unit(attacker,target,player,enemy,counterattack=false):
	if (cards[player][attacker].attacked || cards[player][attacker]==null || cards[enemy][target]==null || (player_points[player]<Data.calc_value(cards[player][attacker].type,"attack cost") && !counterattack) || "no attack" in Data.data[cards[player][attacker].type]["effects"] || counterattack || floor(attacker/POSITIONS)!=floor(target/POSITIONS)):
		return
	
	var card_a = Data.data[cards[player][attacker].type]
	var card_t = Data.data[cards[enemy][target].type]
	var damage = max(cards[player][attacker].damage-cards[enemy][target].shield,0)
	var capture = false
	var counter = false
	for i in range(card_a["effects"].size()):
		if (card_a["events"][i]=="attack"):
			if (card_a["effects"][i]=="penetrate shield"):
				damage = cards[player][attacker].damage
			elif (card_a["effects"][i]=="capture"):
				capture = cards[enemy][target].structure<=damage
			else:
				if (card_a["targets"][i]=="self"):
					apply_effect_unit(card_a["effects"][i],player,attacker)
				elif (card_a["targets"][i]=="target"):
					apply_effect_unit(card_a["effects"][i],enemy,target)
				elif (card_a["targets"][i]=="player"):
					apply_effect(player,card_a["effect"][i])
				elif (card_a["targets"][i]=="opposite"):
					apply_effect(enemy,card_a["effect"][i])
	for i in range(card_t["effects"].size()):
		if (card_t["events"][i]=="attacked"):
			print("when attacked")
			if (card_t["targets"][i]=="attacker"):
				print("target attacker")
				if (card_t["effects"][i]=="counterattack"):
					print("counter attack")
					counter = true
			elif (card_t["targets"][i]=="self"):
				apply_effect_unit(card_t["effects"][i],enemy,attacker)
			elif (card_t["targets"][i]=="target"):
				apply_effect_unit(card_t["effects"][i],player,target)
			elif (card_t["targets"][i]=="player"):
				apply_effect(enemy,card_t["effect"][i])
			elif (card_t["targets"][i]=="opposite"):
				apply_effect(player,card_t["effect"][i])
	
	if (damage<=0):
		return
	
	if (!counterattack):
		player_points[player] -= Data.calc_value(cards[player][attacker].type,"attack cost")
		cards[player][attacker].attacked = true
	
	if (capture):
		destroy_unit(attacker,player)
		add_unit(attacker,cards[enemy][target].type,player)
		cards[player][attacker].structure = cards[enemy][target].structure
		cards[player][attacker].damage = cards[enemy][target].damage
		cards[player][attacker].shield = cards[enemy][target].shield
		cards[player][attacker].attacked = true
		cards[player][attacker].moved = true
		cards[player][attacker].update()
		cards[player][attacker].node.set_global_pos(cards[enemy][target].node.get_global_pos())
		cards[player][attacker].node.set_rot(PI)
		destroy_unit(target,enemy,false)
		counter = false
	else:
		var pi = load("res://scenes/effects/"+Data.data[cards[player][attacker].type]["file"]+".tscn").instance()
		var offset = Vector2(0,0)
		var pos = cards[player][attacker].node.get_global_pos()+offset
		pi.set_pos(offset)
		pi.set_scale(Vector2(1,pos.distance_to(cards[enemy][target].node.get_global_pos())/800.0))
		pi.set_rot(pos.angle_to_point(cards[enemy][target].node.get_global_pos())-cards[player][attacker].node.get_rot())
		cards[player][attacker].node.add_child(pi)
		cards[enemy][target].structure -= damage
		cards[player][attacker].update()
		cards[enemy][target].update()
		if (cards[enemy][target].structure<=0):
			destroy_unit(target,enemy)
			counter = false
	
	print(str(counterattack)+", "+str(counter))
	if (!counterattack && counter):
		print("counter attack!")
		attack_card_unit(target,attacker,enemy,player,true)
	
	calc_prod()
	unselect_unit()

func bombard_card_unit(attacker,target,player,enemy):
	if (cards[player][attacker].attacked || cards[player][attacker]==null || field[target].owner==player || player_points[player]<Data.calc_value(cards[player][attacker].type,"attack cost") || "no attack" in Data.data[cards[player][attacker].type] || floor(attacker/POSITIONS)!=target):
		return
	for x in range(target*POSITIONS,(target+1)*POSITIONS):
		if (cards[enemy][x]!=null):
			return
	
	var card_a = Data.data[cards[player][attacker].type]
	var card_t
	if (field[target].type!=""):
		card_t = Data.data[field[target].type]
	var damage = max(cards[player][attacker].damage-field[target].shield,0)
	for i in range(card_a["effects"].size()):
		if (card_a["events"][i]=="attack"):
			if (card_a["effects"][i]=="penetrate shield"):
				damage = cards[player][attacker].damage
			elif (card_a["effects"][i]=="bombardment 1"):
				damage += 1
			elif (card_a["effects"][i]=="bombardment 2"):
				damage += 2
			else:
				if (card_a["targets"][i]=="self"):
					apply_effect_unit(card_a["effects"][i],player,attacker)
				elif (card_a["targets"][i]=="target"):
					apply_effect_unit(card_a["effects"][i],enemy,target)
				elif (card_a["targets"][i]=="player"):
					apply_effect(player,card_a["effect"][i])
				elif (card_a["targets"][i]=="opposite"):
					apply_effect(enemy,card_a["effect"][i])
	
	if (damage<=0):
		return
	
	player_points[player] -= Data.calc_value(cards[player][attacker].type,"attack cost")
	cards[player][attacker].attacked = true
	
	var pi = load("res://scenes/effects/"+Data.data[cards[player][attacker].type]["file"]+".tscn").instance()
	var offset = Vector2(0,0)
	var pos = cards[player][attacker].node.get_global_pos()+offset
	pi.set_pos(offset)
	pi.set_scale(Vector2(1,pos.distance_to(field[target].node.get_global_pos())/800.0))
	pi.set_rot(pos.angle_to_point(field[target].node.get_global_pos())-cards[player][attacker].node.get_rot())
	cards[player][attacker].node.add_child(pi)
	field[target].structure -= damage
	if (field[target].structure<=0):
		field[target].structure = 0
		field[target].owner = player
	cards[player][attacker].update()
	field[target].update()
	
	calc_prod()
	unselect_unit()

func move_card_unit(from,to,player):
	if (cards[player][from]==null || cards[player][to]!=null || cards[player][from].moved || floor(from/POSITIONS)==floor(to/POSITIONS) || "unmoveable" in Data.data[cards[player][from].type]["effects"]):
		return
	
	var cost = Data.calc_value(cards[player][from].type,"movement cost")
	if (player_points[player]<cost):
		return
	player_points[player] -= cost
	
	add_unit(to,cards[player][from].type,player,get_node("Card_"+str(from)+"_"+str(player)).get_global_pos()-get_node("Card_"+str(to)+"_"+str(player)).get_global_pos())
	
	cards[player][to].structure = cards[player][from].structure
	cards[player][to].damage = cards[player][from].damage
	cards[player][to].shield = cards[player][from].shield
	cards[player][to].attacked = cards[player][from].attacked
	cards[player][to].moved = true
	cards[player][to].update()
	
	destroy_unit(from,player,false)
	
	unselect_unit()
	calc_prod()

func add_unit(x,ID,player,pos=Vector2(0,0)):
	cards[player][x] = Unit.new(self,ID,Data.calc_value(ID,"structure"),Data.calc_value(ID,"dmg"),Data.calc_value(ID,"shield"),Data.calc_value(ID,"level"),player,x,pos)
	if (pos==Vector2(0,0)):
		cards[player][x].node.set_pos(cards[player][x].node.get_pos()+Vector2(0,800*(0.5-player)))

func destroy_unit(x,player,explosion=true):
	cards[player][x].node.set_name("destroyed")
	if (explosion):
		cards[player][x].node.get_node("Anim").play("explode")
	else:
		cards[player][x].node.queue_free()
	cards[player][x] = null

func calc_prod():
	for p in range(NUM_PLAYERS):
		player_prod[p] = 0
		player_cost[p] = 0
		for x in range(SIZE*POSITIONS):
			if (cards[p][x]!=null):
				player_cost[p] -= cards[p][x].level*int(!("cheap" in Data.data[cards[p][x].type]["effects"]))
	for x in range(SIZE):
		if (field[x].owner>NEUTRAL):
			player_prod[field[x].owner] += field[x].production
	
	get_node("UI/Panel/VBoxContainer/Points/Label").set_text(str(player_points[PLAYER1]))
	get_node("UI/Panel/VBoxContainer/Production/Label").set_text(str(player_prod[PLAYER1]+player_cost[PLAYER1]))
	if (player_prod[PLAYER1]+player_cost[PLAYER1]<0):
		get_node("UI/Panel/VBoxContainer/Production/Label").add_color_override("font_color",Color(1.0,0.3,0.4))
	else:
		get_node("UI/Panel/VBoxContainer/Production/Label").add_color_override("font_color",Color(0.3,1.0,0.4))



func drydock(pos,player,ID):
	var target
	var thp = 9999
	for tx in range(floor(pos/POSITIONS)*POSITIONS,(floor(pos/POSITIONS)+1)*POSITIONS):
		if (cards[player][tx]!=null && (cards[player][tx].structure<thp && cards[player][tx].structure<Data.calc_value(cards[player][tx].type,"structure"))):
			thp = cards[player][tx].structure
			target = tx
	if (target!=null):
		var pi = load("res://scenes/effects/"+Data.data[ID]["file"]+".tscn").instance()
		var max_structure = Data.calc_value(cards[player][target].type,"structure")
		cards[player][target].node.add_child(pi)
		cards[player][target].structure += Data.calc_value(ID,"repair")
		if (cards[player][target].structure>max_structure):
			cards[player][target].structure = max_structure
		cards[player][target].update()

func mines(pos,enemy,damage):
	for tx in range(floor(pos/POSITIONS)*POSITIONS,(floor(pos/POSITIONS)+1)*POSITIONS):
		if (cards[enemy][tx]!=null && (cards[enemy][tx].structure>1)):
			cards[enemy][tx].structure -= damage
			print("Mines do "+str(damage)+" damage.")
			if (cards[enemy][tx].structure<1):
				cards[enemy][tx].structure = 1
			cards[enemy][tx].update()

func next_turn():
	var num_planets = 0
	var num_units = 0
	var num_units_left = 0
	turn += 1
	player = turn%NUM_PLAYERS
	print("Turn "+str(turn)+": Player "+str(player)+"'s turn.")
	
	draw_card(player)
	calc_prod()
	player_points[player] = player_prod[player]+player_cost[player]#+floor(turn/(3*NUM_PLAYERS))
	if (player_points[player]<3):
		player_points[player] = 3
	
	for i in hand[player]+deck[player]:
		if (Data.data[i]["type"]=="unit"):
			num_units_left += 1
	for x in range(SIZE*POSITIONS):
		if (cards[player][x]!=null):
			var pos = floor(x/POSITIONS)
			var card = Data.data[cards[player][x].type]
			cards[player][x].attacked = false
			cards[player][x].moved = false
			num_units += 1
			for i in range(card["effects"].size()):
				if (card["events"][i]=="player turn"):
					print(str(x)+", "+str(pos)+": player turn event")
					if (card["effects"][i]=="drydock"):
						drydock(x,player,cards[player][x].type)
					elif (card["effects"][i]=="mine damage"):
						mines(x,1-player,field[x].type)
					elif (card["effects"][i]=="self desctruction"):
						destroy_unit(x,player,false)
						num_units -= 1
					print(str(field[pos])+", "+card["targets"][i]+", "+str(field[pos].owner)+", "+str(player))
					if (field[pos]!=null && card["targets"][i]=="friendly planet" && field[pos].owner==player):
						print(str(x)+": friendly planet")
						if (card["effects"][i]=="terraform"):
							field[pos].planet = sign(PLANET_TERRAN-field[pos].planet)
						elif (card["effects"][i]=="production 1"):
							field[pos].production += 1
						elif (card["effects"][i]=="production 2"):
							field[pos].production += 2
	for x in range(SIZE):
		if (field[x]!=null && field[x].owner==player):
			num_planets += 1
		if (field[x].owner==player):
			if (field[x].structure<10):
				field[x].structure += 2
				if (field[x].structure>10):
					field[x].structure = 10
			
			if (field[x].type!=""):
				var card = Data.data[field[x].type]
				if (field[x].structure<1):
					field[x].structure = 1
				for i in range(card["effects"].size()):
					if (card["events"][i]=="player turn"):
						if (card["effects"][i]=="drydock"):
							drydock(x,player,field[x].type)
						elif (card["effects"][i]=="mine damage"):
							mines(x,1-player,Data.calc_value(field[x].type,"mine damage"))
						elif (card["effects"][i]=="self desctruction"):
							remove_card_planet(x)
		field[x].update()
	
	player_points[player] = min(player_points[player],3+floor(turn/NUM_PLAYERS))
	get_node("UI/Panel/VBoxContainer/Points/Label").set_text(str(player_points[PLAYER1]))
	
	if (num_planets==0 || (num_units==0 && num_units_left==0)):
		print("Player "+str(player)+" lost!")
		get_node("/root/Menu").end_match(player!=PLAYER1)
		queue_free()
		return
	
	if (player_is_ai[player]):
		get_node("UI/Panel/VBoxContainer/Button").set_disabled(true)
		ai_phase = 0
		ai_timer()
	else:
		get_node("UI/Panel/VBoxContainer/Button").set_disabled(false)
		# player has to select a card
		select = CARD

func draw_card(player):
	# player draws one card
	if (deck[player].size()<=0):
		print("Player "+str(player)+" has no cards left!")
		return
	
	var ID = randi()%(deck[player].size())
	hand[player].push_back(deck[player][ID])
	if (player==PLAYER1):
		add_card(hand[player].size()-1,deck[player][ID],player)
	else:
		var ci = TextureFrame.new()
		ci.set_texture(card_back)
		ci.set_name("Card"+str(hand[player].size()-1))
		get_node("UI/Cards"+str(player+1)+"/HBoxContainer").add_child(ci)
	deck[player].remove(ID)


# display cards #

func update_cards():
	for c in get_node("UI/Cards1/HBoxContainer").get_children()+get_node("UI/Cards2/HBoxContainer").get_children():
		c.set_name("deleted")
		c.queue_free()
	
#	for p in range(NUM_PLAYERS):
#		for i in range(hand[p].size()):
#			add_card(i,hand[p][i],p)
	for i in range(hand[PLAYER1].size()):
		add_card(i,hand[PLAYER1][i],PLAYER1)
	for i in range(hand[PLAYER2].size()):
		var ci = TextureFrame.new()
		ci.set_texture(card_back)
		ci.set_name("Card"+str(i))
		get_node("UI/Cards"+str(PLAYER2+1)+"/HBoxContainer").add_child(ci)
	

func add_card(index,ID,player):
	# add a new card to the container
	var bi = TextureButton.new()
	var outline = TextureFrame.new()
	var ci = Cards.create_card(ID)
	ci.set_pos(Vector2(175,250))
	ci.set_draw_behind_parent(true)
	bi.connect("pressed",self,"select_hand",[index,player])
	bi.add_child(ci)
	bi.set_custom_minimum_size(Vector2(350,500))
	bi.set_name("Card"+str(index))
	bi.set_hover_texture(select_green)
	get_node("UI/Cards"+str(player+1)+"/HBoxContainer").add_child(bi)
	outline.set_expand(true)
	outline.set_texture(select_outline)
	outline.set_modulate(Color(0.0,0.5,1.0))
	outline.set_anchor_and_margin(MARGIN_LEFT,Control.ANCHOR_BEGIN,0)
	outline.set_anchor_and_margin(MARGIN_TOP,Control.ANCHOR_BEGIN,0)
	outline.set_anchor_and_margin(MARGIN_RIGHT,Control.ANCHOR_END,0)
	outline.set_anchor_and_margin(MARGIN_BOTTOM,Control.ANCHOR_END,0)
	outline.hide()
	outline.set_name("Outline")
	bi.add_child(outline)

func remove_card(ID,player):
	# remove a card from the container
	get_node("UI/Cards"+str(player+1)+"/HBoxContainer/Card"+str(ID)).queue_free()
	get_node("UI/Cards"+str(player+1)+"/HBoxContainer/Card"+str(ID)).set_name("deleted")
	for i in range(ID+1,hand[player].size()+1):
		get_node("UI/Cards"+str(player+1)+"/HBoxContainer/Card"+str(i)).disconnect("pressed",self,"select_hand")
		get_node("UI/Cards"+str(player+1)+"/HBoxContainer/Card"+str(i)).connect("pressed",self,"select_hand",[i-1,player])
		get_node("UI/Cards"+str(player+1)+"/HBoxContainer/Card"+str(i)).set_name("Card"+str(i-1))


# set up #

func init_field():
	var size = SIZE*POSITIONS
	var array_null = []
	array_null.resize(size)
	cards.resize(NUM_PLAYERS)
	field.resize(SIZE)
	for i in range(SIZE):
		field[i] = null
	for i in range(size):
		array_null[i] = null
	for i in range(NUM_PLAYERS):
		cards[i] = []+array_null
	
	for x in range(size):
		for y in range(2):
			var ci = get_node("Card").duplicate()
			ci.set_name("Card_"+str(x)+"_"+str(y))
			ci.set_pos((Vector2(x-SIZE*POSITIONS/2.0+0.1*floor(x/POSITIONS)+0.25,-y+0.5))*Vector2(390,1100))
			ci.get_node("Button").connect("pressed",self,"select_field",[x,y])
			add_child(ci)
			ci.show()
	for x in range(SIZE):
		var pi = get_node("Card").duplicate()
		pi.set_name("Planet_"+str(x))
		pi.set_pos((Vector2(x*(POSITIONS+0.1)-SIZE*POSITIONS/2.0+1.25,0))*Vector2(390,0))
		pi.get_node("Button").connect("pressed",self,"select_planet",[x])
		add_child(pi)
		pi.show()
	
	for x in range(SIZE):
		field[x] = Planet.new(self,planets[x]["type"],planets[x]["structure"],planets[x]["damage"],planets[x]["shield"],planets[x]["level"],planets[x]["points"],planets[x]["owner"],planets[x]["image"],x)
	
	var homeworld = 0
	
	field[homeworld].owner = PLAYER1
	field[homeworld].structure = 9
	field[homeworld].planet = PLANET_TERRAN
	field[homeworld].production = 8
	
	field[SIZE-1-homeworld].owner = PLAYER2
	field[SIZE-1-homeworld].structure = 9
	field[SIZE-1-homeworld].planet = PLANET_TERRAN
	field[SIZE-1-homeworld].production = 8
	
	for i in range(SIZE):
		field[i].update()
	
	get_node("Camera").set_pos(Vector2(0,150))

func randomize_deck(player,number):
	for i in range(0.3*number):
		deck[player].push_back(Data.get_tier1_unit())
	for i in range(0.2*number):
		deck[player].push_back(Data.get_tier1_card())
	for i in range(0.25*number):
		deck[player].push_back(Data.get_tier2_unit())
	for i in range(0.1*number):
		deck[player].push_back(Data.get_tier2_card())
	for i in range(0.1*number):
		deck[player].push_back(Data.get_tier3_unit())
	for i in range(0.05*number):
		deck[player].push_back(Data.get_tier3_card())


# resize screen #

func _resize():
	var zoom = max((395.0*SIZE*POSITIONS+150.0)/OS.get_video_mode_size().x,2800.0/OS.get_video_mode_size().y)
	get_node("Camera").make_current()
	get_node("Camera").set_zoom(zoom*Vector2(1,1))
	get_node("UI/Cards1").set_size(Vector2(OS.get_video_mode_size().x/0.5-300,510))

# input #

func button_end_turn():
	if (player<0 || player_is_ai[player]):
		return
	
	unselect_hand()
	unselect_unit()
	end_turn()

func select_hand(index,player):
	if (player_is_ai[player]):
		return
	
	unselect_hand()
	if (select==CARD && Data.calc_value(hand[player][index],"level")<=player_points[player]):
		var type = Data.data[hand[player][index]]["type"]
		selected_hand = index
		get_node("UI/Cards"+str(player+1)+"/HBoxContainer/Card"+str(index)+"/Outline").show()
		if (type=="unit"):
			select = EMPTY
			for x in range(SIZE*POSITIONS):
				if (cards[player][x]==null && field[floor(x/POSITIONS)].owner==player):
					get_node("Card_"+str(x)+"_"+str(player)+"/Select").show()
					get_node("Card_"+str(x)+"_"+str(player)+"/Select").set_modulate(Color(0.0,1.0,0.0))
		elif (type=="planet"):
			var target = Data.data[hand[player][index]]["targets"][0]
			if (target=="friendly planet"):
				select = PLANET_FRIENDLY
				for x in range(SIZE):
					if (field[x]!=null && field[x].owner==player):
						get_node("Planet_"+str(x)+"/Select").show()
						get_node("Planet_"+str(x)+"/Select").set_modulate(Color(0.0,0.0,1.0))
			elif (target=="enemy planet"):
				select = PLANET_ENEMY
				for x in range(SIZE):
					if (field[x]!=null && field[x].owner!=player):
						get_node("Planet_"+str(x)+"/Select").show()
						get_node("Planet_"+str(x)+"/Select").set_modulate(Color(0.0,0.0,1.0))
		elif (type=="effect"):
			var targets = []
			var targets_type = Data.data[hand[player][index]]["targets"]
			targets.resize(targets_type.size())
			for i in range(targets_type.size()):
				for j in range(i):
					if (targets[i]==targets[j]):
						targets[i] = targets[j]
						continue
				
				if (targets_type[i]=="friendly planet"):
					select = PLANET_FRIENDLY
					for x in range(SIZE):
						if (field[x]!=null && field[x].owner==player && field[x].planet>=PLANET_BARREN && field[x].planet<=PLANET_INFERNO):
							get_node("Planet_"+str(x)+"/Select").show()
							get_node("Planet_"+str(x)+"/Select").set_modulate(Color(0.0,0.0,1.0))
				elif (targets_type[i]=="enemy planet"):
					select = PLANET_ENEMY
					for x in range(SIZE):
						if (field[x]!=null && field[x].owner!=player && field[x].planet>=PLANET_BARREN && field[x].planet<=PLANET_INFERNO):
							get_node("Planet_"+str(x)+"/Select").show()
							get_node("Planet_"+str(x)+"/Select").set_modulate(Color(0.0,0.0,1.0))
				elif (targets_type[i]=="enemy"):
					var enemy = PLAYER1
					if (player==PLAYER1):
						enemy = PLAYER2
					select = ENEMY
					for x in range(SIZE*POSITIONS):
						if (cards[enemy][x]!=null):
							get_node("Card_"+str(x)+"_"+str(enemy)+"/Select").show()
							get_node("Card_"+str(x)+"_"+str(enemy)+"/Select").set_modulate(Color(1.0,0.0,0.0))
				elif (targets_type[i]=="friendly"):
					select = FRIENDLY
					for x in range(SIZE*POSITIONS):
						if (cards[player][x]!=null):
							get_node("Card_"+str(x)+"_"+str(player)+"/Select").show()
							get_node("Card_"+str(x)+"_"+str(player)+"/Select").set_modulate(Color(0.0,0.0,1.0))
				elif (targets_type[i]=="player"):
					targets[i] = "player"
					continue
				elif (targets_type[i]=="opposite"):
					targets[i] = "opposite"
					continue
				elif (targets_type[i]=="self"):
					continue
				
				yield(self,"target_selected")
				if (selected_target==null):
					return
				targets[i] = selected_target
			
			use_card_effect(targets,selected_hand,player)

func unselect_hand():
	if (selected_hand!=null):
		get_node("UI/Cards"+str(player+1)+"/HBoxContainer/Card"+str(selected_hand)+"/Outline").hide()
		selected_hand = null
		select = CARD
		for x in range(SIZE*POSITIONS):
			for y in range(2):
				get_node("Card_"+str(x)+"_"+str(y)+"/Select").hide()
		for x in range(SIZE):
			get_node("Planet_"+str(x)+"/Select").hide()
		selected_target = null
		emit_signal("target_selected",selected_target)

func select_unit(x,p):
	if (player<0 || player_is_ai[player] || select!=CARD || cards[p][x]==null || p!=player):
		return
	
	var enemy = PLAYER1
	if (player==PLAYER1):
		enemy = PLAYER2
	selected_field = x
	select = EMPTY_OR_ENEMY
	get_node("Card_"+str(x)+"_"+str(p)+"/Select").set_modulate(Color(0.0,1.0,0.0))
	get_node("Card_"+str(x)+"_"+str(p)+"/Select").show()
	if (!cards[p][x].attacked && !("no attack" in Data.data[cards[p][x].type]["effects"]) && Data.calc_value(cards[p][x].type,"attack cost")<=player_points[player]):
		var guarded = false
		for y in get_card_targets(x,p,enemy):
			get_node("Card_"+str(y)+"_"+str(enemy)+"/Select").set_modulate(Color(1.0,0.0,0.0))
			get_node("Card_"+str(y)+"_"+str(enemy)+"/Select").show()
			guarded = true
		if (!guarded && field[floor(x/POSITIONS)].owner!=player):
			get_node("Planet_"+str(floor(x/POSITIONS))+"/Select").set_modulate(Color(1.0,0.0,0.0))
			get_node("Planet_"+str(floor(x/POSITIONS))+"/Select").show()
	if (!cards[p][x].moved && !("unmoveable" in Data.data[cards[p][x].type]["effects"]) && Data.calc_value(cards[p][x].type,"movement cost")<=player_points[player]):
		for y in range(SIZE*POSITIONS):
			if (cards[player][y]==null && floor(y/POSITIONS)!=floor(x/POSITIONS)):
				get_node("Card_"+str(y)+"_"+str(player)+"/Select").set_modulate(Color(0.0,0.25,1.0))
				get_node("Card_"+str(y)+"_"+str(player)+"/Select").show()

func unselect_unit():
	if (selected_field==null):
		return
	
	for x in range(SIZE*POSITIONS):
		for y in range(2):
			get_node("Card_"+str(x)+"_"+str(y)+"/Select").hide()
	for x in range(SIZE):
		get_node("Planet_"+str(x)+"/Select").hide()
	selected_field = null
	if (player>=0 && !player_is_ai[player]):
		select = CARD

func select_field(x,p):
	if (player<0 || player_is_ai[player]):
		return
	
	if (select==EMPTY):
		if (selected_hand!=null):
			use_card_unit(x,selected_hand,player)
			selected_target = null
			emit_signal("target_selected",selected_target)
	elif (select==CARD):
		if (cards[p][x]!=null):
			select_unit(x,p)
			selected_target = null
			emit_signal("target_selected",selected_target)
	elif (select==EMPTY_OR_ENEMY):
		if (cards[p][x]!=null && player!=p):
			attack_card_unit(selected_field,x,player,p,false)
			selected_target = null
			emit_signal("target_selected",selected_target)
		elif (cards[p][x]==null && player==p):
			move_card_unit(selected_field,x,player)
			selected_target = null
			emit_signal("target_selected",selected_target)
	elif (select==ENEMY || select==FRIENDLY):
		if (cards[p][x]!=null):
			selected_target = cards[p][x]
			emit_signal("target_selected",selected_target)

func select_planet(x):
	if (player<0 || player_is_ai[player]):
		return
	
	var enemy = PLAYER1
	if (player==PLAYER1):
		enemy = PLAYER2
	if (select==PLANET_FRIENDLY):
		if (field[x]!=null && field[x].owner==player):
			if (Data.data[hand[player][selected_hand]]["type"]=="planet"):
				use_card_planet(x,selected_hand,player)
				return
			selected_target = field[x]
			emit_signal("target_selected",selected_target)
	elif (select==PLANET_ENEMY):
		if (field[x]!=null && field[x].owner!=player):
			if (Data.data[hand[player][selected_hand]]["type"]=="planet"):
				use_card_planet(x,selected_hand,player)
				return
			selected_target = field[x]
			emit_signal("target_selected",selected_target)
	elif (select==EMPTY_OR_ENEMY):
		var guarded = false
		for x1 in range(x*POSITIONS,(x+1)*POSITIONS):
			if (cards[enemy][x1]!=null):
				guarded = true
		if (!guarded && field[x].owner!=player):
			bombard_card_unit(selected_field,x,player,enemy)
			selected_target = null
			emit_signal("target_selected",selected_target)

func _input(event):
	if (player<0 || player_is_ai[player]):
		return
	
	if (event.type==InputEvent.MOUSE_BUTTON && event.pressed && event.button_index==2):
		if (select!=NONE):
			unselect_hand()
			unselect_unit()
			select = CARD

func _process(delta):
	get_node("UI/Panel/Points").set_text(str(player_points[PLAYER1]))
	get_node("UI/Panel/Income").set_text(str(player_prod[PLAYER1]-player_cost[PLAYER1]))
	if (player_prod[PLAYER1]<player_cost[PLAYER1]):
		get_node("UI/Panel/Income").add_color_override("font_color",Color(1.0,0.3,0.4))
	else:
		get_node("UI/Panel/Income").add_color_override("font_color",Color(0.3,1.0,0.4))

func _ready():
	set_process_input(true)
	get_tree().connect("screen_resized",self,"_resize")
	_resize()
	add_user_signal("target_selected",[{"name":"target_selected","type":TYPE_OBJECT}])
	
	init_field()
	
	# add 4 cards for each player
	for p in range(NUM_PLAYERS):
		var num_cards = 4
		hand[p].resize(num_cards)
		for i in range(num_cards):
			var ID = randi()%(deck[p].size())
			hand[p][i] = deck[p][ID]
			deck[p].remove(ID)
	
	calc_prod()
	update_cards()
	ai = ai_class.new(PLAYER2,hand,cards,field,SIZE,POSITIONS)
	
	get_node("TimerNextTurn").start()
