extends CanvasLayer

const DEFAULT_PORT = 8910 # some random number, pick your port properly

var status_text = ""
var waiting = false
var dots = 0
var player_name = {}
var player_deck = {}
var player_self = 0


func show():
	get_node("Panel").show()
	get_node("Panel/VBoxContainer/HBoxContainer/ButtonJoin").set_disabled(false)
	get_node("Panel/VBoxContainer/HBoxContainer/ButtonHost").set_disabled(false)
	get_tree().set_refuse_new_network_connections(false)
	player_name.clear()
	player_deck.clear()
	player_self = 0

func hide():
	get_node("Panel").hide()
	get_tree().set_refuse_new_network_connections(true)
	player_self = 0


# network callbacks #

func _player_disconnected(id):
	# someone disconnected, stop the game
	if (has_node("/root/Main")):
		get_node("/root/Main").queue_free()
		get_node("../BattleEnd").set_title(tr("DISCONNECTED"))
		get_node("../BattleEnd/Text").set_text("PLAYER_DISCONNECTED")
		get_parent().show_main()
		get_node("../BattleEnd").popup()
	else:
		show()
		set_status("PLAYER_DISCONNECTED",true,false)

func _server_disconnected():
	# server disconnected, stop the game
	if (has_node("/root/Main")):
		get_node("/root/Main").queue_free()
		get_node("../BattleEnd").set_title(tr("DISCONNECTED"))
		get_node("../BattleEnd/Text").set_text("SERVER_DISCONNECTED")
		get_parent().show_main()
		get_node("../BattleEnd").popup()
	else:
		show()
		set_status("SERVER_DISCONNECTED",true,false)

func _connected_ok():
	# Only called on clients, not server. Send my ID and info to all the other peers
	player_name[get_tree().get_network_unique_id()] = get_parent().player_name
	player_deck[get_tree().get_network_unique_id()] = Data.deck
	rpc("register_player",get_tree().get_network_unique_id(),get_parent().player_name,get_parent().get_deck(Data.deck))

func _connected_fail():
	_cancel()


remote func register_player(ID,nm,deck):
	player_name[ID] = nm
	player_deck[ID] = deck
	rpc_id(ID,"register_player",1,get_parent().player_name,get_parent().get_deck(Data.deck)) # Send myself to other dude
	
	if (player_name.size()>1):
		var planets
		if (player_self==0):
			planets = get_parent().randomize_planets(3)
			rpc("start",planets,3)

remote func start(planets,positions):
	var other = player_name.keys()[0]
	if (other==1):
		other = player_name.keys()[1]
	get_parent().add_credits = 250
	get_parent().start_game(planets,planets.size(),positions,player_deck[1],player_deck[other],player_name[1],player_name[other],false,false,1,other)
	hide()


# game creation #

func _host():
	var host = NetworkedMultiplayerENet.new()
	host.set_compression_mode(NetworkedMultiplayerENet.COMPRESS_RANGE_CODER)
	var err = host.create_server(DEFAULT_PORT,1) # max: 1 peer, since it's a 2 players game
	if (err!=OK):
		# is another server running?
		set_status("ADRESS_IN_USE",true,false)
		return
	
	player_self = 0
	get_tree().set_network_peer(host)
	get_tree().set_meta("network_peer",host)
	get_node("Panel/VBoxContainer/HBoxContainer/ButtonJoin").set_disabled(true)
	get_node("Panel/VBoxContainer/HBoxContainer/ButtonHost").set_disabled(true)
	get_node("Panel/VBoxContainer/ButtonCancel").show()
	set_status("WAITING_FOR_PLAYER",false,true)

func _join():
	var ip = get_node("Panel/VBoxContainer/Adress").get_text()
	if (!ip.is_valid_ip_address()):
		set_status("IP_INVALID",true,false)
		return
	
	var host = NetworkedMultiplayerENet.new()
	player_self = 1
	host.set_compression_mode(NetworkedMultiplayerENet.COMPRESS_RANGE_CODER)
	host.create_client(ip,DEFAULT_PORT)
	get_tree().set_network_peer(host)
	get_tree().set_meta("network_peer",host)
	get_node("Panel/VBoxContainer/HBoxContainer/ButtonJoin").set_disabled(true)
	get_node("Panel/VBoxContainer/HBoxContainer/ButtonHost").set_disabled(true)
	get_node("Panel/VBoxContainer/ButtonCancel").show()
	set_status("CONNECTING",false,true)

func _cancel():
	get_tree().set_network_peer(null) # remove peer
	get_tree().set_meta("network_peer",null)
	get_node("Panel/VBoxContainer/HBoxContainer/ButtonJoin").set_disabled(false)
	get_node("Panel/VBoxContainer/HBoxContainer/ButtonHost").set_disabled(false)
	get_node("Panel/VBoxContainer/ButtonCancel").hide()
	set_status("",false,false)


# display #

func set_status(text,error,wt):
	status_text = tr(text)
	waiting = wt
	dots = 0
	get_node("Panel/VBoxContainer/Status").set_text(status_text)
	if (error):
		get_node("Panel/VBoxContainer/Status").add_color_override("font_color",Color(1.0,0.1,0.1))
	else:
		get_node("Panel/VBoxContainer/Status").add_color_override("font_color",Color(0.1,1.0,0.1))

func _ready():
	var timer = Timer.new()
	timer.set_wait_time(0.5)
	add_child(timer)
	timer.connect("timeout",self,"_display_status")
	timer.start()
	
	# connect the callbacks related to networking
	get_tree().connect("network_peer_disconnected",self,"_player_disconnected")
	get_tree().connect("connected_to_server",self,"_connected_ok")
	get_tree().connect("connection_failed",self,"_connected_fail")
	get_tree().connect("server_disconnected",self,"_server_disconnected")
	
	rpc_config("start",RPC_MODE_SYNC)

func _display_status():
	var text = ""+status_text
	if (waiting):
		for i in range(dots):
			text += "."
	get_node("Panel/VBoxContainer/Status").set_text(text)
	dots = (dots+1)%4
