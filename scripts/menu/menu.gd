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

const FACTIONS_SKIRMISH = ["empire","rebels"]
const COST = [150,250,400]

var resolution = Vector2(1280,720)
var fullscreen = false
var maximized = false
var music = 100
var sound = 100
var mode = SAVE
var deck_file
var last_file_button
var last_mouse_pos = Vector2(0,0)
var star_selected = -1
var enemy
var add_credits = 0
var faction_stylebox = []
var filter = {"empire":true,"rebels":true,"pirates":true}
var player_name = tr("PLAYER")
var name_new = ""
var credits = 0

var main_scene = preload("res://scenes/main/main.tscn")
var tutorial_scene = preload("res://scenes/main/help.tscn")


func end_match(win,player=null):
	if (has_node("/root/Main")):
		get_node("/root/Main").queue_free()
	if (win):
		get_node("BattleEnd").set_title(tr("WON!"))
		credits += add_credits
		get_node("BattleEnd/Text").set_text(str(add_credits)+tr("CREDITS")+" "+tr("GAINED")+"!")
	else:
		credits += 50
		get_node("BattleEnd").set_title(tr("LOST!"))
		get_node("BattleEnd/Text").set_text("50"+tr("CREDITS")+" "+tr("GAINED")+"!")
	show_main()
	if (player!=null):
		rpc("end_match",player)
	get_node("Lobby")._cancel()
	get_node("BattleEnd").popup()

func start_game(planets,size,positions,player1_deck,player2_deck,player1_name,player2_name,player1_is_ai,player2_is_ai,id1=1,id2=0):
	var mi = main_scene.instance()
	
	mi.SIZE = size # number of planets
	mi.POSITIONS = positions # number of fields per planet
	mi.deck[0] = get_deck(player1_deck)
	mi.deck[1] = get_deck(player2_deck)
	mi.planets = planets
	mi.player_name = [player1_name,player2_name]
	mi.set_name("Main")
	mi.get_node("UI/Player1/VBoxContainer/Name").set_text(player1_name)
	mi.get_node("UI/Player2/Name").set_text(player2_name)
	mi.player_is_ai[0] = player1_is_ai
	mi.player_is_ai[1] = player2_is_ai
	mi.main_player = get_node("Lobby").player_self
	if (get_node("Lobby").player_self==0):
		mi.ID = id1
		mi.ID_enemy = id2
	else:
		mi.ID = id2
		mi.ID_enemy = id1
	
	if (has_node("/root/Main")):
		get_node("/root/Main").queue_free()
		get_node("/root/Main").set_name("deleted")
	get_tree().get_root().add_child(mi)
	get_node("Panel").hide()

func _skirmish():
	var factions = [FACTIONS_SKIRMISH[randi()%FACTIONS_SKIRMISH.size()]]
	
	if (randf()<0.3):
		factions.push_back(FACTIONS_SKIRMISH[randi()%FACTIONS_SKIRMISH.size()])
	elif (randf()<0.2):
		factions.push_back("pirates")
	
	add_credits = 150
	start_game(randomize_planets(4),4,3,Data.deck,randomize_deck(Data.MAX_CARDS,factions),player_name,tr("SKIRMISH_AI"),false,true)

func _tutorial():
	var ti = tutorial_scene.instance()
	add_credits = 50
	start_game([{"type":PLANET_TERRAN,"image":randi()%5,"cards":1,"owner":-1,"structure":0,"damage":0,"shield":0,"level":0},{"type":randi()%7,"image":randi()%5,"cards":1,"owner":-1,"structure":0,"damage":0,"shield":0,"level":0},{"type":PLANET_TERRAN,"image":randi()%5,"cards":1,"owner":-1,"structure":0,"damage":0,"shield":0,"level":0}],3,3,Data.DECK_DEFAULT["empire"],randomize_deck(Data.MAX_CARDS-10,["rebels"]),player_name,tr("SKIRMISH_AI"),false,true)
	get_node("/root/Main").tutorial = true
	get_node("/root/Main").add_child(ti)

func randomize_planets(size):
	var planets = []
	planets.resize(size)
	for i in range(size):
		var type = (randi()%8)-1
		var structure = 0
		var owner = -1
		if (type==PLANET_TERRAN):
			structure = 4
		if (i==0):
			owner = 0
		elif (i==size-1):
			owner = 1
		planets[i] = {"type":type,"image":randi()%5,"cards":1,"owner":owner,"structure":structure,"damage":0,"shield":0,"level":0}
	return planets

