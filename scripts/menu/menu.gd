extends CanvasLayer

const SAVE = 0
const LOAD = 1
const PLANET_GAS = -1
const PLANET_BARREN = 0
const PLANET_TUNDRA = 1
const PLANET_DESERT = 2
const PLANET_TERRAN = 3
const PLANET_OCEAN = 4
const PLANET_TOXIC = 5
const PLANET_INFERNO = 6
const PLANET_ASTEROID = 7

const planet_icons = {
PLANET_GAS:[preload("res://images/planets/gas01.png"),preload("res://images/planets/gas02.png"),preload("res://images/planets/gas03.png"),preload("res://images/planets/gas04.png"),preload("res://images/planets/gas05.png")],
PLANET_BARREN:[preload("res://images/planets/barren01.png"),preload("res://images/planets/barren02.png"),preload("res://images/planets/barren03.png"),preload("res://images/planets/barren04.png"),preload("res://images/planets/barren05.png")],
PLANET_TUNDRA:[preload("res://images/planets/tundra01.png"),preload("res://images/planets/tundra02.png"),preload("res://images/planets/tundra03.png"),preload("res://images/planets/tundra04.png"),preload("res://images/planets/tundra05.png")],
PLANET_DESERT:[preload("res://images/planets/desert01.png"),preload("res://images/planets/desert02.png"),preload("res://images/planets/desert03.png"),preload("res://images/planets/desert04.png"),preload("res://images/planets/desert05.png")],
PLANET_TERRAN:[preload("res://images/planets/terran01.png"),preload("res://images/planets/terran02.png"),preload("res://images/planets/terran03.png"),preload("res://images/planets/terran04.png"),preload("res://images/planets/terran05.png")],
PLANET_OCEAN:[preload("res://images/planets/ocean01.png"),preload("res://images/planets/ocean02.png"),preload("res://images/planets/ocean03.png"),preload("res://images/planets/ocean04.png"),preload("res://images/planets/ocean05.png")],
PLANET_TOXIC:[preload("res://images/planets/toxic01.png"),preload("res://images/planets/toxic02.png"),preload("res://images/planets/toxic03.png"),preload("res://images/planets/toxic04.png"),preload("res://images/planets/toxic05.png")],
PLANET_INFERNO:[preload("res://images/planets/inferno01.png"),preload("res://images/planets/inferno02.png"),preload("res://images/planets/inferno03.png"),preload("res://images/planets/inferno04.png"),preload("res://images/planets/inferno05.png")]}
const FACTION_COLOUR = [
Color(0.75,0.75,0.75),Color(0.1,1.0,0.2),Color(1.0,0.2,0.1),Color(0.9,0.4,0.0),Color(0.8,0.0,0.6),Color(0.2,0.1,0.8)]


var card_selected
var deck_selected
var resolution = Vector2(1280,720)
var fullscreen = false
var maximized = false
var music = 100
var sound = 100
var mode = SAVE
var deck_file
var last_file_button
var map_scroll = false
var last_mouse_pos = Vector2(0,0)
var star_selected = -1
var campaign = false
var campaign_battle = false
var add_credits = 0


var main_scene = preload("res://scenes/main/main.tscn")


func end_match(win):
	if (win):
		get_node("BattleEnd").set_title(tr("WON!"))
		if (campaign):
			Campaign.stars[star_selected].owner = 1
			Campaign.credits += add_credits
			Campaign.update_deck()
			get_node("BattleEnd/Text").set_text(str(add_credits)+tr("CREDITS")+" "+tr("GAINED")+"!")
		else:
			get_node("BattleEnd/Text").set_text("")
	else:
		get_node("BattleEnd").set_title(tr("LOST!"))
		get_node("BattleEnd/Text").set_text("")
	if (campaign):
		Campaign._save()
		_select_star(-1)
		update_map()
		show_map()
	else:
		show_main()
	get_node("BattleEnd").popup()

