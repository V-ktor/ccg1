extends Node

# constants #

var SIZE = 4
var POSITIONS = 2
var NUM_START_CARDS = 4
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
const PLAYER1 = 0 # player
const PLAYER2 = 1 # enemy
const COLOURS = {NEUTRAL:Color(1.0,1.0,1.0),PLAYER1:Color(0.2,0.4,1.0),PLAYER2:Color(1.0,0.3,0.2)}
const NONE = -1
const CARD = 0
const EMPTY = 1
const ENEMY = 2
const FRIENDLY = 3
const PLANET_FRIENDLY = 4
const PLANET_ENEMY = 5
const EMPTY_OR_ENEMY = 6
const DISCARD = 7


# variables #

var planets = []
var player_is_ai = [false,true]
var deck = [[],[]]
var hand = [[],[]]
var player = NEUTRAL
var player_points = [{},{}]
var player_used_points = [{},{}]
var selected_hand
var selected_field
var cards = []
var field = []
var turn = -1
var select = NONE
var selected_target
var hand_offset = 0
var started = false
var discard = []
var player_name = []
var main_player = PLAYER1
var ID
var ID_enemy
var ready = false
var tutorial = false

var script_card_hand = preload("res://scripts/cards/card_hand.gd")
var point_textures = {
	"empire":[preload("res://images/ui/point_empire_available.png"),preload("res://images/ui/point_empire_used.png")],
	"rebels":[preload("res://images/ui/point_rebels_available.png"),preload("res://images/ui/point_rebels_used.png")],
	"pirates":[preload("res://images/ui/point_pirates_available.png"),preload("res://images/ui/point_pirates_used.png")]
}


# signals #

signal target_selected(target_selected)
signal new_turn()
signal init_discarded()
signal started()
signal unit_used()
signal unit_moved()
signal unit_attacked()
signal unit_invaded()
signal discarded()


# classes #

class Card:
	var structure
	var damage
	var shield
	var points
	var cards
	var level
	var type
	var node
	var root

class Unit:
	extends Card
	var attacked
	var moved
	
	func _init(_root,_type,_structure,_damage,_shield,_level,player,pos,pos0,rot):
		root = _root
		node = Cards.create_card(_type)
		structure = _structure
		damage = _damage
		shield = _shield
		level = _level
		type = _type
		attacked = false
		moved = false
		
		node.set_draw_behind_parent(true)
		node.set_name("Card")
		node.set_rotation(rot*PI)
		node.get_node("Description").set_rotation(-rot*PI)
		root.get_node("Card_"+str(pos)+"_"+str(player)).add_child(node)
		node.set_process(true)
		node.set_position(pos0)
		
		update()
	
	func update():
		if (structure<0):
			structure = 0
		Cards.update_values(node,level,structure,damage,shield)
		node.get_node("VBoxContainer/Structure").show()
		node.get_node("Effects/Attack").set_visible(!attacked)
		node.get_node("Effects/Movement").set_visible(!moved)

class Planet:
	extends Card
	var owner
	var planet
	var image
	var revolt
	
	func _init(_root,_type,_structure,_damage,_shield,_level,_cards,_owner,_image,pos):
		var img = Sprite.new()
		root = _root
		node = Cards.base.instance()
		node.set_draw_behind_parent(true)
		node.set_name("Card")
		img.set_name("Image")
		node.get_node("Type").set_texture(Cards.icon_type["planet"])
		node.get_node("Logo").hide()
		node.get_node("Image").add_child(img)
		structure = _structure
		damage = _damage
		shield = _shield
		level = _level
		cards = _cards
		planet = _type
		points = {}
		type = ""
		owner = _owner
		image = _image
		revolt = false
		
		root.get_node("Planet_"+str(pos)).add_child(node)
		node.set_process(true)
		
		update()
	
	func update():
		Cards.update_values(node,level,structure,damage,shield,cards,points)
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
			var effects = Data.data[type]["effects"]
			var targets = Data.data[type]["targets"]
			var events = Data.data[type]["events"]
			node.get_node("Name").set_text(tr(Data.data[type]["name"].to_upper()))
			for c in node.get_node("Description/ScrollContainer/VBoxContainer").get_children()+node.get_node("Effects").get_children():
				if (c.get_name()!="Effect"):
					c.set_name("deleted")
					c.queue_free()
			for i in range(effects.size()):
				var t = effects[i]+"-"+targets[i]+"-"+events[i]
				var pi = node.get_node("Description/Effect").duplicate()
				if (Cards.icon_effect.has(t)):
					var ti = node.get_node("Effects/Effect").duplicate()
					ti.set_texture(Cards.icon_effect[t])
					ti.set_name("Effect"+str(i))
					ti.show()
					node.get_node("Effects").add_child(ti)
				pi.set_name("Effect"+str(i))
				pi.get_node("Name").set_text(tr(t.to_upper().replace(" ","_")))
				pi.get_node("Desc").set_text(tr(t.to_upper().replace(" ","_")+"_DESC"))
				node.get_node("Description/ScrollContainer/VBoxContainer").add_child(pi)


# other graphics #

var select_outline = preload("res://images/ui/card_select.png")
var select_green = preload("res://images/ui/card_select_green.png")
var card_back = preload("res://images/cards/card_back.png")


# AI functions #

var ai_class = preload("res://scripts/ai/ai_base.gd")
var ai