func randomize_deck(number,factions):
	var deck = []
	var ID = 0
	deck.resize(number)
	for i in range(0.3*number):
		deck[ID] = Data.get_tier1_unit(factions[randi()%factions.size()])
		ID += 1
	for i in range(0.2*number):
		deck[ID] = Data.get_tier1_card(factions[randi()%factions.size()])
		ID += 1
	for i in range(0.2*number):
		deck[ID] = Data.get_tier2_unit(factions[randi()%factions.size()])
		ID += 1
	for i in range(0.1*number):
		deck[ID] = Data.get_tier2_card(factions[randi()%factions.size()])
		ID += 1
	for i in range(0.1*number):
		deck[ID] = Data.get_tier3_unit(factions[randi()%factions.size()])
		ID += 1
	for i in range(0.1*number):
		deck[ID] = Data.get_tier3_card(factions[randi()%factions.size()])
		ID += 1
	
	return deck

func get_deck(from):
	printt(from,typeof(from))
	if (typeof(from)==TYPE_ARRAY):
		return from
	
	var deck = []
	
	for ID in from.keys():
		for i in range(from[ID]):
			deck.push_back(ID)
	
	return deck

func _add_card(ID):
	var deck
	var num_cards = 0
	var max_cards
	deck = Data.deck
	max_cards = Data.MAX_CARDS
	
	for n in deck.values():
		num_cards += n
	if (num_cards>max_cards):
		return false
	if (deck.has(ID) && (deck[ID]>2 || deck[ID]>=min(Data.inventory[ID],3))):
		return false
	
	if (deck.has(ID)):
		deck[ID] += 1
	else:
		deck[ID] = 1
	update_cards()
	
	return true

func _remove_card(ID):
	if (!Data.deck.has(ID)):
		return false
	
	if (Data.deck[ID]<2):
		Data.deck.erase(ID)
	else:
		Data.deck[ID] -= 1
	update_cards()
	
	return true

func update_cards():
	var num_cards = 0
	var pos = 0
	var cols = int((get_node("Deck").get_size().x-8)/175)
	
	for n in Data.deck.values():
		num_cards += n
	
	for c in get_node("Deck/Deck").get_children():
		c.hide()
	for c in get_node("Deck/Cards/Control").get_children():
		c.hide()
	
	for i in range(Data.inventory.size()):
		var bi
		var ID = Data.inventory.keys()[i]
		var ci = Cards.create_card(ID)
		var cards = 0
		var visible = filter[Data.data[ID]["faction"]]
		if (has_node("Deck/Cards/Control/Card"+str(i))):
			bi = get_node("Deck/Cards/Control/Card"+str(i))
			bi.get_node("Card").queue_free()
			bi.get_node("Card").set_name("deleted")
		else:
			bi = get_node("Deck/ButtonCard").duplicate()
			bi.set_name("Card"+str(i))
			bi.connect("gui_input",bi,"_input_event")
			bi.connect("mouse_exited",bi,"_mouse_exited")
			get_node("Deck/Cards/Control").add_child(bi)
		ci.set_position(Vector2(175,250))
		ci.set_draw_behind_parent(true)
		bi.set_position(Vector2(175*(pos%cols),250*floor(pos/cols)))
		bi.add_child(ci)
		if (Data.deck.has(ID)):
			cards = Data.deck[ID]
		bi.get_node("HBoxContainer/Label").set_text(str(cards)+" / "+str(min(Data.inventory.values()[i],3)))
		if (Data.deck.has(ID)):
			bi.get_node("HBoxContainer/ButtonAdd").set_disabled(num_cards>=Data.MAX_CARDS || Data.deck[ID]>=min(Data.inventory[ID],3))
		else:
			bi.get_node("HBoxContainer/ButtonAdd").set_disabled(num_cards>=Data.MAX_CARDS)
		bi.get_node("HBoxContainer/ButtonSub").set_disabled(!Data.deck.has(ID))
		if (bi.get_node("HBoxContainer/ButtonAdd").is_connected("pressed",self,"_add_card")):
			bi.get_node("HBoxContainer/ButtonAdd").disconnect("pressed",self,"_add_card")
		if (bi.get_node("HBoxContainer/ButtonSub").is_connected("pressed",self,"_remove_card")):
			bi.get_node("HBoxContainer/ButtonSub").disconnect("pressed",self,"_remove_card")
		bi.get_node("HBoxContainer/ButtonAdd").connect("pressed",self,"_add_card",[ID])
		bi.get_node("HBoxContainer/ButtonSub").connect("pressed",self,"_remove_card",[ID])
		bi.set_visible(visible)
		pos += int(visible)
	for ID in Data.deck.keys():
		get_node("Deck/Deck/"+Data.data[ID]["faction"].capitalize()).show()
	
	get_node("Deck/Cards/Control").set_custom_minimum_size(Vector2(cols*175,ceil(pos/cols+1)*250))
	get_node("Deck/Deck/Label").set_text(tr("DECK")+": "+str(num_cards)+" / "+str(Data.MAX_CARDS)+" "+tr("CARDS"))
	get_node("Deck/Deck/Label").show()

