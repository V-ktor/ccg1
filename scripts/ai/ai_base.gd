var hand
var deck
var player
var enemy
var cards
var field
var SIZE
var POSITIONS
var points
var used
var left
var guarded
var defended
var phase = 0
var next_action
var Main

func _init(_player,_hand,_deck,_cards,_field,_points,_used,_size,_positions,_main):
	player = _player
	enemy = 0
	if (player==0):
		enemy = 1
	hand = _hand
	deck = _deck
	cards = _cards
	field = _field
	SIZE = _size
	POSITIONS = _positions
	points = _points
	used = _used
	Main = _main

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
	guarded.resize(SIZE)
	defended.resize(SIZE)
	for i in range(SIZE):
		guarded[i] = false
		defended[i] = false
		for j in range(POSITIONS):
			var pos = i*POSITIONS+j
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
	for x in range(SIZE):
		for y in range(POSITIONS):
			var pos = x*POSITIONS+y
			var card = cards[player][pos]
			if (card==null):
				continue
			if (card.attack_points<=0 || card.damage<1):
				continue
			
			if (field[x].owner!=player && !guarded[x]):
				# invade planet
				var v = 1.0/(1+abs(field[x].structure+field[x].shield-card.damage))
				var p = 3+int(cards[player][pos].damage>field[x].structure+field[x].shield)
				if (p>priority || (p==priority && v>value)):
					priority = p
					value = v
					action = {"function":"bombard_unit","arguments":[pos,x,player,enemy]}
			else:
				# attack enemy units
				for z in range(POSITIONS):
					var t = x*POSITIONS+z
					var enemy_card = cards[enemy][t]
					if (enemy_card!=null && enemy_card.shield<card.damage):
						var v = 2*(card.damage-enemy_card.shield)+2*enemy_card.damage+2*enemy_card.shield-enemy_card.level-4*max(card.damage-enemy_card.structure-enemy_card.shield,0)
						var p = 1+int(card.damage>enemy_card.structure+enemy_card.shield)
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
	for x in range(SIZE):
		for y in range(POSITIONS):
			var pos = x*POSITIONS+y
			var card = cards[player][pos]
			if (card==null):
				continue
			if (card.movement_points<=0):
				continue
			
			# move card
			for x1 in range(0,x)+range(x+1,SIZE):
				var to = -1
				# find empty field
				for y1 in range(POSITIONS):
					var t = x1*POSITIONS+y1
					if (cards[player][t]==null):
						to = t
						break
				
				if (to>=0):
					# free field available
					var v = 1
					var p = 0
					var na
					if (field[x1].owner==player):
						if (!defended[x1]):
							p = 3
					else:
						if (!guarded[x1] && card.damage>0):
							p = 2
							v = 1.0/(1+abs(field[x].structure+field[x].shield-card.damage))
							if (card.attack_points>0 && field[x1].structure+field[x1].shield<=card.damage):
								p = 4
								na = {"function":"bombard_unit","arguments":[to,x1,player,enemy]}
					if (guarded[x1]):
						for y1 in range(POSITIONS):
							var t = x1*POSITIONS+y1
							var enemy_card = cards[enemy][t]
							if (enemy_card!=null && card.damage>0):
								var val = 2*(card.damage-enemy_card.shield)+2*enemy_card.damage+2*enemy_card.shield-enemy_card.level-4*max(card.damage-enemy_card.structure-enemy_card.shield,0)
								var _p = 1
								var _na
								if (card.attack_points>0):
									if (card.damage>=enemy_card.structure+enemy_card.shield):
										_p = 2
										_na = {"function":"attack_unit","arguments":[to,t,player,enemy]}
								else:
									v -= 4*max(enemy_card.damage-card.shield,0)
								if (_p>p || (p==_p && val>v)):
									v = val
									p = _p
									na = _na
					
					var ships = 0
					for y1 in range(POSITIONS):
						if (cards[player][x*POSITIONS+y1]!=null):
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
		var cost = card["level"]
		var faction = card["faction"]
		if (cost>left[faction]):
			continue
		var type = card["type"]
		if (type!="unit"):
			continue
		var v = cost
		var p = 1
		var pos = -1
		var effects = Data.Effects.new()
		var script = GDScript.new()
		var code = card["script"].get_script().get_source_code()
		script.set_source_code(code)
		script.reload()
		effects.set_script(script)
		effects._self = self
		effects.Main = self
		for x in range(SIZE):
			for y in range(POSITIONS):
				if (field[x].owner==player && cards[player][x*POSITIONS+y]==null):
					var val = v
					var _p = 1+int(!defended[x])+int(!guarded[x])
					if (effects.has_method("estimate_effectiveness")):
						val = effects.call("estimate_effectiveness",val,x*POSITIONS+y)
					if (field[x].owner==player):
						val += field[x].structure+2*field[x].shield
					else:
						val += 10-field[x].structure-2*field[x].shield
					if (_p>p || (_p==p && val>v)):
						v = val
						p = _p
						pos = x*POSITIONS+y
		if (pos>=0 && p>priority || (p==priority && v>value)):
			priority = p
			value = v
			action = {"function":"use_card_unit","arguments":[pos,c,player]}
	
	return action