func ai_timer():
	get_node("AiTimer").set_wait_time(0.25)
	
	var action
	ai.update()
	action = ai.get_action()
	printt("AI ACTION:",action)
	if (action==null):
		get_node("TimerNextTurn").start()
		return
	var f = action["function"]
	callv(f,action["arguments"])
	
	if (f=="move_unit"):
		get_node("AiTimer").set_wait_time(1.0)
	elif (f=="attack_unit"):
		get_node("AiTimer").set_wait_time(2.0)
	elif (f=="bombard_unit"):
		get_node("AiTimer").set_wait_time(1.0)
	elif (f=="discard_hand"):
		get_node("AiTimer").set_wait_time(0.5)
	
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
	
	field[pos].shield -= Data.calc_value(field[pos].type,"shield")
	field[pos].type = ""
	field[pos].level = 0
	for f in field[pos].points.keys():
		player_points[field[pos].owner][f] -= field[pos].points[f]
	field[pos].points.clear()
	field[pos].update()

func add_card_planet(pos,ID):
	var card = Data.data[ID]
	field[pos].shield += Data.calc_value(ID,"shield")
	field[pos].type = ID
	field[pos].level = card["level"]*(1-int("cheap" in card["effects"]))
	if (card["effects"].has("production 2")):
		field[pos].points[card["faction"]] = 2
		player_points[field[pos].owner][card["faction"]] += 2
		player_used_points[field[pos].owner][card["faction"]] += 2
	field[pos].update()

func end_turn():
	player = NEUTRAL
	select = NONE
	get_node("TimerNextTurn").start()

remote func use_card_effect(targets,ID,player):
	printt("use effect card",targets,ID,player,hand[player][ID])
	var faction = Data.data[hand[player][ID]]["faction"]
	if (Data.calc_value(hand[player][ID],"level")>player_points[player][faction]-player_used_points[player][faction]):
		return
	
	var effects = Data.data[hand[player][ID]]["effects"]
	var type = Data.data[hand[player][ID]]["targets"]
	var enemy = PLAYER1
	if (player==PLAYER1):
		enemy = PLAYER2
	for i in range(type.size()):
		if (type[i]=="friendly"):
			targets[i] = cards[player][targets[i]]
		elif (type[i]=="enemy"):
			targets[i] = cards[enemy][targets[i]]
		elif (type[i]=="friendly planet" || type[i]=="enemy planet"):
			targets[i] = field[targets[i]]
	for i in range(effects.size()):
		if (typeof(targets[i])==TYPE_STRING):
			if (targets[i]=="player"):
				apply_effect(player,effects[i])
			elif (targets[i]=="opposite"):
				apply_effect(enemy,effects[i])
		else:
			apply_effect_target(effects[i],player,enemy,targets[i],hand[player][ID])
	
	player_used_points[player][Data.data[hand[player][ID]]["faction"]] += Data.calc_value(hand[player][ID],"level")
	unselect_hand()
	hand[player].remove(ID)
	update_resources()
	
	remove_card(ID,player)
	update_cards()

remote func use_card_planet(x,ID,player):
	printt("use planet card",x,ID,player)
	var faction = Data.data[hand[player][ID]]["faction"]
	if (Data.calc_value(hand[player][ID],"level")>player_points[player][faction]-player_used_points[player][faction]):
		return
	
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
	
	player_used_points[player][Data.data[hand[player][ID]]["faction"]] += Data.calc_value(hand[player][ID],"level")
	unselect_hand()
	hand[player].remove(ID)
	update_resources()
	
	remove_card(ID,player)

remote func use_card_unit(x,ID,player):
	var card = Data.data[hand[player][ID]]
	if (cards[player][x]!=null || (field[floor(x/POSITIONS)].owner!=player && !field[floor(x/POSITIONS)].revolt && !("partisan" in card["effects"])) || Data.calc_value(hand[player][ID],"level")>player_points[player][card["faction"]]-player_used_points[player][card["faction"]]):
		return
	
	var enemy = abs(1-player)
	add_unit(x,hand[player][ID],player)
	
	for i in range(card["events"].size()):
		if (card["events"][i]=="spawn"):
			if (card["targets"][i]=="self"):
				apply_effect_target(card["effects"][i],player,enemy,cards[player][x],hand[player][ID])
			elif (card["targets"][i]=="player"):
				apply_effect(player,card["effects"][i])
			elif (card["targets"][i]=="opposite"):
				for p in range(NUM_PLAYERS):
					if (p!=player):
						apply_effect(player,card["effects"][i])
	
	player_used_points[player][Data.data[hand[player][ID]]["faction"]] += Data.calc_value(hand[player][ID],"level")
	unselect_hand()
	hand[player].remove(ID)
	update_resources()
	
	remove_card(ID,player)
	update_cards()
	emit_signal("unit_used")

func apply_effect(player,effect):
	if (effect=="draw 2"):
		for k in range(2):
			if (main_player==0):
				draw_card(player)
	elif (effect=="draw 3"):
		for k in range(3):
			if (main_player==0):
				draw_card(player)
	elif (effect=="remove 2"):
		if (main_player==0):
			remove_cards(player,2)
	elif (effect=="remove 3"):
		if (main_player==0):
			remove_cards(player,3)
	

func remove_cards(player,num):
	for k in range(min(num,hand[player].size())):
		var ID = randi()%(hand[player].size())
		if (get_tree().has_network_peer()):
			rpc("remove_card_ID",player,ID)
		else:
			remove_card_ID(player,ID)

func remove_card_ID(player,ID):
	hand[player].remove(ID)

