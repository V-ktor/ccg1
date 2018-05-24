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
	"booby_trab":2,"suicide":1,"virus":2,
	"large_mine_field":1
}
const TARGET_TYPE = {"hand":0,"empty":1,"unit":2,"ally_unit":3,"enemy_unit":4,"planet":5,"ally_planet":6,"enemy_planet":7,"empty_or_enemy":8}


var data = {}
var inventory = INVENTORY_DEFAULT.duplicate()
var all_cards = []
var deck = DECK_DEFAULT["empire"].duplicate()
var cards_tier1 = [[],[],[],[],[]]
var cards_tier2 = [[],[],[],[],[]]
var cards_tier3 = [[],[],[],[],[]]


class Effects:
	var Main
	var owner
	var _self


func load_path(path):
	var dir = Directory.new()
	var file = File.new()
	var filename
	var p = path.substr(0,path.find("://")+2)
	var error = dir.change_dir(path)
	if (error!=OK):
		print("Can't open data directory!")
		return
	error = dir.list_dir_begin(true)
	if (error!=OK):
		print("Can't open data directory!")
		return
	
	# load all data files in the cards directory
	filename = dir.get_next()
	while filename!="":
		# open file
		error = file.open("res://cards/"+filename,File.READ)
		if (error!=OK):
			print("Can't open file "+filename+"!")
			continue
		else:
			print("Loading cards "+filename+".")
		
		while (!file.eof_reached()):
			# gather all lines that are belonging to the same card
			var currentline = file.get_line()
			var num_brackets = 0
			var code = "var _self\nvar Main\n"
			var scr = GDScript.new()
			var effects = Effects.new()
			for s in currentline:
				num_brackets += int(s=="{")-int(s=="}")
			while (num_brackets>0):
				var new = file.get_line()
				for s in new:
					num_brackets += int(s=="{")-int(s=="}")
				currentline += "\n"+new
				if (file.eof_reached()):
					break
			if (currentline.length()<1):
				continue
			
			# parse data
			var raw = currentline
			currentline = JSON.parse(currentline)
			if (currentline.error!=OK):
				printt("Error parsing "+filename+".",raw)
				continue
			currentline = currentline.get_result()
			if (!currentline.has("name")):
				printt("Error parsing "+filename+" (missing name).")
				continue
			
			# set undefined values to default values
			for s in ["structure","shield","damage","cards"]:
				if (!currentline.has(s)):
					currentline[s] = 0
			for s in ["movement_points","attack_points"]:
				if (!currentline.has(s)):
					currentline[s] = 1
			if (currentline["type"]=="planet" && !currentline.has("target")):
				currentline["target"] = "ally_planet"
			currentline["path"] = p
			# make 'effects' an array
			if (!currentline.has("effects")):
				currentline["effects"] = []
			elif (typeof(currentline["effects"])!=TYPE_ARRAY):
				currentline["effects"] = [currentline["effects"]]
			# first add effect scripts
			for effect in currentline["effects"]:
				if (effect.has("script")):
					# correct indentation
					var p1
					var p2
					var n
					var script = effect["script"].replace("self","_self")
					p1 = script.find("func")
					p2 = script.rfind("\n",p1)
					n = p1-p2-2
					for i in range(script.length()-1,-1,-1):
						if (script[i]=="\n"):
							script = script.substr(0,i+1)+script.substr(i+n+2,script.length()-i-n-2)
#					printt(p1,p2,script==effect["script"],"\n",script)
					effect["script"] = script
				if (!effect.has("target")):
					effect["target"] = []
				elif (typeof(effect["target"])!=TYPE_ARRAY):
					effect["target"] = [effect["target"]]
				for i in range(effect["target"].size()):
					effect["target"][i] = TARGET_TYPE[effect["target"][i]]
			for effect in currentline["effects"]:
				if (effect.has("script")):
					code += effect["script"]+"\n"
			# add an array containing target types used for effect function call
			for effect in currentline["effects"]:
				if (effect.has("script")):
					var p1 = effect["script"].find("func ")+5
					var p2 = effect["script"].find("(",p1)
					var property = effect["script"].substr(p1,p2-p1)+"_targets"
					printt(property,effect["target"])
					code += "var "+property+" = "+str(effect["target"])+"\n"
			# add AI helper function that estimates usefullness
			if (currentline.has("effectiveness")):
				# correct indentation
				var p1
				var p2
				var n
				var script = currentline["effectiveness"].replace("self","_self")
				p1 = script.find("func")
				p2 = script.rfind("\n",p1)
				n = p1-p2-2
				for i in range(script.length()-1,-1,-1):
					if (script[i]=="\n"):
						script = script.substr(0,i+1)+script.substr(i+n+2,script.length()-i-n-2)
				code += "\n"+script
			
			# finally parse script
			scr.set_source_code(code)
#			printt(scr,"\n",code)
			scr.reload()
			effects.set_script(scr)
			# replace script string with class
			currentline["script"] = effects
			
			# add card data
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

func load_data():
	load_path("res://cards")
	load_path("user://cards")

func calc_value(ID,value):
	if (value=="level"):
		return data[ID]["level"]
	elif (value=="damage"):
		return data[ID]["damage"]
	elif (value=="structure"):
		return data[ID]["structure"]
	elif (value=="shield"):
		return data[ID]["shield"]
	elif (value=="cards"):
		return data[ID]["cards"]
	elif (value=="movement_points"):
		return data[ID]["movement_points"]
	elif (value=="attack_points"):
		return data[ID]["attack_points"]
	
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