func _skirmish():
	var mi = main_scene.instance()
	campaign_battle = false
	
	mi.SIZE = 4				# number of planets
	mi.POSITIONS = 3		# number of fields per planet
	mi.deck[0] = []+Data.deck
	mi.randomize_deck(mi.PLAYER2,Data.MAX_CARDS)
	mi.planets = randomize_planets(mi.SIZE)
	
	get_tree().get_root().add_child(mi)
	get_node("Panel").hide()

func _campaign():
	if (!campaign || star_selected<0):
		return
	
	var system = Campaign.stars[star_selected]
	var ai_cards = 25
	var planets = []
	var num_enemy_planets = 0
	var mi = main_scene.instance()
	campaign_battle = true
	Campaign._save()
	
	if (system.owner>1):
		ai_cards = Campaign.get_num_cards(system.owner)+5
	
	mi.SIZE = system.planets.size()
	mi.POSITIONS = 3
	
	planets.resize(system.planets.size())
	for i in range(system.planets.size()):
		var p = system.planets[i]
		planets[i] = {"type":p.type,"image":p.image,"points":p.points,"owner":p.owner-1,"structure":p.structure,"damage":p.damage,"shield":p.shield,"level":0}
		if (p.owner>1):
			num_enemy_planets += 1
	
	mi.deck[0] = []+Campaign.deck
	mi.randomize_deck(mi.PLAYER2,ai_cards+5*(system.planets.size()-3))
	mi.planets = planets
	get_tree().get_root().add_child(mi)
	add_credits = 250+randi()%50+200*int(system.owner>1)+50*num_enemy_planets
	get_node("Map").hide()

func randomize_planets(size):
	var planets = []
	planets.resize(size)
	for i in range(size):
		var type = (randi()%8)-1
		var points = [5,3,4,5,6,5,4,3,4][type+1]
		var structure = 0
		var owner = -1
		if (type==PLANET_TERRAN):
			structure = 4
		if (i==0):
			owner = 0
		elif (i==size-1):
			owner = 1
		planets[i] = {"type":type,"image":randi()%5,"points":points,"owner":owner,"structure":structure,"damage":0,"shield":0,"level":0}
	return planets


func add_card():
	var deck
	var inventory
	var max_cards
	if (campaign):
		deck = Campaign.deck
		inventory = Campaign.inventory
		max_cards = Campaign.max_deck_size
	else:
		deck = Data.deck
		inventory = Data.inventory
		max_cards = Data.MAX_CARDS
	if (card_selected!=null && deck.size()<max_cards):
		deck.push_back(inventory[card_selected])
		inventory.remove(card_selected)
		update_cards()
		card_selected = null

func remove_card():
	var deck
	var inventory
	if (campaign):
		deck = Campaign.deck
		inventory = Campaign.inventory
	else:
		deck = Data.deck
		inventory = Data.inventory
	if (deck_selected!=null):
		inventory.push_back(deck[deck_selected])
		deck.remove(deck_selected)
		update_cards()
		deck_selected = null

func select_deck(ID):
	unselect()
	card_selected = null
	deck_selected = ID
	
	for c in get_node("Deck/Card").get_children():
		c.queue_free()
	
	var card
	if (campaign):
		card = Campaign.deck[ID]
	else:
		card = Data.deck[ID]
	var ci = Cards.create_card(card)
	ci.set_scale(Vector2(0.75,0.75))
	ci.set_pos(Vector2(152,214))
	get_node("Deck/Card").add_child(ci)

func select_card(ID):
	unselect()
	card_selected = ID
	deck_selected = null
	
	for c in get_node("Deck/Card").get_children():
		c.queue_free()
	
	var card
	if (campaign):
		card = Campaign.inventory[ID]
	else:
		card = Data.inventory[ID]
	var ci = Cards.create_card(card)
	ci.set_scale(Vector2(0.75,0.75))
	ci.set_pos(Vector2(152,214))
	get_node("Deck/Card").add_child(ci)