func apply_effect_target(effect,player,enemy,target,ID):
	var ps = load("res://scenes/effects/"+Data.data[ID]["file"]+".tscn")
	if (ps!=null):
		target.node.add_child(ps.instance())
	if (effect=="direct damage 4" || effect=="direct damage 6"):
		target.structure -= Data.calc_value(ID,"dmg")
		target.update()
		if (target.structure<=0):
			var x
			for y in range(SIZE*POSITIONS):
				if (cards[enemy][y]==target):
					x = y
					break
			if (x!=null):
				destroy_unit(x,enemy)
	elif (effect=="increase dmg 2"):
		target.damage += 2
	elif (effect=="armor 2"):
		target.structure += 2
	elif (effect=="reduce structure 1"):
		target.structure = max(target.structure-1,1)
	elif (effect=="reduce dmg 2"):
		target.damage = max(target.damage-2,0)
	elif (effect=="shield 1"):
		target.shield += 1
	elif (effect=="jam 1"):
		target.shield = max(target.shield-1,0)
	elif (effect=="repair 4"):
		target.structure = min(target.structure+4,max(target.structure,Data.calc_value(target.type,"structure")))
	elif (effect=="repair 5"):
		target.structure = min(target.structure+5,max(target.structure,Data.calc_value(target.type,"structure")))
	elif (effect=="repair 6"):
		target.structure = min(target.structure+6,max(target.structure,Data.calc_value(target.type,"structure")))
	elif (effect=="terraform"):
		target.planet += sign(PLANET_TERRAN-target.planet)
	elif (effect=="defense 4"):
		target.structure += 4
	elif (effect=="defense 6"):
		target.structure += 6
	elif (effect=="reduce dmg 1"):
		target.damage = max(target.damage-1,0)
	elif (effect=="reduce dmg 2"):
		target.damage = max(target.damage-2,0)
	elif (effect=="reduce cost 4"):
		target.level = max(target.level-4,0)
	elif (effect=="cheap"):
		target.level = 0
	elif (effect=="points 1"):
		player_used_points[player][Data.data[ID]["faction"]] = max(player_used_points[player][Data.data[ID]["faction"]]-1,0)
		update_resources()
	elif (effect=="points 2"):
		player_used_points[player][Data.data[ID]["faction"]] = max(player_used_points[player][Data.data[ID]["faction"]]-2,0)
		update_resources()
	elif (effect=="take over"):
		target.structure = 0
		target.owner = player
		target.update()
	elif (effect=="revolt"):
		target.revolt = true
	
	if (target!=null):
		target.update()


remote func attack_unit(attacker,target,player,enemy,counterattack=false):
	if (cards[player][attacker]==null || (cards[player][attacker].attacked && !counterattack) || cards[enemy][target]==null || ("no attack" in Data.data[cards[player][attacker].type]["effects"] && !counterattack) || floor(attacker/POSITIONS)!=floor(target/POSITIONS)):
		return
	
	var card_a = Data.data[cards[player][attacker].type]
	var card_t = Data.data[cards[enemy][target].type]
	var damage = max(cards[player][attacker].damage-cards[enemy][target].shield,0)
	var capture = false
	var counter = false
	var t_pos = cards[enemy][target].node.get_global_position()
	for i in range(card_a["effects"].size()):
		if (card_a["events"][i]=="attack"):
			if (card_a["effects"][i]=="penetrate shield"):
				damage = cards[player][attacker].damage
			elif (card_a["effects"][i]=="capture"):
				capture = cards[enemy][target].structure<=damage
			else:
				if (card_a["targets"][i]=="self"):
					apply_effect_target(card_a["effects"][i],player,enemy,cards[player][attacker],cards[player][attacker].type)
				elif (card_a["targets"][i]=="target"):
					apply_effect_target(card_a["effects"][i],player,enemy,cards[enemy][target],cards[player][attacker].type)
				elif (card_a["targets"][i]=="player"):
					apply_effect(player,card_a["effect"][i])
				elif (card_a["targets"][i]=="opposite"):
					apply_effect(enemy,card_a["effect"][i])
	for i in range(card_t["effects"].size()):
		if (card_t["events"][i]=="attacked"):
			if (card_t["targets"][i]=="attacker"):
				if (card_t["effects"][i]=="counterattack"):
					counter = true
			elif (card_t["targets"][i]=="self"):
				apply_effect_target(card_t["effects"][i],enemy,player,cards[enemy][target],cards[enemy][target].type)
			elif (card_t["targets"][i]=="target"):
				apply_effect_target(card_t["effects"][i],enemy,player,cards[player][attacker],cards[enemy][target].type)
			elif (card_t["targets"][i]=="player"):
				apply_effect(enemy,card_t["effect"][i])
			elif (card_t["targets"][i]=="opposite"):
				apply_effect(player,card_t["effect"][i])
	
	if (damage<=0):
		return
	
	if (!counterattack):
		cards[player][attacker].attacked = true
	
	if (capture):
		var pi = load("res://scenes/effects/"+Data.data[cards[player][attacker].type]["file"]+".tscn").instance()
		var pos = cards[player][attacker].node.get_global_position()
		pi.set_scale(Vector2(1,pos.distance_to(cards[enemy][target].node.get_global_position())/800.0))
		pi.set_global_position(pos)
		pi.set_rotation(pos.angle_to_point(cards[enemy][target].node.get_global_position())-PI/2.0)
		add_child(pi)
		destroy_unit(attacker,player)
		add_unit(attacker,cards[enemy][target].type,player)
		cards[player][attacker].structure = cards[enemy][target].structure
		cards[player][attacker].damage = cards[enemy][target].damage
		cards[player][attacker].shield = cards[enemy][target].shield
		cards[player][attacker].attacked = true
		cards[player][attacker].moved = true
		cards[player][attacker].update()
		destroy_unit(target,enemy,false)
		counter = false
	else:
		var pi = load("res://scenes/effects/"+Data.data[cards[player][attacker].type]["file"]+".tscn").instance()
		var pos = cards[player][attacker].node.get_global_position()
		pi.set_scale(Vector2(1,pos.distance_to(cards[enemy][target].node.get_global_position())/800.0))
		pi.set_global_position(pos)
		pi.set_rotation(pos.angle_to_point(cards[enemy][target].node.get_global_position())-PI/2.0)
		add_child(pi)
		cards[enemy][target].structure -= damage
		cards[player][attacker].update()
		cards[enemy][target].update()
		if (cards[enemy][target].structure<=0):
			destroy_unit(target,enemy)
			counter = false
	
	if (!counterattack && counter):
		attack_unit(target,attacker,enemy,player,true)
	
	update_resources()
	unselect_unit()
	emit_signal("unit_attacked")
	
	if (capture):
		var timer = Timer.new()
		timer.set_one_shot(true)
		timer.set_wait_time(1.0)
		add_child(timer)
		timer.start()
		
		yield(timer,"timeout")
		cards[player][attacker].node.set_global_position(t_pos)
		cards[player][attacker].node.set_rotation(-(player+main_player)*PI)
		cards[player][attacker].node.get_node("Description").set_rotation(-(player+main_player)*PI)

