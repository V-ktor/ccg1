extends Node

const MAX_CARDS = 40
const DECK_DEFAULT = {
	"empire":{
		"fighter":3,"heavy_fighter":2,"bomber":1,
		"planetary_defense_network":1,
		"factory":1,"repair_ship":1,"heavy_bomber":1,
		"corvette":2,"destroyer":2,
		"cruiser":2,"carrier":2,"battleship":2,"assault_carrier":1,
		"draw_3":2,"long_range_torpedos":2,
		"repair_4":3,
		"upgrade_weapons":2,"armor_plating":2,"upgrade_shields":2,
		"planetary_defense_6":2,
		"orbital_drydock":1,"factory_world":2,"planetary_barrier":1},
	"rebels":{
		"light_fighter":3,"fighter_flamer":2,"stealth_fighter":1,
		"freighter":2,"defender":3,
		"abandoned_space_station":2,"troop_ship":1,
		"militia":2,"ironclad":2,"asteroid_ship":2,
		"rebels_carrier":2,"rebels_battleship":2,
		"jam_shields":2,"cripple":2,
		"downgrade":2,"repair_5":2,
		"sabotage":2,"revolt":2,"rebellion":1,
		"bunker_complex":1,"shipyard":2}
		
}
const INVENTORY_DEFAULT = {
	"fighter":3,"heavy_fighter":2,"bomber":1,"heavy_bomber":1,
	"planetary_defense_network":1,"factory":2,"repair_ship":1,
	"corvette":2,"destroyer":2,"cruiser":2,"carrier":2,"battleship":2,"assault_carrier":1,
	"draw_3":2,"long_range_torpedos":2,
	"upgrade_weapons":2,"armor_plating":2,"upgrade_shields":2,"repair_4":3,
	"planetary_defense_6":2,
	"orbital_drydock":1,"factory_world":2,"planetary_barrier":1,
	"light_fighter":3,"fighter_flamer":2,"stealth_fighter":1,
	"freighter":3,"defender":3,
	"militia":2,"ironclad":2,"asteroid_ship":2,
	"rebels_carrier":2,"rebels_battleship":2,
	"abandoned_space_station":2,"troop_ship":1,
	"jam_shields":2,"cripple":2,
	"downgrade":2,"repair_5":2,
	"sabotage":2,"revolt":2,"rebellion":1,
	"bunker_complex":2,"shipyard":2,
	"pirate_fighter":3,"stolen_freighter":3,"looter":2,
	"pirate_corvette":2,"pirate_carrier":2,
	"booby_trab":2,"virus":2,
	"large_mine_field":1
}

var data = {}
var inventory = INVENTORY_DEFAULT.duplicate()
var all_cards = []
var deck = DECK_DEFAULT["empire"].duplicate()
var cards_tier1 = [[],[],[],[],[]]
var cards_tier2 = [[],[],[],[],[]]
var cards_tier3 = [[],[],[],[],[]]

func load_data():
	var dir = Directory.new()
	var file = File.new()
	var filename
	var error = dir.change_dir("res://cards")
	if (error!=OK):
		print("Can't open data directory!")
		return
	error = dir.list_dir_begin(true)
	if (error!=OK):
		print("Can't open data directory!")
		return
	
	filename = dir.get_next()
	while filename!="":
		error = file.open("res://cards/"+filename,File.READ)
		if (error!=OK):
			print("Can't open file "+filename+"!")
			continue
		else:
			print("Loading cards "+filename+".")
		
		while (!file.eof_reached()):
			var currentline = JSON.parse(file.get_line()).get_result()
			if (currentline==null || !currentline.has("name")):
				continue
			data[currentline["name"]] = currentline
			if (currentline.has("level")):
				if (currentline["level"]<5):
					cards_tier1[currentline["grade"]].push_back(currentline["name"])
				if (currentline["level"]>2 && currentline["level"]<8):
					cards_tier2[currentline["grade"]].push_back(currentline["name"])
				if (currentline["level"]>5):
					cards_tier3[currentline["grade"]].push_back(currentline["name"])
			
			for i in range(4-currentline["grade"]):
				all_cards.push_back(currentline["name"])
		filename = dir.get_next()

