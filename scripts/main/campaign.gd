extends Node

const star_type = [
"star_blue01","star_blue02","star_blue03","star_blue04",
"star_orange01","star_orange02","star_orange03","star_orange04",
"star_red01","star_red02","star_red03","star_red04",
"star_white01","star_white02","star_white03","star_white04",
"star_yellow01","star_yellow02","star_yellow03","star_yellow04"]
const POS = [Vector2(50,250),Vector2(-50,-250),Vector2(300,-50),Vector2(-300,50),Vector2(0,0)]

var stars = []
var credits = 0
var max_deck_size = 20
var inventory = []
var deck = []

class Star:
	var type
	var position
	var planets
	var owner
	
	func _init(_type,_pos,_planets,_owner):
		type = _type
		position = _pos
		planets = _planets
		owner = _owner
	
	func to_dict():
		var _planets = []
		_planets.resize(planets.size())
		for i in range(planets.size()):
			_planets[i] = planets[i].to_dict()
		var dict = {"type":type,"pos_x":position.x,"pos_y":position.y,"planets":_planets,"owner":owner}
		return dict

class Planet:
	var type
	var image
	var points
	var owner
	var structure
	var damage
	var shield
	
	func _init(_type,_image,_points,_owner,_structure,_damage,_shield):
		type = _type
		image = _image
		points = _points
		owner = _owner
		structure = _structure
		damage = _damage
		shield = _shield
	
	func to_dict():
		var dict = {"type":type,"image":image,"points":points,"owner":owner,"structure":structure,"damage":damage,"shield":shield}
		return dict


func _save():
	var file = File.new()
	print("SAVE CAMPAIGN")
	get_node("/root/Menu").create_save_dir()
	file.open("user://campaign.sav",File.WRITE)
	file.store_line({"credits":credits,"inventory":inventory,"deck":deck}.to_json())
	for s in stars:
		file.store_line(s.to_dict().to_json())
	file.close()

func _load():
	var file = File.new()
	if (!file.file_exists("user://campaign.sav")):
		return false
	
	file.open("user://campaign.sav",File.READ)
	stars.clear()
	
	var currentline = {}
	currentline.parse_json(file.get_line())
	credits = currentline["credits"]
	inventory = currentline["inventory"]
	deck = currentline["deck"]
	
	while (!file.eof_reached()):
		var currentline = {}
		var planets
		var _planets = []
		currentline.parse_json(file.get_line())
		if (!currentline.has("planets")):
			continue
		planets = currentline["planets"]
		_planets.resize(planets.size())
		for i in range(planets.size()):
			var p = {}
			p = planets[i]
			_planets[i] = Planet.new(int(p["type"]),int(p["image"]),int(p["points"]),int(p["owner"]),int(p["structure"]),int(p["damage"]),int(p["shield"]))
		stars.push_back(Star.new(str(currentline["type"]),Vector2(currentline["pos_x"],int(currentline["pos_y"])),_planets,int(currentline["owner"])))
	
	file.close()
	update_deck()
	return true




func new(num_stars):
#	stars.resize(num_stars)
	stars.clear()
	for i in range(num_stars):
		var planets = []
		var num_planets = randi()%3+3
		var pos = rand_pos(Vector2(0,0),256)
		var faction = 0
		for i in range(POS.size()):
			if (POS[i].distance_squared_to(pos)<100*100):
				faction = i+1
				break
		planets.resize(num_planets)
		for j in range(num_planets):
			var type = (randi()%8)-1
			var owner = 0
			if (j==0):
				owner = 1
			elif (j==num_planets-1):
#				owner = max(faction,2)
				owner = 2
			elif (faction>1 && randf()<0.5):
#				owner = faction
				owner = 2
			planets[j] = Planet.new(type,randi()%5,[5,3,4,5,6,5,4,3,4][type+1],owner,4*int(type==3)+4*int(owner>0),0,int(faction>0 && owner>0))
		
		stars.push_back(Star.new(star_type[randi()%(star_type.size())],pos,planets,faction))
	
	inventory = []
	deck = ["fighter","fighter","light_fighter","light_fighter","freighter","freighter","space_station","defender","corvette","cruiser","destroyer","asteroid_ship",
	"draw_3","points_2","upgrade_weapons","planetary_defense_6","repair_4","repair_4","factory_world","planetary_barrier"]
	credits = 50
	update_deck()

func update_deck():
	max_deck_size = get_num_cards(1)
	for i in range(deck.size()-1,max_deck_size-1,-1):
		inventory.push_back(deck[i])
		deck.remove(i)

func get_num_cards(ID):
	var num_planets = 0
	var num_planets = 0
	for s in stars:
		if (s.owner==ID):
			num_planets += 1
	
	return 20+floor(max(num_planets-1,0)/2)



# random star position

func rand_pos(m,s):
	var pos# = randg(m,s)
	var c = true
	while c:
		pos = randg(m,s)
		c = pos.x<-500 || pos.x>500 || pos.y<-400 || pos.y>400
		if (!c):
			for s in stars:
				if (pos.distance_squared_to(s.position)<50*50):
					c = true
					break
	
	return pos

func randg(m,s):
#	returns a pair of independent Gauss ditributed random number
	var r
	var u = rand_range(-1,1)
	var v = rand_range(-1,1)
	while(u*u+v*v>=1):
		u = rand_range(-1,1)
		v = rand_range(-1,1)
	
	r = sqrt(-log(u*u+v*v)/(u*u+v*v))
	return Vector2(r*u*s,r*v*s)+m