remote func bombard_unit(attacker,target,player,enemy):
	if (cards[player][attacker]==null || cards[player][attacker].attacked || field[target].owner==player || "no attack" in Data.data[cards[player][attacker].type] || floor(attacker/POSITIONS)!=target):
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
					apply_effect_target(card_a["effects"][i],player,enemy,cards[player][attacker],cards[player][attacker].type)
				elif (card_a["targets"][i]=="target"):
					apply_effect_target(card_a["effects"][i],player,enemy,cards[enemy][target],cards[player][attacker].type)
				elif (card_a["targets"][i]=="player"):
					apply_effect(player,card_a["effect"][i])
				elif (card_a["targets"][i]=="opposite"):
					apply_effect(enemy,card_a["effect"][i])
	
	if (damage<=0):
		return
	
	cards[player][attacker].attacked = true
	
	var pi = load("res://scenes/effects/"+Data.data[cards[player][attacker].type]["file"]+".tscn").instance()
	var offset = Vector2(0,0)
	var pos = cards[player][attacker].node.get_global_position()+offset
	pi.set_position(offset)
	pi.set_scale(Vector2(1,pos.distance_to(field[target].node.get_global_position())/800.0))
	pi.set_global_position(pos)
	pi.set_rotation(pos.angle_to_point(field[target].node.get_global_position())-PI/2.0)
	add_child(pi)
	field[target].structure -= damage
	if (field[target].structure<=0):
		field[target].structure = 0
		field[target].owner = player
	cards[player][attacker].update()
	field[target].update()
	
	update_resources()
	unselect_unit()
	emit_signal("unit_invaded")

remote func move_unit(from,to,player):
	if (cards[player][from]==null || cards[player][to]!=null || cards[player][from].moved || floor(from/POSITIONS)==floor(to/POSITIONS) || "unmoveable" in Data.data[cards[player][from].type]["effects"]):
		return
	
	add_unit(to,cards[player][from].type,player,get_node("Card_"+str(from)+"_"+str(player)).get_global_position()-get_node("Card_"+str(to)+"_"+str(player)).get_global_position())
	
	cards[player][to].level = cards[player][from].level
	cards[player][to].structure = cards[player][from].structure
	cards[player][to].damage = cards[player][from].damage
	cards[player][to].shield = cards[player][from].shield
	cards[player][to].attacked = cards[player][from].attacked
	cards[player][to].moved = true
	cards[player][to].update()
	
	destroy_unit(from,player,false)
	
	unselect_unit()
	update_resources()
	emit_signal("unit_moved")

func add_unit(x,ID,player,pos=Vector2(0,0)):
	cards[player][x] = Unit.new(self,ID,Data.calc_value(ID,"structure"),Data.calc_value(ID,"dmg"),Data.calc_value(ID,"shield"),Data.calc_value(ID,"level"),player,x,pos,player+main_player)
	if (pos==Vector2(0,0)):
		cards[player][x].node.set_position(cards[player][x].node.get_position()+Vector2(0,800*(0.5-player)))

func destroy_unit(x,player,explosion=true):
	cards[player][x].node.set_name("destroyed")
	if (explosion):
		cards[player][x].node.get_node("Anim").play("explode")
	else:
		cards[player][x].node.queue_free()
	cards[player][x] = null

func update_resources():
	for p in range(NUM_PLAYERS):
		get_node("UI/Player"+str(int(p!=main_player)+1)+"/VBoxContainer/Deck/Label").set_text(str(deck[p].size()))
		for f in player_points[p].keys():
			for c in get_node("UI/Player"+str(int(p!=main_player)+1)+"/VBoxContainer/Points"+f.capitalize()).get_children():
				c.hide()
			for i in range(player_points[p][f]):
				var cols = max(floor(player_points[p][f]/3)+1,4)
				get_node("UI/Player"+str(int(p!=main_player)+1)+"/VBoxContainer/Points"+f.capitalize()).set_custom_minimum_size(Vector2(160+16*(cols-4),80))
				if (has_node("UI/Player"+str(int(p!=main_player)+1)+"/VBoxContainer/Points"+f.capitalize()+"/Point"+str(i))):
					get_node("UI/Player"+str(int(p!=main_player)+1)+"/VBoxContainer/Points"+f.capitalize()+"/Point"+str(i)).set_texture(point_textures[f][0])
					get_node("UI/Player"+str(int(p!=main_player)+1)+"/VBoxContainer/Points"+f.capitalize()+"/Point"+str(i)).show()
				else:
					var pi = get_node("UI/Player"+str(int(p!=main_player)+1)+"/VBoxContainer/Points"+f.capitalize()+"/Point0").duplicate()
					pi.set_name("Point"+str(i))
					pi.set_position(Vector2(88,16)+Vector2(16*floor(i/3),16*(i%3)))
					get_node("UI/Player"+str(int(p!=main_player)+1)+"/VBoxContainer/Points"+f.capitalize()).add_child(pi)
					pi.show()
			for i in range(max(player_points[p][f]-player_used_points[p][f],0),player_points[p][f]):
				get_node("UI/Player"+str(int(p!=main_player)+1)+"/VBoxContainer/Points"+f.capitalize()+"/Point"+str(i)).set_texture(point_textures[f][1])
				get_node("UI/Player"+str(int(p!=main_player)+1)+"/VBoxContainer/Points"+f.capitalize()+"/Point"+str(i)).show()
	



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

