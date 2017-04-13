var actions = load("res://scripts/ai/actions.gd").new()

var hand
var player
var enemy
var cards
var field
var size
var positions

func _init(_player,_hand,_cards,_field,_size,_positions):
	player = _player
	enemy = 0
	if (player==0):
		enemy = 1
	hand = _hand
	cards = _cards
	field = _field
	size = _size
	positions = _positions

func gather_available_actions(points,income):
	var guarded = []
	var defended = []
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
	
	actions.reset()
	
	# use cards from hand
	for c in range(hand[player].size()):
		var ID = hand[player][c]
		var cost = Data.calc_value(ID,"level")
		if (cost<=points):
			var type = Data.data[ID]["type"]
			if (type=="unit"):
				# deploy units
				var value = max(cost+5*income+points-30,-1)
				var pos = -1
				for x in range(size):
					for y in range(positions):
						if (field[x].owner==player && cards[player][x*positions+y]==null):
							var val = value+5+field[x].production-field[x].structure-2*field[x].shield
							if !defended[x]:
								val += 50
							if (val>value):
								value = val
								pos = x*positions+y
				if (pos>=0):
					actions.add_action(value,"use_card_unit",[pos,c,player])
			elif (type=="effect"):
				var targets = []
				var targets_type = Data.data[ID]["targets"]
				var effects = Data.data[ID]["effects"]
				var value = income-cost
				targets.resize(targets_type.size())
				for i in range(targets_type.size()):
					if (targets_type[i]=="enemy"):
						var val0 = value
						var dmg = 0
						if (effects[i]=="direct damage 6"):
							dmg = 6
						for x in range(size):
							for y in range(positions):
								var pos = x*positions+y
								if (cards[enemy][pos]!=null):
									var val = value
									if (dmg>0):
										val += 50-abs(dmg-cards[enemy][pos].structure)+max(dmg-cards[enemy][pos].structure/2,0)+cards[enemy][pos].damage+2*cards[enemy][pos].shield
									if (cards[enemy][pos].structure<=dmg):
										val += 25
									if (val>val0):
										targets[i] = cards[enemy][pos]
										val0 = val
						value = val0
					elif (targets_type[i]=="friendly"):
						var val0 = value
						var repair = 0
						var armor = 0
						var shield = 0
						var dmg_inc = 0
						val0 = value
						if (effects[i]=="repair 4"):
							repair = 4
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
									var val = value+cards[player][pos].structure+cards[player][pos].damage+2*cards[player][pos].shield+repair+armor+shield+dmg_inc
									val /= 4
									if (repair>0):
										if (cards[player][pos].structure>=Data.calc_value(cards[player][pos].type,"structure")):
											continue
										val += 2*min(9-cards[player][pos].structure-repair,0)
									if (val>val0):
										targets[i] = cards[player][pos]
										val0 = val
						value = val0
					elif (targets_type[i]=="planet_friendly"):
						var val0 = value
						for x in range(size):
							if (field[x].owner==player):
								var val = value+field[x].structure/2+field[x].shield+field[x].production
								var defense = 0
								if ("defense 4" in effects[i]):
									defense = 4
								elif ("defense 6" in effects[i]):
									defense = 6
								if (defense>0):
									val += defense+2*min(9-field[x].structure-defense,0)
								if (Data.data[ID]["effects"][i]=="terraform"):
									if (field[x].planet>=0 && field[x].planet<=6):
										val += 5
									else:
										val -= 25
								if (val>val0):
									val0 = val
									targets[i] = field[x]
						value = val0
						if (Data.data[ID]["effects"][i]=="mines 1"):
							value += 25
						elif (Data.data[ID]["effects"][i]=="drydock"):
							value += 25
					elif (targets_type[i]=="player"):
						if (Data.data[ID]["effects"][i]=="draw 3"):
							value += 50-5*hand[player].size()
						elif (Data.data[ID]["effects"][i]=="points 2"):
							value += 10
					elif (targets_type[i]=="opposite"):
						if (Data.data[ID]["effects"][i]=="remove 2"):
							value += 30
							if (hand[enemy].size()<2):
								value -= 26
				
				var valid = true
				for i in range(targets.size()):
					if (targets[i]==null):
						valid = false
						break
				if (valid):
					actions.add_action(value,"use_card_effect",[targets,c,player])
			elif (type=="planet"):
				# use planet cards
				var value = income+20-cost+Data.calc_value(ID,"shield")
				var pos = -1
				var targets = Data.data[ID]["targets"]
				var effects = Data.data[ID]["effects"]
				for i in range(targets.size()):
					if (effects[i]=="production 1"):
						value += 3
					elif (effects[i]=="production 2"):
						value += 6
					elif (effects[i]=="mines 1"):
						value += 5
					elif (effects[i]=="drydock"):
						value += 5
				for x in range(size):
					if (field[x].owner==player && field[x].type==""):
						var val = value+field[x].structure+field[x].shield
						if (val>value):
							value = val
							pos = x
				if (pos>=0):
					actions.add_action(value,"use_card_planet",[pos,c,player])
	
	# unit actions
	for x in range(size):
		for y in range(positions):
			var pos = x*positions+y
			if (cards[player][pos]!=null):
				var atk_cost = Data.calc_value(cards[player][pos].type,"attack cost")
				var move_cost = Data.calc_value(cards[player][pos].type,"movement cost")
				if (!cards[player][pos].attacked && !("no attack" in Data.data[cards[player][pos].type]["effects"]) && points>=atk_cost):
					# attack
					if (field[x].owner!=player && !guarded[x]):
						# invade planet
						var value = 150+3*field[x].production+min(cards[player][pos].damage+Data.calc_value(cards[player][pos].type,"bombardment")-field[x].structure-field[x].shield,0)
						if (cards[player][pos].damage>=field[x].structure+field[x].shield):
							value += 100
						actions.add_action(value,"bombard_card_unit",[pos,x,player,enemy])
					elif (guarded[x]):
						# attack enemy units
						for z in range(positions):
							var t = x*positions+z
							if (cards[enemy][t]!=null && cards[enemy][t].shield<cards[player][pos].damage):
								var value = max(175-abs(cards[player][pos].damage-cards[enemy][t].shield-cards[enemy][t].structure)+2*(cards[player][pos].damage-cards[enemy][t].shield)+2*cards[enemy][t].damage+2*cards[enemy][t].shield+field[x].production-0.5*field[x].structure-field[x].shield,1)
								if (cards[player][pos].damage>=cards[enemy][t].structure+cards[enemy][t].shield):
									value += 50
								elif ("counterattack" in Data.data[cards[enemy][t].type]["effects"]):
									value -= 4*cards[enemy][t].damage
									if (cards[player][pos].structure+cards[player][pos].shield<=cards[enemy][t].damage):
										value -= 25
								actions.add_action(value,"attack_card_unit",[pos,t,player,enemy])
				if (!cards[player][pos].moved && !("unmoveable" in Data.data[cards[player][pos].type]["effects"]) && points>=move_cost):
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
							var value = 2*field[x1].production-field[x].structure-2*field[x].shield
							if (field[x1].owner==player):
								if (!defended[x1]):
									value = max(2*value,0)
									value += 25
							else:
								if (!guarded[x1] && cards[player][pos].damage>0 && points>atk_cost+move_cost):
									value += 75+Data.calc_value(cards[player][pos].type,"bombardment")
									if (field[x1].structure+field[x1].shield<=cards[player][pos].damage+Data.calc_value(cards[player][pos].type,"bombardment")):
										value += 100
							if (guarded[x1]):
								var val = 0
								for y1 in range(positions):
									var t = x1*positions+y1
									if (cards[enemy][t]!=null && cards[player][pos].damage>0):
										var v = max(150-abs(cards[player][pos].damage-cards[enemy][t].shield-cards[enemy][t].structure)+2*(cards[player][pos].damage-cards[enemy][t].shield)+2*cards[enemy][t].damage+2*cards[enemy][t].shield+field[x].production-0.5*field[x].structure-field[x].shield,1)
										if (!("no attack" in Data.data[cards[player][pos].type]["effects"]) && points>atk_cost+move_cost):
											if (cards[player][pos].damage>=cards[enemy][t].structure+cards[enemy][t].shield):
												value += 50
											elif ("counterattack" in Data.data[cards[enemy][t].type]["effects"]):
												value -= 4*cards[enemy][t].damage
												if (cards[player][pos].structure+cards[player][pos].shield<=cards[enemy][t].damage):
													value -= 25
										else:
											value -= 4*max(cards[enemy][t].damage-cards[player][pos].shield,0)
										if (v>value):
											val = v
								if (!cards[player][pos].attacked && !("no attack" in Data.data[cards[player][pos].type]["effects"]) && points>atk_cost+move_cost):
									value = 0.3*value+0.8*val
							
							var value_stay = 0
							var ships = 0
							for y1 in range(positions):
								if (cards[player][x*positions+y1]!=null):
									ships += 1
							if (ships<=1):
								value_stay = max(50+2*field[x1].production-2*field[x1].structure-3*field[x1].shield,-5)
							else:
								actions.add_action(value+25,"move_card_unit",[pos,to,player])
								continue
							if (value_stay<value):
								actions.add_action(value,"move_card_unit",[pos,to,player])
	

func get_best_action():
	return actions.get_best_action()