func show_deck():
	update_cards()
	get_node("Deck").show()
	get_node("Deck/HBoxContainer/ButtonSave").show()
	get_node("Deck/HBoxContainer/ButtonLoad").show()
	get_node("Panel").hide()

func show_main():
	get_node("Deck").hide()
	get_node("Panel").show()

func show_shop():
	get_node("Shop/VBoxContainer/Label").set_text(tr("CREDITS")+": "+str(credits))
	for i in range(3):
		get_node("Shop/VBoxContainer/ButtonTier"+str(i+1)).set_text(tr("BUY_TIER"+str(i+1)+"_CARDS")+" ("+str(COST[i])+")")
	get_node("Shop").show()

func show_settings():
	_set_music(100*db2linear(AudioServer.get_bus_volume_db(1)))
	_set_sound(100*db2linear(AudioServer.get_bus_volume_db(2)))
	get_node("Settings").show()

func hide_shop():
	get_node("Shop").hide()

func hide_deck():
	_save()
	show_main()

func hide_settings():
	get_node("Settings").hide()

func accept_settings():
	apply_settings()
	hide_settings()
	save_config()

func settings_show_player():
	get_node("Settings/Player").show()
	get_node("Settings/Resolution").hide()
	get_node("Settings/Audio").hide()

func settings_show_resolution():
	get_node("Settings/Player").hide()
	get_node("Settings/Resolution").show()
	get_node("Settings/Audio").hide()

func settings_show_audio():
	get_node("Settings/Player").hide()
	get_node("Settings/Resolution").hide()
	get_node("Settings/Audio").show()

func show_quit():
	get_node("Quit").popup_centered(Vector2(0,0))

func quit():
	_save()
	save_config()
	get_tree().quit()

func create_save_dir():
	var dir = Directory.new()
	if (!dir.dir_exists("user://decks")):
		dir.make_dir_recursive("user://decks")

func _load():
	var file = File.new()
	
	if (!file.file_exists("user://cards.save")):
		print("No save file found!")
		return 
	var error = file.open("user://cards.save",File.READ)
	
	if (error!=OK):
		print("Can't open save file!")
		return
	
	while (!file.eof_reached()):
		var currentline = JSON.parse(file.get_line()).get_result()
		if (currentline==null):
			continue
		if (currentline.has("deck")):
			Data.deck = currentline["deck"]
		elif (currentline.has("inventory")):
			Data.inventory = currentline["inventory"]
			credits = currentline["credits"]

func _save():
	var dir = Directory.new()
	if (!dir.dir_exists("user://")):
		dir.make_dir_recursive("user://")
	
	var file = File.new()
	var error = file.open("user://cards.save",File.WRITE)
	if (error!=OK):
		print("Can't write save file!")
		return
	
	file.store_line(JSON.print({"deck":Data.deck}))
	file.store_line(JSON.print({"inventory":Data.inventory,"credits":credits}))
	
	file.close()

func _default():
	resolution = OS.get_screen_size()
	fullscreen = false
	maximized = true
	music = 100
	sound = 100
	
	apply_settings()
	save_config()
	show_settings()
	settings_show_player()

func load_config():
	var file = File.new()
	if (!file.file_exists("user://settings.cfg")):
		print("No config file found!")
		_default()
		return
	
	var error = file.open("user://settings.cfg",File.READ)
	
	if (error==OK):
		while (!file.eof_reached()):
			var currentline = JSON.parse(file.get_line()).get_result()
			if (currentline==null):
				continue
			if currentline.has("resolution_x"):
				resolution = Vector2(currentline["resolution_x"],currentline["resolution_y"])
			elif currentline.has("fullscreen"):
				fullscreen = currentline["fullscreen"]
				maximized = currentline["maximized"]
			elif currentline.has("music"):
				music = currentline["music"]
				sound = currentline["sound"]
			elif (currentline.has("name")):
				player_name = currentline["name"]
				name_new = player_name
	
	file.close()
	apply_settings()