func _next_turn():
	if (!started):
		discard_cards()
	elif (player==main_player):
		if (get_tree().has_network_peer()):
			rpc("next_turn")
		else:
			next_turn()

remote func next_turn():
	if (!started):
		discard_cards()
		return
	
	var num_planets = 0
	var num_units = 0
	var num_units_left = 0
	turn += 1
	player = turn%NUM_PLAYERS
	print("Turn "+str(turn)+": Player "+str(player)+"'s turn.")
	emit_signal("new_turn")
	
	if (main_player==0 && turn>0):
		draw_card(player)
		if (turn>=NUM_PLAYERS):
			for x in range(SIZE):
				if (field[x]!=null && field[x].owner==player):
					draw_card(player)
	for f in player_used_points[player].keys():
		player_used_points[player][f] = 0
	
	for i in hand[player]+deck[player]:
		if (Data.data[i]["type"]=="unit"):
			num_units_left += 1
	for x in range(SIZE*POSITIONS):
		if (cards[player][x]!=null):
			var pos = floor(x/POSITIONS)
			var card = Data.data[cards[player][x].type]
			cards[player][x].attacked = false #!("no attack" in card["effects"])
			cards[player][x].moved = false #!("unmoveable" in card["effects"])
			num_units += 1
#			cards[player][x].level = max(cards[player][x].level-1,1)
			if (player_used_points[player].has(card["faction"])):
				player_used_points[player][card["faction"]] += cards[player][x].level
			for i in range(card["effects"].size()):
				if (card["events"][i]=="player turn"):
					if (card["effects"][i]=="drydock"):
						drydock(x,player,cards[player][x].type)
					elif (card["effects"][i]=="mines 1"):
						mines(x,1-player,Data.calc_value(cards[player][x].type,"mine damage"))
					elif (card["effects"][i]=="self desctruction"):
						destroy_unit(x,player,false)
						num_units -= 1
			cards[player][x].update()
	for x in range(SIZE):
		field[x].revolt = false
		if (field[x].owner==player):
			num_planets += 1
			if (field[x].structure<20):
				field[x].structure += 2
				if (field[x].structure>20):
					field[x].structure = 20
#			field[x].level = max(field[x].level-1,1)
			
			if (field[x].type!=""):
				var card = Data.data[field[x].type]
				if (field[x].structure<1):
					field[x].structure = 1
				for f in field[x].points.keys():
					player_points[player][f] += field[x].points[f]
				for i in range(card["effects"].size()):
					if (card["events"][i]=="player turn"):
						if (card["effects"][i]=="drydock"):
							drydock(x,player,field[x].type)
						elif (card["effects"][i]=="mines 1" || card["effects"][i]=="mines 2"):
							mines(x,1-player,Data.calc_value(field[x].type,"mine damage"))
						elif (card["effects"][i]=="spawn light_fighter"):
							var pos = -1
							for y in range(POSITIONS):
								if (cards[player][x*POSITIONS+y]==null):
									pos = x*POSITIONS+y
									break
							if (pos>=0):
								add_unit(pos,"light_fighter",player)
						elif (card["effects"][i]=="self desctruction"):
							remove_card_planet(x)
		field[x].update()
	for f in player_used_points[player].keys():
		if (player_used_points[player][f]>player_points[player][f]):
			player_used_points[player][f] = player_points[player][f]
	update_resources()
	
	if (num_planets==0 || deck[player].size()+hand[player].size()==0):
		print("Player "+str(player)+" lost!")
		get_node("/root/Menu").end_match(player!=main_player,(player+1)%2)
		return
	
	if (player_is_ai[player]):
		get_node("UI/Player1/VBoxContainer/Button").set_disabled(true)
		ai.reset()
		ai_timer()
	else:
		get_node("UI/Player1/VBoxContainer/Button").set_disabled(player!=main_player)
		# player has to select a card
		select = CARD

func draw_card(player):
	# player draws one card
	var ID
	if (main_player==PLAYER1):
		ID = get_card_from_deck(player)
	if (ID!=null):
		if (get_tree().has_network_peer()):
			rpc("draw_card_ID",player,ID)
		else:
			draw_card_ID(player,ID)

remote func get_card_from_deck(player):
	if (deck[player].size()<1):
		return
	return randi()%(deck[player].size())

remote func draw_card_ID(player,ID):
	hand[player].push_back(deck[player][ID])
	if (player==main_player):
		add_card(hand[player].size()-1,deck[player][ID],player)
	else:
		var ci = TextureRect.new()
		ci.set_texture(card_back)
		ci.set_name("Card"+str(hand[player].size()-1))
		ci.set_mouse_filter(Control.MOUSE_FILTER_IGNORE)
		ci.set_script(script_card_hand)
		ci.connect("gui_input",ci,"_input_event")
		ci.set_position(Vector2(get_node("UI/Cards2").get_size().x+250,0))
		get_node("UI/Cards2").add_child(ci)
	deck[player].remove(ID)

func _select_discard(pressed,ID):
	if (pressed):
		if !(ID in discard[PLAYER1]):
			discard[PLAYER1].push_back(ID)
	else:
		discard[PLAYER1].erase(ID)

func discard_cards():
	var timer = Timer.new()
	timer.set_one_shot(true)
	timer.set_wait_time(1.0)
	add_child(timer)
	
	for p in range(NUM_PLAYERS):
		if (!player_is_ai[p] && p!=main_player):
			continue
		
		var h
		if (player_is_ai[p]):
			discard[p] = ai.discard(hand[p])
		for ID in discard[p]:
			hand[p].erase(ID)
		h = []+hand[p]
		hand[p].clear()
		if (get_tree().has_network_peer()):
			rpc("set_hand",p,h)
		else:
			set_hand(p,h)
	get_node("UI/Player1/VBoxContainer/Button").set_text(tr("END_TURN"))
	for c in get_node("UI/HBoxContainer").get_children():
		c.target_pos = Vector2(-300,800)
	timer.start()
	emit_signal("init_discarded")
	
	yield(timer,"timeout")
	get_node("UI/HBoxContainer").hide()
	timer.queue_free()

