var hand
var deck
var player
var enemy
var cards
var field
var size
var positions
var points
var used
var left
var guarded
var defended
var phase = 0
var next_action

func _init(_player,_hand,_deck,_cards,_field,_points,_used,_size,_positions):
	player = _player
	enemy = 0
	if (player==0):
		enemy = 1
	hand = _hand
	deck = _deck
	cards = _cards
	field = _field
	size = _size
	positions = _positions
	points = _points
	used = _used

func discard(hand):
	# chose wich cards to keep on game start
	var discard = []
	var _ID
	for ID in hand:
		var lvl = Data.data[ID]["level"]+int(Data.data[ID]["type"]!="unit")
		if (lvl>points[Data.data[ID]["faction"]]):
			discard.push_back(ID)
	if (discard.size()==hand.size()):
		for ID in discard:
			var lvl = Data.data[ID]["level"]
			if (lvl<5):
				discard.erase(ID)
				break
	
	return discard

func reset():
	phase = 0

func update():
	left = {}
	guarded = []
	defended = []
	guarded.resize(size)
	defended.resize(size)
	for i in range(size):
		guarded[i] = false
		defended[i] = false
		for j in range(positions):
			var pos = i*positions+j
			if (cards[enemy][pos]!=null):
				guarded[i] = true
			if (cards[player][pos]!=null):
				defended[i] = true
	for f in points.keys():
		left[f] = points[f]-used[f]

func get_action():
	var action
	if (next_action!=null):
		action = next_action
		next_action = null
		return action
	if (phase==0):
		action = get_effect()
	elif (phase==1):
		action = get_attack()
	elif (phase==2):
		action = get_spawn()
	elif (phase==3):
		action = get_effect()
	elif (phase==4):
		action = get_movement()
	elif (phase==5):
		action = get_effect()
	elif (phase==6):
		action = get_attack()
	elif (phase==7):
		action = get_discard()
	
	if (phase<7 && action==null):
		phase += 1
		return get_action()
	return action

func get_attack():
	var action
	var priority = 0
	var value = 0
	for x in range(size):
		for y in range(positions):
			var pos = x*positions+y
			if (cards[player][pos]==null):
				continue
			if (cards[player][pos].attacked || ("no attack" in Data.data[cards[player][pos].type]["effects"]) || cards[player][pos].damage<1):
				continue
			
			var ps = int(!("penetrate shields" in Data.data[cards[player][pos].type]["effects"]))
			if (field[x].owner!=player && !guarded[x] && cards[player][pos].damage>field[x].shield*ps):
				# invade planet
				var v = 1.0/(1+abs(field[x].structure+field[x].shield*ps-cards[player][pos].damage))
				var p = 3+int(cards[player][pos].damage>field[x].structure+field[x].shield)
				if (p>priority || (p==priority && v>value)):
					priority = p
					value = v
					action = {"function":"bombard_unit","arguments":[pos,x,player,enemy]}
			else:
				# attack enemy units
				for z in range(positions):
					var t = x*positions+z
					if (cards[enemy][t]!=null && cards[enemy][t].shield*ps<cards[player][pos].damage):
						var v = 2*(cards[player][pos].damage-cards[enemy][t].shield*ps)+2*cards[enemy][t].damage+2*cards[enemy][t].shield-cards[enemy][t].level-4*max(cards[player][pos].damage-cards[enemy][t].structure-cards[enemy][t].shield*ps,0)
						var p = 1+int(cards[player][pos].damage>cards[enemy][t].structure+cards[enemy][t].shield*ps)
						if (p<2 && "counterattack" in Data.data[cards[enemy][t].type]["effects"]):
							value -= 4*cards[enemy][t].damage
						if (p>priority || (p==priority && v>value)):
							priority = p
							value = v
							action = {"function":"attack_unit","arguments":[pos,t,player,enemy]}
	
	return action