func save_config():
	create_save_dir()
	
	var file = File.new()
	var error = file.open("user://settings.cfg",File.WRITE)
	
	resolution = OS.get_window_size()
	fullscreen = OS.is_window_fullscreen()
	maximized = OS.is_window_maximized()
	music = 100*db2linear(AudioServer.get_bus_volume_db(1))
	sound = 100*db2linear(AudioServer.get_bus_volume_db(2))
	
	file.store_line(JSON.print({"resolution_x":resolution.x,"resolution_y":resolution.y}))
	file.store_line(JSON.print({"fullscreen":fullscreen,"maximized":maximized}))
	file.store_line(JSON.print({"music":music,"sound":sound}))
	file.store_line(JSON.print({"name":player_name}))
	
	file.close()

func apply_settings():
	OS.set_window_size(resolution)
	OS.set_window_fullscreen(fullscreen)
	OS.set_window_maximized(maximized)
	AudioServer.set_bus_volume_db(1,linear2db(music/100.0))
	AudioServer.set_bus_volume_db(2,linear2db(sound/100.0))
	player_name = name_new
	
	get_node("Settings/Player/Name/LineEdit").set_text(player_name)

func _input(event):
	if (event.is_action_pressed("cancel")):
		if (!get_node("Panel").is_visible()):
			show_main()
		elif (!get_node("Quit").is_visible()):
			show_quit()
		else:
			quit()

func _ready():
	randomize()
	set_process_input(true)
	load_config()
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
			Data.deck = Data.DECK_DEFAULT[deck_file].duplicate()
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

func buy_tier1():
	if (credits<COST[0]):
		return
	
	for c in get_node("Cards/ScrollContainer/Control").get_children():
		c.queue_free()
	yield(get_tree(),"idle_frame")
	credits -= COST[0]
	for i in range(3):
		var card = Data.get_tier1_card()
		if (Data.inventory.has(card)):
			Data.inventory[card] += 1
		else:
			Data.inventory[card] = 1
		show_card(card)
	get_node("Cards").show()
	hide_shop()

func buy_tier2():
	if (credits<COST[1]):
		return
	
	for c in get_node("Cards/ScrollContainer/Control").get_children():
		c.queue_free()
	yield(get_tree(),"idle_frame")
	credits -= COST[1]
	for i in range(3):
		var card = Data.get_tier2_card()
		if (Data.inventory.has(card)):
			Data.inventory[card] += 1
		else:
			Data.inventory[card] = 1
		show_card(card)
	get_node("Cards").show()
	hide_shop()

func buy_tier3():
	if (credits<COST[2]):
		return
	
	for c in get_node("Cards/ScrollContainer/Control").get_children():
		c.queue_free()
	yield(get_tree(),"idle_frame")
	credits -= COST[2]
	for i in range(3):
		var card = Data.get_tier3_card()
		if (Data.inventory.has(card)):
			Data.inventory[card] += 1
		else:
			Data.inventory[card] = 1
		show_card(card)
	get_node("Cards").show()
	hide_shop()

func show_card(card):
	var ci = Cards.create_card(card)
	var bi = get_node("Cards/Card").duplicate()
	bi.connect("gui_input",bi,"_input_event")
	ci.set_position(Vector2(175,250))
	bi.add_child(ci)
	bi.set_position(Vector2(350*get_node("Cards/ScrollContainer/Control").get_child_count(),0))
	get_node("Cards/ScrollContainer/Control").add_child(bi)
	bi.show()
	get_node("Cards/ScrollContainer/Control").set_custom_minimum_size(Vector2(350*get_node("Cards/ScrollContainer/Control").get_child_count(),250))

func hide_cards():
	get_node("Cards").hide()

func _toggle_filter(pressed,faction):
	filter[faction] = pressed
	update_cards()

func _show_lobby():
	get_node("Lobby").show()

func _set_player_name(text):
	name_new = text

func _set_music(value):
	music = value
	get_node("Settings/Audio/Music/SpinBox").set_value(value)
	get_node("Settings/Audio/Music/HSlider").set_value(value)

func _set_sound(value):
	sound = value
	get_node("Settings/Audio/Sound/SpinBox").set_value(value)
	get_node("Settings/Audio/Sound/HSlider").set_value(value)