func start():
	for p in range(NUM_PLAYERS):
		for i in range(NUM_START_CARDS-hand[p].size()):
			if (main_player==PLAYER1):
				draw_card(p)
			else:
				rpc_id(1,"draw_card",p)
	update_cards()
	started = true
	emit_signal("started")
	get_node("TimerNextTurn").start()

remote func set_hand(player,cards):
	print("set hand",player,cards)
	hand[player] = cards
	for ID in cards:
		deck[player].erase(ID)
	if (ready):
		start()
	else:
		ready = true

remote func discard_hand(ID):
	printt("discard card ",ID,hand[player][ID])
	player_points[player][Data.data[hand[player][ID]]["faction"]] += 1
	player_used_points[player][Data.data[hand[player][ID]]["faction"]] += 1
	hand[player].remove(ID)
	remove_card(ID,player)
	unselect_hand()
	update_resources()
	emit_signal("discarded")

func _discard_hand():
	if (selected_hand!=null):
		if (get_tree().has_network_peer()):
			rpc("discard_hand",selected_hand)
		else:
			discard_hand(selected_hand)


# display cards #

func update_cards():
	for c in get_node("UI/Cards1").get_children()+get_node("UI/Cards2").get_children():
		c.hide()
	
	for i in range(hand[main_player].size()):
		if (!has_node("UI/Cards1/Card"+str(i))):
			add_card(i,hand[main_player][i],main_player)
		else:
			var bi = get_node("UI/Cards1/Card"+str(i))
			if (!bi.has_node("Card") || bi.get_node("Card").ID!=hand[main_player][i]):
				var ci = Cards.create_card(i)
				if (bi.has_node("Card")):
					bi.get_node("Card").queue_free()
					bi.get_node("Card").set_name("deleted")
				ci.set_position(Vector2(175,250))
				ci.set_draw_behind_parent(true)
				bi.add_child(ci)
			bi.show()
	for i in range(hand[(main_player+1)%2].size()):
		if (!has_node("UI/Cards2/Card"+str(i))):
			var ci = TextureRect.new()
			ci.set_texture(card_back)
			ci.set_name("Card"+str(i))
			ci.set_mouse_filter(Control.MOUSE_FILTER_IGNORE)
			ci.set_script(script_card_hand)
			ci.connect("gui_input",ci,"_input_event")
			ci.set_position(Vector2(get_node("UI/Cards2").get_size().x+250,0))
			get_node("UI/Cards2").add_child(ci)
		else:
			get_node("UI/Cards2/Card"+str(i)).show()
	

func add_card(index,ID,player):
	# add a new card to the container
	var bi = TextureButton.new()
	var outline = TextureRect.new()
	var ci = Cards.create_card(ID)
	ci.set_position(Vector2(175,250))
	ci.set_draw_behind_parent(true)
	bi.connect("pressed",self,"select_hand",[index,player])
	bi.set_custom_minimum_size(Vector2(350,500))
	bi.set_name("Card"+str(index))
	bi.set_hover_texture(select_green)
	bi.set_script(script_card_hand)
	bi.connect("gui_input",bi,"_input_event")
	bi.set_position(Vector2(-250,0))
	get_node("UI/Cards1").add_child(bi)
	bi.add_child(ci)
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
	get_node("UI/Cards"+str(int(player!=main_player)+1)+"/Card"+str(ID)).queue_free()
	get_node("UI/Cards"+str(int(player!=main_player)+1)+"/Card"+str(ID)).set_name("deleted")
	for i in range(ID+1,hand[player].size()+1):
		if (get_node("UI/Cards"+str(int(player!=main_player)+1)+"/Card"+str(i)).is_connected("pressed",self,"select_hand")):
			get_node("UI/Cards"+str(int(player!=main_player)+1)+"/Card"+str(i)).disconnect("pressed",self,"select_hand")
			get_node("UI/Cards"+str(int(player!=main_player)+1)+"/Card"+str(i)).connect("pressed",self,"select_hand",[i-1,player])
		get_node("UI/Cards"+str(int(player!=main_player)+1)+"/Card"+str(i)).set_name("Card"+str(i-1))

func update_discard_cards():
	discard.resize(NUM_PLAYERS)
	for i in range(NUM_PLAYERS):
		discard[i] = []
	for c in get_node("UI/HBoxContainer").get_children():
		c.set_name("deleted")
		c.queue_free()
	for i in range(hand[main_player].size()):
		var bi
		var ci = Cards.create_card(hand[main_player][i])
		if (!has_node("UI/HBoxContainer/Button"+str(i))):
			bi = get_node("UI/Card").duplicate()
			bi.set_name("Button"+str(i))
			get_node("UI/HBoxContainer").add_child(bi)
		else:
			bi = get_node("UI/HBoxContainer/Button"+str(i))
		bi.connect("toggled",self,"_select_discard",[hand[main_player][i]])
		bi.connect("gui_input",bi,"_input_event")
		ci.set_position(Vector2(5+175/2.0,250/2.0))
		ci.set_scale(Vector2(0.5,0.5))
		bi.add_child(ci)
		bi.show()
		bi.set_pressed(false)
		bi.target_pos = Vector2(150+200*i,500)
		bi.set_position(Vector2(-300,800))
	
	get_node("UI/HBoxContainer").show()
	get_node("UI/Player1/VBoxContainer/Button").set_text(tr("CONFIRM"))


# set up #

