extends CanvasLayer

const SAVE = 0
const LOAD = 1

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

var main_scene = preload("res://scenes/main/main.tscn")


func end_match(win):
	_save()
	show_main()
	if (win):
		get_node("BattleEnd").set_title(tr("WON!"))
	else:
		get_node("BattleEnd").set_title(tr("LOST!"))
	get_node("BattleEnd").popup()

func start():
	_save()
	randomize()
	var mi = main_scene.instance()
	
	mi.SIZE = 4				# number of planets
	mi.POSITIONS = 3		# number of fields per planet
	
	mi.deck[0] = []+Data.deck
	mi.randomize_deck(mi.PLAYER2,Data.MAX_CARDS)
	
	get_tree().get_root().add_child(mi)
	get_node("Panel").hide()

func add_card():
	if (card_selected!=null && Data.deck.size()<Data.MAX_CARDS):
		Data.deck.push_back(Data.inventory[card_selected])
		Data.inventory.remove(card_selected)
		update_cards()
		card_selected = null

func remove_card():
	if (deck_selected!=null):
		Data.inventory.push_back(Data.deck[deck_selected])
		Data.deck.remove(deck_selected)
		update_cards()
		deck_selected = null

func select_deck(ID):
	unselect()
	card_selected = null
	deck_selected = ID
	
	for c in get_node("Deck/Card").get_children():
		c.queue_free()
	
	var ci = Cards.create_card(Data.deck[ID])
	ci.set_scale(Vector2(0.75,0.75))
	ci.set_pos(Vector2(152,214))
	get_node("Deck/Card").add_child(ci)

func select_card(ID):
	unselect()
	card_selected = ID
	deck_selected = null
	
	for c in get_node("Deck/Card").get_children():
		c.queue_free()
	
	var ci = Cards.create_card(Data.inventory[ID])
	ci.set_scale(Vector2(0.75,0.75))
	ci.set_pos(Vector2(152,214))
	get_node("Deck/Card").add_child(ci)

func unselect():
	if (card_selected!=null and get_node("Deck/Cards/GridContainer/Card"+str(card_selected))):
		get_node("Deck/Cards/GridContainer/Card"+str(card_selected)).set_pressed(false)
	if (deck_selected!=null and get_node("Deck/Deck/GridContainer/Card"+str(deck_selected))):
		get_node("Deck/Deck/GridContainer/Card"+str(deck_selected)).set_pressed(false)

func update_cards():
	for c in get_node("Deck/Cards/GridContainer").get_children()+get_node("Deck/Deck/GridContainer").get_children():
		c.set_name("deleted")
		c.queue_free()
	
	for i in range(Data.deck.size()):
		var bi = Button.new()
		bi.connect("pressed",self,"select_deck",[i])
		bi.set_name("Card"+str(i))
		bi.set_text(tr(Data.data[Data.deck[i]]["name"]))
		bi.set_h_size_flags(Control.SIZE_EXPAND_FILL)
		bi.set_toggle_mode(true)
		bi.set_custom_minimum_size(Vector2(0,32))
		get_node("Deck/Deck/GridContainer").add_child(bi)
	
	for i in range(Data.inventory.size()):
		var bi = Button.new()
		bi.connect("pressed",self,"select_card",[i])
		bi.set_name("Card"+str(i))
		bi.set_text(tr(Data.data[Data.inventory[i]]["name"]))
		bi.set_h_size_flags(Control.SIZE_EXPAND_FILL)
		bi.set_toggle_mode(true)
		bi.set_custom_minimum_size(Vector2(0,32))
		get_node("Deck/Cards/GridContainer").add_child(bi)
	
	get_node("Deck/Text1").set_text(tr("DECK")+": "+str(Data.deck.size())+" / "+str(Data.MAX_CARDS)+" "+tr("CARDS"))
	get_node("Deck/Text2").set_text(tr("INVENTORY")+": "+str(Data.inventory.size())+" "+tr("CARDS"))

func show_deck():
	get_node("Deck").show()
	get_node("Panel").hide()

func show_main():
	get_node("Deck").hide()
	get_node("Panel").show()

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
	return
	var file = File.new()
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

func _save():
	return
	var file = File.new()
	var error = file.open_encrypted_with_pass("user://cards.save",File.WRITE,OS.get_unique_ID())
	
	file.store_line({"deck":Data.deck}.to_json())
	file.close()

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

func _ready():
	randomize()
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