func get_target(type,effects,event,ID,last_targets,valid_targets):
	if (valid_targets.size()<1):
		return
	
	return valid_targets[randi()%valid_targets.size()]

func get_best_targets(effects,value,targets):
	if (targets.size()<effects.on_use_targets.size()):
		var best_value = 0
		var best_targets
		for target in Main.get_targets(effects.on_use_targets[targets.size()],effects,"on_use",targets.size(),targets):
			var score = get_best_targets(effects,value,targets+[target])
			
			if (score["value"]>best_value):
				best_value = score["value"]
				best_targets = score["targets"]
		return {"value":best_value,"targets":best_targets}
	
	var _targets = []
	var val
	_targets.resize(targets.size())
	for i in range(targets.size()):
		if (effects.on_use_targets[i]==Main.ALLY_UNIT):
			_targets[i] = cards[player][targets[i]]
		elif (effects.on_use_targets[i]==Main.ENEMY_UNIT):
			_targets[i] = cards[enemy][targets[i]]
		elif (effects.on_use_targets[i]==Main.ALLY_PLANET || effects.on_use_targets[i]==Main.ENEMY_PLANET || effects.on_use_targets[i]==Main.PLANET):
			_targets[i] = field[targets[i]]
	val = effects.call("estimate_effectiveness",value,_targets)
	return {"value":val,"targets":targets}

func get_effect():
	var action
	var value = 0
	for c in range(hand[player].size()):
		var ID = hand[player][c]
		var card = Data.data[ID]
		var cost = card["level"]
		var faction = card["faction"]
		if (cost>left[faction]):
			continue
		var type = card["type"]
		var effects = Data.Effects.new()
		var script = GDScript.new()
		var code = card["script"].get_script().get_source_code()
		script.set_source_code(code)
		script.reload()
		effects.set_script(script)
		effects._self = self
		effects.Main = self
		if (type=="effect" && effects.has_method("estimate_effectiveness")):
			# use effect card
			var val = cost-abs(left[faction]/2-cost)
			var best = get_best_targets(effects,val,[])
			if (best["value"]>0):
				action = {"function":"use_card_effect","arguments":[c,player,best["targets"]]}
		elif (type=="planet"):
			# use planet cards
			var val = cost-abs(left[faction]/2-cost)
			var pos
			var targets = Main.get_targets(Main.ALLY_PLANET,null)
			if (effects.has_method("estimate_effectiveness")):
				for x in targets:
					var v = effects.call("estimate_effectiveness",val,[field[x]])
					if (v>val):
						val = v
						pos = x
			elif (val>0 && targets.size()>0):
				pos = targets[randi()%targets.size()]
			if (val>0):
				action = {"function":"use_card_planet","arguments":[pos,c,player]}
	
	return action

func get_discard():
	var action
	var value = 0
	for c in range(hand[player].size()):
		var ID = hand[player][c]
		var cost = Data.data[ID]["level"]
		var faction = Data.data[ID]["faction"]
		var v = 2.5*min(cost,points[faction]-cost)*(1.0-0.5*float(Data.data[ID]["type"]!="unit"))+hand[player].size()-points[faction]+deck[player].size()-20
		if (v>value && deck[player].size()+hand[player].size()>20 && hand[player].size()>1):
			value = v
			action = {"function":"discard_hand","arguments":[c]}
	
	return action
