extends Node

const MAX_CARDS = 40
const DECK_DEFAULT = {"default":[
"fighter","fighter","fighter","light_fighter","light_fighter","fighter_flamer","fighter_flamer",
"space_station","space_station","planetary_defense_network",
"factory","repair_ship","defender",
"cruiser","destroyer","asteroid_ship","carrier","carrier","battleship","battleship","assault_carrier",
"draw_3","points_2","points_2",
"terraforming","long_range_torpedos","long_range_torpedos","sabotage","sabotage",
"upgrade_weapons","armor_plating","upgrade_shields",
"planetary_defense_6","planetary_defense_6",
"repair_4","repair_6","repair_6",
"orbital_drydock","factory_world","planetary_barrier"]}

var data = {}
var inventory = []
var all_cards = []
var deck = []+DECK_DEFAULT["default"]
var cards_tier1 = [[],[],[],[],[]]
var cards_tier2 = [[],[],[],[],[]]
var cards_tier3 = [[],[],[],[],[]]

func load_data():
	var file = File.new()
	if (!file.file_exists("res://scripts/cards/data.json")):
		print("no data to load found")
		return
	
	file.open("res://scripts/cards/data.json",File.READ)
	while (!file.eof_reached()):
		var currentline = {}
		currentline.parse_json(file.get_line())
		if !currentline.has("name"):
			continue
		data[currentline["name"]] = currentline
		if (currentline.has("level")):
			if (currentline["level"]<=5):
				cards_tier1[currentline["grade"]].push_back(currentline["name"])
			if (currentline["level"]>=3 && currentline["level"]<=8):
				cards_tier2[currentline["grade"]].push_back(currentline["name"])
			if (currentline["level"]>=5 && currentline["level"]<=10):
				cards_tier3[currentline["grade"]].push_back(currentline["name"])
		
		for i in range(4-currentline["grade"]):
			all_cards.push_back(currentline["name"])
	
	update_inventory()

func update_inventory():
	inventory = []+all_cards
	for c in deck:
		inventory.erase(c)

func calc_value(ID,value):
	if (value=="level"):
		return data[ID]["level"]
	elif (value=="production"):
		return ("production 1" in data[ID]["effects"])+2*("production 2" in data[ID]["effects"])
	elif (value=="dmg"):
		return data[ID]["dmg"]
	elif (value=="structure"):
		return data[ID]["structure"]
	elif (value=="shield"):
		return data[ID]["shield"]
	elif (value=="repair"):
		return 4*("repair 4" in data[ID]["effects"])+6*("repair 6" in data[ID]["effects"])+2*("drydock" in data[ID]["effects"])
	elif (value=="movement cost"):
		return !("no movement cost" in data[ID]["effects"])+("expensive movement" in data[ID]["effects"])
	elif (value=="attack cost"):
		return !("no attack cost" in data[ID]["effects"])+("expensive attack" in data[ID]["effects"])
	elif (value=="bombardment"):
		return 2*("bombardment 2" in data[ID]["effects"])+4*("bombardment 4" in data[ID]["effects"])
	elif (value=="mine damage"):
		return ("mines 1" in data[ID]["effects"])+2*("mines 2" in data[ID]["effects"])
	
	print("ERROR: "+value)
	return


# return random card

func get_tier1_card():
	var card
	while (card==null):
		var grade = randi()%3
		if (cards_tier1[grade].size()>0):
			card = cards_tier1[grade][randi()%cards_tier1[grade].size()]
	
	return card

func get_tier2_card():
	var card
	while (card==null):
		var grade = randi()%3
		if (cards_tier2[grade].size()>0):
			card = cards_tier2[grade][randi()%cards_tier2[grade].size()]
	
	return card

func get_tier3_card():
	var card
	while (card==null):
		var grade = randi()%3
		if (cards_tier3[grade].size()>0):
			card = cards_tier3[grade][randi()%cards_tier3[grade].size()]
	
	return card

# return random unit card

func get_tier1_unit():
	var card
	while (card==null):
		var grade = randi()%3
		if (cards_tier1[grade].size()>0):
			card = cards_tier1[grade][randi()%cards_tier1[grade].size()]
			if (data[card]["type"]!="unit"):
				card = null
	
	return card

func get_tier2_unit():
	var card
	while (card==null):
		var grade = randi()%3
		if (cards_tier2[grade].size()>0):
			card = cards_tier2[grade][randi()%cards_tier2[grade].size()]
			if (data[card]["type"]!="unit"):
				card = null
	
	return card

func get_tier3_unit():
	var card
	while (card==null):
		var grade = randi()%3
		if (cards_tier3[grade].size()>0):
			card = cards_tier3[grade][randi()%cards_tier3[grade].size()]
			if (data[card]["type"]!="unit"):
				card = null
	
	return card




func _ready():
	load_data()