func unselect():
	if (card_selected!=null and get_node("Deck/Cards/GridContainer/Card"+str(card_selected))):
		get_node("Deck/Cards/GridContainer/Card"+str(card_selected)).set_pressed(false)
	if (deck_selected!=null and get_node("Deck/Deck/GridContainer/Card"+str(deck_selected))):
		get_node("Deck/Deck/GridContainer/Card"+str(deck_selected)).set_pressed(false)

func update_cards():
	var deck
	var inventory
	var max_cards
	if (campaign):
		deck = Campaign.deck
		inventory = Campaign.inventory
		max_cards = Campaign.max_deck_size
	else:
		deck = Data.deck
		inventory = Data.inventory
		max_cards = Data.MAX_CARDS
	
	for c in get_node("Deck/Cards/GridContainer").get_children()+get_node("Deck/Deck/GridContainer").get_children():
		c.set_name("deleted")
		c.queue_free()
	
	for i in range(deck.size()):
		var bi = Button.new()
		bi.connect("pressed",self,"select_deck",[i])
		bi.set_name("Card"+str(i))
		bi.set_text(tr(Data.data[deck[i]]["name"]))
		bi.set_h_size_flags(Control.SIZE_EXPAND_FILL)
		bi.set_toggle_mode(true)
		bi.set_custom_minimum_size(Vector2(0,32))
		get_node("Deck/Deck/GridContainer").add_child(bi)
	
	for i in range(inventory.size()):
		var bi = Button.new()
		bi.connect("pressed",self,"select_card",[i])
		bi.set_name("Card"+str(i))
		bi.set_text(tr(Data.data[inventory[i]]["name"]))
		bi.set_h_size_flags(Control.SIZE_EXPAND_FILL)
		bi.set_toggle_mode(true)
		bi.set_custom_minimum_size(Vector2(0,32))
		get_node("Deck/Cards/GridContainer").add_child(bi)
	
	get_node("Deck/Text1").set_text(tr("DECK")+": "+str(deck.size())+" / "+str(max_cards)+" "+tr("CARDS"))
	get_node("Deck/Text2").set_text(tr("INVENTORY")+": "+str(inventory.size())+" "+tr("CARDS"))

func show_deck():
	campaign = false
	update_cards()
	get_node("Deck").show()
	get_node("Deck/Panel/VBoxContainer/ButtonSave").show()
	get_node("Deck/Panel/VBoxContainer/ButtonLoad").show()
	get_node("Map").hide()
	get_node("Panel").hide()

func show_map():
	campaign = true
	get_node("Map/Panel/VBoxContainer/ButtonAttack").set_disabled(star_selected<0)
	get_node("Deck").hide()
	get_node("Map").show()
	get_node("Panel").hide()

func show_main():
	campaign = false
	get_node("Deck").hide()
	get_node("Map").hide()
	get_node("Panel").show()

func show_shop():
	get_node("Shop").show()

func hide_shop():
	get_node("Shop").hide()

func show_deck_campaign():
	campaign = true
	update_cards()
	get_node("Deck").show()
	get_node("Deck/Panel/VBoxContainer/ButtonSave").hide()
	get_node("Deck/Panel/VBoxContainer/ButtonLoad").hide()
	get_node("Map").hide()
	get_node("Panel").hide()

func hide_deck():
	if (campaign):
		show_map()
	else:
		show_main()

func show_quit():
	get_node("Quit").popup_centered(Vector2(0,0))

func quit():
	Campaign._save()
	save_config()
	get_tree().quit()

func create_save_dir():
	var dir = Directory.new()
	if (!dir.dir_exists("user://decks")):
		dir.make_dir_recursive("user://decks")