func calc_value(ID,value):
	if (value=="level"):
		return data[ID]["level"]
	elif (value=="production"):
		return int("production 1" in data[ID]["effects"])+2*int("production 2" in data[ID]["effects"])
	elif (value=="dmg"):
		return data[ID]["dmg"]+4*int("direct damage 4" in data[ID]["effects"])+6*int("direct damage 6" in data[ID]["effects"])
	elif (value=="structure"):
		return data[ID]["structure"]
	elif (value=="shield"):
		return data[ID]["shield"]
	elif (value=="repair"):
		return 4*int("repair 4" in data[ID]["effects"])+6*int("repair 6" in data[ID]["effects"])+2*int("drydock" in data[ID]["effects"])
	elif (value=="movement cost"):
		return int(!("no movement cost" in data[ID]["effects"]))+int("expensive movement" in data[ID]["effects"])
	elif (value=="attack cost"):
		return int(!("no attack cost" in data[ID]["effects"]))+int("expensive attack" in data[ID]["effects"])
	elif (value=="bombardment"):
		return 2*int("bombardment 2" in data[ID]["effects"])+4*int("bombardment 4" in data[ID]["effects"])
	elif (value=="mine damage"):
		return int("mines 1" in data[ID]["effects"])+2*int("mines 2" in data[ID]["effects"])
	
	print("ERROR: "+value)
	return


# return random card

func get_tier1_card(faction="rnd"):
	var card
	while (card==null):
		var grade = [0,0,0,1,1,1,2,2,3,3][randi()%10]
		if (cards_tier1[grade].size()>0):
			card = cards_tier1[grade][randi()%cards_tier1[grade].size()]
			if (faction!="rnd" && faction!=data[card]["faction"]):
				card = null
	
	return card

func get_tier2_card(faction="rnd"):
	var card
	while (card==null):
		var grade = [0,0,0,1,1,1,2,2,3,3][randi()%10]
		if (cards_tier2[grade].size()>0):
			card = cards_tier2[grade][randi()%cards_tier2[grade].size()]
			if (faction!="rnd" && faction!=data[card]["faction"]):
				card = null
	
	return card

func get_tier3_card(faction="rnd"):
	var card
	while (card==null):
		var grade = [0,0,0,1,1,1,2,2,3,3][randi()%10]
		if (cards_tier3[grade].size()>0):
			card = cards_tier3[grade][randi()%cards_tier3[grade].size()]
			if (faction!="rnd" && faction!=data[card]["faction"]):
				card = null
	
	return card

# return random unit card

func get_tier1_unit(faction="rnd"):
	var card
	while (card==null):
		var grade = [0,0,0,1,1,1,2,2,3,3][randi()%10]
		if (cards_tier1[grade].size()>0):
			card = cards_tier1[grade][randi()%cards_tier1[grade].size()]
			if (data[card]["type"]!="unit" || (faction!="rnd" && faction!=data[card]["faction"])):
				card = null
	
	return card

func get_tier2_unit(faction="rnd"):
	var card
	while (card==null):
		var grade = [0,0,0,1,1,1,2,2,3,3][randi()%10]
		if (cards_tier2[grade].size()>0):
			card = cards_tier2[grade][randi()%cards_tier2[grade].size()]
			if (data[card]["type"]!="unit" || (faction!="rnd" && faction!=data[card]["faction"])):
				card = null
	
	return card

func get_tier3_unit(faction="rnd"):
	var card
	while (card==null):
		var grade = [0,0,0,1,1,1,2,2,3,3][randi()%10]
		if (cards_tier3[grade].size()>0):
			card = cards_tier3[grade][randi()%cards_tier3[grade].size()]
			if (data[card]["type"]!="unit" || (faction!="rnd" && faction!=data[card]["faction"])):
				card = null
	
	return card




func _ready():
	load_data()