func get_movement():
	var action
	var naction
	var priority = 0
	var value = 0
	for x in range(size):
		for y in range(positions):
			var pos = x*positions+y
			if (cards[player][pos]==null):
				continue
			if (cards[player][pos].moved || ("unmoveable" in Data.data[cards[player][pos].type]["effects"])):
				continue
			# move card
			for x1 in range(0,x)+range(x+1,size):
				var to = -1
				for y1 in range(positions):
					var t = x1*positions+y1
					if (cards[player][t]==null):
						to = t
						break
				
				if (to>=0):
					# free field available
					var v = 1
					var p = 0
					var na
					var ps = int(!("penetrate shields" in Data.data[cards[player][pos].type]["effects"]))
					if (field[x1].owner==player):
						if (!defended[x1]):
							p = 3
					else:
						if (!guarded[x1] && cards[player][pos].damage>0):
							p = 2
							v = 1.0/(1+abs(field[x].structure+field[x].shield*ps-cards[player][pos].damage))
							if (!cards[player][pos].attacked && field[x1].structure+field[x1].shield*ps<=cards[player][pos].damage+Data.calc_value(cards[player][pos].type,"bombardment")):
								p = 4
								na = {"function":"bombard_unit","arguments":[to,x1,player,enemy]}
					if (guarded[x1]):
						for y1 in range(positions):
							var t = x1*positions+y1
							if (cards[enemy][t]!=null && cards[player][pos].damage>0):
								var val = 2*(cards[player][pos].damage-cards[enemy][t].shield*ps)+2*cards[enemy][t].damage+2*cards[enemy][t].shield-cards[enemy][t].level-4*max(cards[player][pos].damage-cards[enemy][t].structure-cards[enemy][t].shield*ps,0)
								var _p = 1
								var _na
								if (!cards[player][pos].attacked && !("no attack" in Data.data[cards[player][pos].type]["effects"])):
									if (cards[player][pos].damage>=cards[enemy][t].structure+cards[enemy][t].shield*ps):
										_p = 2
										_na = {"function":"attack_unit","arguments":[to,t,player,enemy]}
									elif ("counterattack" in Data.data[cards[enemy][t].type]["effects"]):
										v -= 4*cards[enemy][t].damage
								else:
									v -= 4*max(cards[enemy][t].damage-cards[player][pos].shield*ps,0)
								if (_p>p || (p==_p && val>v)):
									v = val
									p = _p
									na = _na
					
					var ships = 0
					for y1 in range(positions):
						if (cards[player][x*positions+y1]!=null):
							ships += 1
					if (ships<=1):
						p -= 2
					if (p>priority || (p==priority && v>value)):
						priority = p
						value = v
						naction = na
						action = {"function":"move_unit","arguments":[pos,to,player]}
	
	next_action = naction
	return action

func get_spawn():
	var action
	var value = 0
	var priority = 0
	for c in range(hand[player].size()):
		var ID = hand[player][c]
		var card = Data.data[ID]
		var cost = Data.calc_value(ID,"level")
		var faction = card["faction"]
		if (cost>left[faction]):
			continue
		var type = card["type"]
		if (type!="unit"):
			continue
		var v = cost*(1.0+float("cheap" in card["effects"])-0.5*float("partisan" in card["effects"])-0.5*float("unmoveable" in card["effects"]))
		var p = 1
		var pos = -1
		for x in range(size):
			for y in range(positions):
				if ((field[x].owner==player || field[x].revolt || ("partisan" in card["effects"])) && cards[player][x*positions+y]==null):
					var val = v
					var _p = 1+int(!defended[x])+int(!guarded[x])
					if (field[x].owner==player):
						val += field[x].structure+2*field[x].shield
					else:
						val += 10-field[x].structure-2*field[x].shield+5*int(("partisan" in card["effects"]) && !field[x].revolt)
					if (_p>p || (_p==p && val>v)):
						v = val
						p = _p
						pos = x*positions+y
		if (pos>=0 && p>priority || (p==priority && v>value)):
			priority = p
			value = v
			action = {"function":"use_card_unit","arguments":[pos,c,player]}
	
	return action