func _load():
	return
	var file = File.new()
	
	Campaign._load()
	
	if (!file.file_exists("user://cards.save")):
		print("No save file found!")
		return 
	var error = file.open_encrypted_with_pass("user://cards.save",File.READ,OS.get_unique_ID())
	
	if (error==OK):
		while (!file.eof_reached()):
			var currentline = {}
			currentline.parse_json(file.get_line())
			if (currentline.has("deck")):
				Data.deck = currentline["deck"]

func _default():
	resolution = OS.get_screen_size()
	fullscreen = false
	maximized = true
	
	apply_settings()
	save_config()

func load_config():
	var file = File.new()
	if (!file.file_exists("user://settings.cfg")):
		print("No config file found!")
		_default()
		return
	
	var error = file.open("user://settings.cfg",File.READ)
	
	if (error==OK):
		while (!file.eof_reached()):
			var currentline = {}
			currentline.parse_json(file.get_line())
			if currentline.has("resolution_x"):
				resolution = Vector2(currentline["resolution_x"],currentline["resolution_y"])
			elif currentline.has("fullscreen"):
				fullscreen = currentline["fullscreen"]
				maximized = currentline["maximized"]
			elif currentline.has("music"):
				music = currentline["music"]
				sound = currentline["sound"]
	
	file.close()
	apply_settings()

func save_config():
	create_save_dir()
	
	var file = File.new()
	var error = file.open("user://settings.cfg",File.WRITE)
	
	resolution = OS.get_video_mode_size()
	fullscreen = OS.is_window_fullscreen()
	maximized = OS.is_window_maximized()
	
	file.store_line({"resolution_x":resolution.x,"resolution_y":resolution.y}.to_json())
	file.store_line({"fullscreen":fullscreen,"maximized":maximized}.to_json())
	file.store_line({"music":music,"sound":sound}.to_json())
	
	file.close()

func apply_settings():
	OS.set_window_size(resolution)
	OS.set_window_fullscreen(fullscreen)
	OS.set_window_maximized(maximized)
	AudioServer.set_stream_global_volume_scale(music/100.0)
	AudioServer.set_fx_global_volume_scale(sound/100.0)

func _resize():
	var c = int(OS.get_video_mode_size().x*4.0/1024.0)
	get_node("Deck/Cards/GridContainer").set_columns(c)
	get_node("Deck/Deck/GridContainer").set_columns(c)

func _input(event):
	if (event.is_action_pressed("cancel")):
		if (get_node("Panel").is_hidden()):
			show_main()
		elif (get_node("Quit").is_hidden()):
			show_quit()
		else:
			quit()

func _process(delta):
	if (map_scroll):
		var offset = get_node("Map/ScrollContainer").get_global_mouse_pos()-last_mouse_pos
		get_node("Map/ScrollContainer").set_h_scroll(get_node("Map/ScrollContainer").get_h_scroll()-delta*100.0*offset.x)
		get_node("Map/ScrollContainer").set_v_scroll(get_node("Map/ScrollContainer").get_v_scroll()-delta*100.0*offset.y)
		last_mouse_pos = get_node("Map/ScrollContainer").get_global_mouse_pos()

func _ready():
	randomize()
	set_process(true)
	set_process_input(true)
	get_tree().connect("screen_resized",self,"_resize")
	load_config()
	_resize()
	_load()
	
	update_cards()


func _show_deck_load():
	mode = LOAD
	get_node("Deck/Load/HBoxContainer/ButtonLoad").show()
	get_node("Deck/Load/HBoxContainer/ButtonSave").hide()
	get_node("Deck/Load/ScrollContainer/VBoxContainer/New").hide()
	get_node("Deck/Load/Title").set_text(tr("LOAD"))
	get_node("Deck/Load").show()
	
	for i in range(Data.DECK_DEFAULT.size()):
		if !has_node("Deck/Load/ScrollContainer/VBoxContainer/ButtonDefault"+str(i)):
			var bi = get_node("Deck/Load/ScrollContainer/VBoxContainer/Button").duplicate()
			bi.set_name("ButtonDefault"+str(i))
			bi.set_text(tr(Data.DECK_DEFAULT.keys()[i]))
			bi.connect("pressed",self,"_select_deck",[Data.DECK_DEFAULT.keys()[i],bi])
			bi.show()
			get_node("Deck/Load/ScrollContainer/VBoxContainer").add_child(bi)
		
	
	list_save_files()