func draw_init():
	hand[main_player].resize(NUM_START_CARDS)
	for i in range(NUM_START_CARDS):
		var ID = randi()%(deck[main_player].size())
		hand[main_player][i] = deck[main_player][ID]
	
	for p in range(NUM_PLAYERS):
		if (player_is_ai[p] && p!=main_player):
			hand[p].resize(NUM_START_CARDS)
			for i in range(NUM_START_CARDS):
				var ID = randi()%(deck[p].size())
				hand[p][i] = deck[p][ID]

func init_field():
	var size = SIZE*POSITIONS
	var array_null = []
	var flip = 2*int(main_player==PLAYER1)-1
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
			ci.set_position((Vector2(x-SIZE*POSITIONS/2.0+0.1*floor(x/POSITIONS)+0.25,flip*(0.5-y)))*Vector2(390,1100))
			ci.get_node("Button").connect("pressed",self,"select_field",[x,y])
			add_child(ci)
			ci.show()
	for x in range(SIZE):
		var pi = get_node("Card").duplicate()
		pi.set_name("Planet_"+str(x))
		pi.set_position((Vector2(x*(POSITIONS+0.1)-SIZE*POSITIONS/2.0+1.25,0))*Vector2(390,0))
		pi.get_node("Button").connect("pressed",self,"select_planet",[x])
		add_child(pi)
		pi.show()
	
	for x in range(SIZE):
		field[x] = Planet.new(self,planets[x]["type"],planets[x]["structure"],planets[x]["damage"],planets[x]["shield"],planets[x]["level"],planets[x]["cards"],planets[x]["owner"],planets[x]["image"],x)
	
	var homeworld = 0
	
	field[homeworld].owner = PLAYER1
	field[homeworld].structure = 9
	field[homeworld].planet = PLANET_TERRAN
	
	field[SIZE-1-homeworld].owner = PLAYER2
	field[SIZE-1-homeworld].structure = 9
	field[SIZE-1-homeworld].planet = PLANET_TERRAN
	
	for i in range(SIZE):
		field[i].update()
	
	player_points.resize(NUM_PLAYERS)
	player_used_points.resize(NUM_PLAYERS)
	for p in range(NUM_PLAYERS):
		player_points[p] = {}
		player_used_points[p] = {}
		for ID in deck[p]:
			if (!player_points[p].has(Data.data[ID]["faction"])):
				player_points[p][Data.data[ID]["faction"]] = 2
				player_used_points[p][Data.data[ID]["faction"]] = 0
				get_node("UI/Player"+str(int(p!=main_player)+1)+"/VBoxContainer/Points"+Data.data[ID]["faction"].capitalize()).show()
		for f in player_points[p].keys():
			player_points[p][f] += 2-player_points[p].size()
	
	get_node("Camera").set_position(Vector2(0,150))


# resize screen #

func _resize():
	var zoom = max((395.0*SIZE*POSITIONS+150.0)/OS.get_window_size().x,2800.0/OS.get_window_size().y)
	get_node("Camera").make_current()
	get_node("Camera").set_zoom(zoom*Vector2(1,1))

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
	
	var faction = Data.data[hand[player][index]]["faction"]
	unselect_hand()
	if (select==CARD && Data.calc_value(hand[player][index],"level")<=player_points[player][faction]-player_used_points[player][faction]):
		var type = Data.data[hand[player][index]]["type"]
		selected_hand = index
		get_node("UI/Cards"+str(int(player!=main_player)+1)+"/Card"+str(index)+"/Outline").show()
		get_node("UI/Player1/VBoxContainer/ButtonD").set_disabled(false)
		if (type=="unit"):
			select = EMPTY
			for x in range(SIZE*POSITIONS):
				if (cards[player][x]==null && (field[floor(x/POSITIONS)].owner==player || field[floor(x/POSITIONS)].revolt || ("partisan" in Data.data[hand[player][index]]["effects"]))):
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
			
			if (get_tree().has_network_peer()):
				rpc("use_card_effect",targets,selected_hand,player)
			else:
				use_card_effect(targets,selected_hand,player)
	elif (select==CARD && Data.calc_value(hand[player][index],"level")>player_points[player][faction]-player_used_points[player][faction]):
		selected_hand = index
		select = DISCARD
		get_node("UI/Cards"+str(int(player!=main_player)+1)+"/Card"+str(index)+"/Outline").show()
		get_node("UI/Player1/VBoxContainer/ButtonD").set_disabled(false)