func get_effect():
	var action
	var value = 0
	for c in range(hand[player].size()):
		var ID = hand[player][c]
		var card = Data.data[ID]
		var cost = Data.calc_value(ID,"level")
		var faction = card["faction"]
		if (cost>left[faction]):
			continue
		var type = card["type"]
		if (type=="effect"):
			var targets = []
			var targets_type = ["targets"]
			var effects = card["effects"]
			var v = -cost
			targets.resize(targets_type.size())
			for i in range(targets_type.size()):
				if (targets_type[i]=="enemy"):
					var val0 = v
					var dmg = 0
					var weaken = 0
					var jam = 0
					if (effects[i]=="direct damage 6"):
						dmg = 6
					elif (effects[i]=="direct damage 4"):
						dmg = 4
					elif (effects[i]=="jam 1"):
						jam = 1
					elif (effects[i]=="reduce dmg 2"):
						weaken = 2
					for x in range(size):
						for y in range(positions):
							var pos = x*positions+y
							if (cards[enemy][pos]!=null):
								var val = v
								if (dmg>0):
									val += 50-abs(dmg-cards[enemy][pos].structure)+max(dmg-cards[enemy][pos].structure/2,0)+cards[enemy][pos].damage+2*cards[enemy][pos].shield
								if (cards[enemy][pos].structure<=dmg):
									val += 20
								val += 5*min(jam,cards[enemy][pos].shield)+min(weaken,cards[enemy][pos].damage)
								if (val>val0):
									targets[i] = pos
									val0 = val
					v = val0
				elif (targets_type[i]=="friendly"):
					var val0 = v
					var repair = 0
					var armor = 0
					var shield = 0
					var dmg_inc = 0
					val0 = v
					if (effects[i]=="repair 4"):
						repair = 4
					elif (effects[i]=="repair 5"):
						repair = 5
					elif (effects[i]=="repair 6"):
						repair = 6
					elif (effects[i]=="armor 2"):
						armor = 2
					elif (effects[i]=="shield 1"):
						shield = 1
					elif (effects[i]=="increase dmg 2"):
						dmg_inc = 2
					for x in range(size):
						for y in range(positions):
							var pos = x*positions+y
							if (cards[player][pos]!=null):
								var val = v+cards[player][pos].structure+cards[player][pos].damage+2*cards[player][pos].shield+armor+shield+dmg_inc
								if (repair>0):
									if (cards[player][pos].structure>=Data.calc_value(cards[player][pos].type,"structure")):
										continue
									val += 2*min(9-cards[player][pos].structure-repair,0)
								if (effects[i]=="reduce cost 4"):
									val += 2*min(cards[player][pos].level,4)
								elif (effects[i]=="cheap"):
									val += 2*cards[player][pos].level
								if (val>val0):
									targets[i] = pos
									val0 = val
					v = val0
				elif (targets_type[i]=="friendly planet"):
					var val0 = v
					for x in range(size):
						if (field[x].owner==player):
							var val = v+field[x].structure/2+field[x].shield
							var defense = 0
							if ("defense 4" in effects[i]):
								defense = 4
							elif ("defense 6" in effects[i]):
								defense = 6
							if (defense>0):
								val += defense+2*min(9-field[x].structure-defense,0)
							if (card["effects"][i]=="terraform"):
								if (field[x].planet>=0 && field[x].planet<=6):
									val += 5
								else:
									val -= 25
							if (val>val0):
								val0 = val
								targets[i] = x
					v = val0
					if (card["effects"][i]=="mines 1"):
						v += 20
					elif (card["effects"][i]=="mines 2"):
						v += 35
					elif (card["effects"][i]=="drydock"):
						v += 25
				elif (targets_type[i]=="player"):
					if (card["effects"][i]=="draw 3"):
						v += 50-5*hand[player].size()
				elif (targets_type[i]=="opposite"):
					if (card["effects"][i]=="remove 2"):
						v += 30
						if (hand[enemy].size()<2):
							v -= 26
			
			var valid = true
			for i in range(targets.size()):
				if (targets[i]==null):
					valid = false
					break
			if (valid && v>value):
				value = v
				action = {"function":"use_card_effect","arguments":[targets,c,player]}
		elif (type=="planet"):
			# use planet cards
			var v = 20-cost*(1.0-0.5*float("cheap" in card["effects"]))+Data.calc_value(ID,"shield")+2*Data.calc_value(ID,"production")
			var pos = -1
			var tg = card["targets"]
			var effects = card["effects"]
			var targets = []
			for i in range(effects.size()):
				if (effects[i]=="mines 1"):
					v += 5
				elif (effects[i]=="drydock"):
					v += 5
			for t in tg:
				var val = v
				for x in range(size):
					if (t=="friendly planet"):
						if (field[x].owner==player && field[x].type==""):
							var _v = val+field[x].structure+field[x].shield
							if (val>v):
								val = _v
								pos = x
					elif (t=="enemy planet"):
						if (field[x].owner!=player && field[x].type==""):
							var _v = val+field[x].structure+field[x].shield
							if (val>v):
								val = _v
								pos = x
				targets.push_back(pos)
			if (pos>=0 && v>value):
				value = v
				action = {"function":"use_card_effect","arguments":[targets,c,player]}
	
	return action

func get_discard():
	var action
	var value = 0
	for c in range(hand[player].size()):
		var ID = hand[player][c]
		var cost = Data.calc_value(ID,"level")
		var faction = Data.data[ID]["faction"]
		var v = 2.5*min(cost,points[faction]-cost)*(1.0-0.5*float(Data.data[ID]["type"]!="unit"))+hand[player].size()-points[faction]+deck[player].size()-20
		if (v>value && deck[player].size()+hand[player].size()>20 && hand[player].size()>1):
			value = v
			action = {"function":"discard_hand","arguments":[c]}
	
	return action