func _show_deck_save():
	mode = SAVE
	get_node("Deck/Load/HBoxContainer/ButtonLoad").hide()
	get_node("Deck/Load/HBoxContainer/ButtonSave").show()
	get_node("Deck/Load/ScrollContainer/VBoxContainer/New").show()
	get_node("Deck/Load/Title").set_text(tr("SAVE"))
	get_node("Deck/Load").show()
	
	list_save_files()


func _select_deck(file,button):
	deck_file = file
	if (last_file_button!=null):
		last_file_button.set_pressed(false)
	last_file_button = button
	button.set_pressed(true)

func list_save_files():
	var dir = Directory.new()
	var error = dir.open("user://decks")
	if (error!=OK):
		return
	
	var deck_files = []
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while (file_name!=""):
		if (!dir.current_is_dir()):
			deck_files.push_back(file_name.replace(".sav",""))
		file_name = dir.get_next()
	dir.list_dir_end()
	
	for i in range(deck_files.size()):
		if !has_node("Deck/Load/ScrollContainer/VBoxContainer/Button"+str(i)):
			var bi = get_node("Deck/Load/ScrollContainer/VBoxContainer/Button").duplicate()
			bi.set_name("Button"+str(i))
			bi.set_text(deck_files[i])
			bi.connect("pressed",self,"_select_deck",[deck_files[i],bi])
			bi.show()
			get_node("Deck/Load/ScrollContainer/VBoxContainer").add_child(bi)

func _deck_load():
	var file = File.new()
	if (!file.file_exists("user://decks/"+deck_file+".sav")):
		if Data.DECK_DEFAULT.has(deck_file):
			Data.deck = []+Data.DECK_DEFAULT[deck_file]
			Data.update_inventory()
		get_node("Deck/Load").hide()
		update_cards()
		return
	
	file.open("user://decks/"+deck_file+".sav",File.READ)
	Data.deck.clear()
	while (!file.eof_reached()):
		var card = file.get_line()
		if (card!=""):
			Data.deck.push_back(card)
	Data.update_inventory()
	file.close()
	get_node("Deck/Load").hide()
	update_cards()

func _deck_save():
	var file = File.new()
	create_save_dir()
	file.open("user://decks/"+deck_file+".sav",File.WRITE)
	for c in Data.deck:
		file.store_line(c)
	file.close()
	get_node("Deck/Load").hide()

func _set_deck_file(file):
	deck_file = file
	if (last_file_button!=null):
		last_file_button.set_pressed(false)


func _map_input(ev):
	if (ev.type==InputEvent.MOUSE_BUTTON && ev.button_index==1):
		map_scroll = ev.pressed
		last_mouse_pos = get_node("Map/ScrollContainer").get_global_mouse_pos()