func unselect_hand():
	if (selected_hand!=null):
		if (has_node("UI/Cards"+str(int(player!=main_player)+1)+"/Card"+str(selected_hand)+"/Outline")):
			get_node("UI/Cards"+str(int(player!=main_player)+1)+"/Card"+str(selected_hand)+"/Outline").hide()
		selected_hand = null
		select = CARD
		for x in range(SIZE*POSITIONS):
			for y in range(2):
				get_node("Card_"+str(x)+"_"+str(y)+"/Select").hide()
		for x in range(SIZE):
			get_node("Planet_"+str(x)+"/Select").hide()
		selected_target = null
		emit_signal("target_selected",selected_target)
	get_node("UI/Player1/VBoxContainer/ButtonD").set_disabled(true)

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
	if (!cards[p][x].attacked && !("no attack" in Data.data[cards[p][x].type]["effects"])):
		var guarded = false
		for y in get_card_targets(x,p,enemy):
			get_node("Card_"+str(y)+"_"+str(enemy)+"/Select").set_modulate(Color(1.0,0.0,0.0))
			get_node("Card_"+str(y)+"_"+str(enemy)+"/Select").show()
			guarded = true
		if (!guarded && field[floor(x/POSITIONS)].owner!=player):
			get_node("Planet_"+str(floor(x/POSITIONS))+"/Select").set_modulate(Color(1.0,0.0,0.0))
			get_node("Planet_"+str(floor(x/POSITIONS))+"/Select").show()
	if (!cards[p][x].moved && !("unmoveable" in Data.data[cards[p][x].type]["effects"])):
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
			if (get_tree().has_network_peer()):
				rpc("use_card_unit",x,selected_hand,player)
			else:
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
			if (get_tree().has_network_peer()):
				rpc("attack_unit",selected_field,x,player,p,false)
			else:
				attack_unit(selected_field,x,player,p,false)
			selected_target = null
			emit_signal("target_selected",selected_target)
		elif (cards[p][x]==null && player==p):
			if (get_tree().has_network_peer()):
				rpc("move_unit",selected_field,x,player)
			else:
				move_unit(selected_field,x,player)
			selected_target = null
			emit_signal("target_selected",selected_target)
	elif (select==ENEMY || select==FRIENDLY):
		if (cards[p][x]!=null):
			selected_target = x
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
				if (get_tree().has_network_peer()):
					rpc("use_card_planet",x,selected_hand,player)
				else:
					use_card_planet(x,selected_hand,player)
				return
			selected_target = x
			emit_signal("target_selected",selected_target)
	elif (select==PLANET_ENEMY):
		if (field[x]!=null && field[x].owner!=player):
			if (Data.data[hand[player][selected_hand]]["type"]=="planet"):
				if (get_tree().has_network_peer()):
					rpc("use_card_planet",x,selected_hand,player)
				else:
					use_card_planet(x,selected_hand,player)
				return
			selected_target = x
			emit_signal("target_selected",selected_target)
	elif (select==EMPTY_OR_ENEMY):
		var guarded = false
		for x1 in range(x*POSITIONS,(x+1)*POSITIONS):
			if (cards[enemy][x1]!=null):
				guarded = true
		if (!guarded && field[x].owner!=player):
			if (get_tree().has_network_peer()):
				rpc("bombard_unit",selected_field,x,player,enemy)
			else:
				bombard_unit(selected_field,x,player,enemy)
			selected_target = null
			emit_signal("target_selected",selected_target)

func _input(event):
	if (player<0 || player_is_ai[player]):
		return
	
	if (event is InputEventMouseButton && event.pressed && event.button_index==2):
		if (select!=NONE):
			unselect_hand()
			unselect_unit()
			select = CARD

func _process(delta):
	var last_pos = Vector2(50,200)
	var max_length = get_node("UI/Cards1").get_size().x-100
	var max_delta = max_length/max(get_node("UI/Cards1").get_child_count(),1)
	
	for c in get_node("UI/Cards1").get_children():
		c.target_pos = last_pos+Vector2(c.get_size().x*(c.get_scale().x-0.5)/2.0,0)
		last_pos.x += min(c.get_size().x*c.get_scale().x+8,max_delta)
	if (last_pos.x+350>max_length):
		var offset = ceil((last_pos.x+350-max_length)/(get_node("UI/Cards1").get_child_count()-1))
		for c in get_node("UI/Cards1").get_children():
			c.target_pos.x -= offset
	
	last_pos = Vector2(0,350)
	max_length = get_node("UI/Cards2").get_size().x-100
	max_delta = max_length/max(get_node("UI/Cards2").get_child_count(),1)
	for c in get_node("UI/Cards2").get_children():
		c.target_pos = last_pos+Vector2(c.get_size().x*(c.get_scale().x-0.5)/2.0,0)
		last_pos.x += min(c.get_size().x*c.get_scale().x+8,max_delta)
	if (last_pos.x+350>max_length):
		var offset = ceil((last_pos.x+350-max_length)/(get_node("UI/Cards2").get_child_count()-1))
		for c in get_node("UI/Cards2").get_children():
			c.target_pos.x -= offset
	
	var pos = get_node("UI/Cards1").get_margin(MARGIN_BOTTOM)
	pos = pos+delta*10*(hand_offset-pos)
	get_node("UI/Cards1").set_margin(MARGIN_BOTTOM,pos)
	pos = get_node("UI/Cards1").get_margin(MARGIN_TOP)
	pos = pos+delta*10*(200+hand_offset-pos)
	get_node("UI/Cards1").set_margin(MARGIN_TOP,pos)
	pos = get_node("UI/Cards2").get_margin(MARGIN_BOTTOM)
	pos = pos+delta*10*(300-hand_offset-pos)
	get_node("UI/Cards2").set_margin(MARGIN_BOTTOM,pos)
	pos = get_node("UI/Cards2").get_margin(MARGIN_TOP)
	pos = pos+delta*10*(100-hand_offset-pos)
	get_node("UI/Cards2").set_margin(MARGIN_TOP,pos)

func _ready():
	set_process(true)
	set_process_input(true)
	get_tree().connect("screen_resized",self,"_resize")
	_resize()
	get_node("UI/Player1/VBoxContainer/Button").connect("pressed",self,"_next_turn")
	get_node("UI/Player1/VBoxContainer/ButtonD").connect("pressed",self,"_discard_hand")
	rpc_config("set_hand",RPC_MODE_SYNC)
	rpc_config("use_card_unit",RPC_MODE_SYNC)
	rpc_config("use_card_effect",RPC_MODE_SYNC)
	rpc_config("use_card_planet",RPC_MODE_SYNC)
	rpc_config("attack_unit",RPC_MODE_SYNC)
	rpc_config("bombard_unit",RPC_MODE_SYNC)
	rpc_config("move_unit",RPC_MODE_SYNC)
	rpc_config("discard_hand",RPC_MODE_SYNC)
	rpc_config("next_turn",RPC_MODE_SYNC)
	rpc_config("draw_card_ID",RPC_MODE_SYNC)
	
	init_field()
	draw_init()
	
	update_resources()
	ai = ai_class.new(PLAYER2,hand,deck,cards,field,player_points[PLAYER2],player_used_points[PLAYER2],SIZE,POSITIONS)
	
	update_discard_cards()