func update_map():
	var planets_controled = 0
	for i in range(Campaign.stars.size()):
		var s = Campaign.stars[i]
		var button
		if (s.owner==1):
			planets_controled += 1
		if (!has_node("Map/ScrollContainer/CenterContainer/Background/Button"+str(i))):
			button = get_node("Map/ScrollContainer/CenterContainer/Background/Button").duplicate()
			button.set_name("Button"+str(i))
			button.show()
			get_node("Map/ScrollContainer/CenterContainer/Background").add_child(button)
			button.connect("pressed",self,"_select_star",[i])
		else:
			button = get_node("Map/ScrollContainer/CenterContainer/Background/Button"+str(i))
		button.get_node("Icon").set_texture(load("res://images/star_icons/"+s.type+".png"))
		button.set_disabled(s.owner==1)
		button.set_pos(get_node("Map/ScrollContainer/CenterContainer/Background").get_size()/2+s.position)
	
	get_node("Map/Status/VBoxContainer/Text1").set_text(tr("CREDITS")+": "+str(Campaign.credits))
	get_node("Map/Status/VBoxContainer/Text2").set_text(tr("NUMBER_OF_PLANETS")+": "+str(planets_controled)+" / "+str(Campaign.stars.size()))
	get_node("Map/Status/VBoxContainer/Text3").set_text(tr("NUMBER_OF_CARDS")+": "+str(Campaign.inventory.size()+Campaign.deck.size()))
	get_node("Map/Status/VBoxContainer/Text4").set_text(tr("MAX_DECK_SIZE")+": "+str(Campaign.max_deck_size))

func _select_star(ID):
	var planets
	var num_planets
	star_selected = ID
	if (ID>=0):
		planets = Campaign.stars[ID].planets
		num_planets = planets.size()
		get_node("Map/System/Icon").set_texture(load("res://images/star_icons/"+Campaign.stars[ID].type+".png"))
	else:
		planets = []
		num_planets = 0
		get_node("Map/System/Icon").set_texture(null)
	for c in get_node("Map/System/HBoxContainer").get_children()+get_node("Map/System/HBoxContainer2").get_children():
		c.hide()
	for i in range(num_planets):
		if (!has_node("Map/System/HBoxContainer/Planet"+str(i))):
			var arrow = get_node("Map/System/HBoxContainer2/Planet0").duplicate()
			var icon = get_node("Map/System/HBoxContainer/Planet0").duplicate()
			icon.set_name("Planet"+str(i))
			icon.show()
			get_node("Map/System/HBoxContainer").add_child(icon)
			arrow.set_name("Planet"+str(i))
			arrow.show()
			get_node("Map/System/HBoxContainer2").add_child(arrow)
	get_node("Map/System/HBoxContainer/Space").show()
	get_node("Map/System/HBoxContainer/Space").raise()
	get_node("Map/System/HBoxContainer2/Space").show()
	get_node("Map/System/HBoxContainer2/Space").raise()
	for i in range(num_planets):
		var arrow = get_node("Map/System/HBoxContainer2/Planet"+str(i))
		var icon = get_node("Map/System/HBoxContainer/Planet"+str(i))
		icon.set_texture(planet_icons[planets[num_planets-1-i].type][planets[num_planets-1-i].image])
		icon.show()
		arrow.set_modulate(FACTION_COLOUR[planets[num_planets-1-i].owner])
		arrow.show()
	
	get_node("Map/Panel/VBoxContainer/ButtonAttack").set_disabled(false)

func start_campaign():
	var loaded = Campaign._load()
	if (!loaded):
		Campaign.new(100)
	update_map()
	show_map()


func buy_tier1():
	if (Campaign.credits<100):
		return
	
	var card = Data.get_tier1_card()
	Campaign.inventory.push_back(card)
	Campaign.credits -= 100
	show_card(card)
	update_map()

func buy_tier2():
	if (Campaign.credits<200):
		return
	
	var card = Data.get_tier2_card()
	Campaign.inventory.push_back(card)
	Campaign.credits -= 200
	show_card(card)
	update_map()

func buy_tier3():
	if (Campaign.credits<400):
		return
	
	var card = Data.get_tier3_card()
	Campaign.inventory.push_back(card)
	Campaign.credits -= 400
	show_card(card)
	update_map()


func show_card(card):
	var ci = Cards.create_card(card)
	for c in get_node("Card/Card").get_children():
		c.queue_free()
	ci.set_scale(Vector2(0.75,0.75))
	ci.set_pos(Vector2(152,214))
	get_node("Card/Card").add_child(ci)
	get_node("Card").show()

func hide_card():
	get_node("Card").hide()
