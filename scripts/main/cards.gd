extends Node

const HEADER_COLOR = [Color(0.5,0.5,0.5),Color(0.1,0.5,0.25),Color(0.1,0.25,0.5),Color(0.5,0.5,0.0)]
const TYPE_COLOR = {"unit":Color(0.45,0.4,0.1),"effect":Color(0.2,0.5,0.1),"planet":Color(0.1,0.2,0.5)}
const FACTION_COLOR = {"empire":Color(0.8,0.6,0.1),"rebels":Color(0.2,1.0,0.1),"pirates":Color(0.8,0.05,0.0)}

var base = preload("res://scenes/main/card_base.tscn")
var icon_type = {
	"unit":preload("res://images/cards/logo_unit.png"),
	"effect":preload("res://images/cards/logo_effect.png"),
	"planet":preload("res://images/cards/logo_planet.png")
}
var logo = {
	"empire":preload("res://images/cards/logo_empire.png"),
	"rebels":preload("res://images/cards/logo_rebels.png"),
	"pirates":preload("res://images/cards/logo_pirates.png")
}
var icon_effect = {
	"increase dmg 2-friendly-":preload("res://images/cards/effects/attack_up_2.png"),
	"reduce dmg 1-self-attack":preload("res://images/cards/effects/attack_down_1.png"),
	"reduce dmg 2-enemy-":preload("res://images/cards/effects/attack_down_2.png"),
	"armor 2-friendly-":preload("res://images/cards/effects/armor_up_2.png"),
	"defense 6-friendly planet-":preload("res://images/cards/effects/armor_up_6.png"),
	"reduce structure 1-friendly-":preload("res://images/cards/effects/armor_down_1.png"),
	"shield 1-friendly-":preload("res://images/cards/effects/shield_up_1.png"),
	"shield 1-friendly planet-":preload("res://images/cards/effects/shield_up_1.png"),
	"jam 1-enemy-":preload("res://images/cards/effects/shield_down_1.png"),
	"repair 4-friendly-":preload("res://images/cards/effects/repair_4.png"),
	"repair 5-friendly-":preload("res://images/cards/effects/repair_5.png"),
	"repair 6-friendly-":preload("res://images/cards/effects/repair_6.png"),
	"drydock-friendly planet-player turn":preload("res://images/cards/effects/repair_2.png"),
	"drydock-self-player turn":preload("res://images/cards/effects/repair_2.png"),
	"cheap-self-spawn":preload("res://images/cards/effects/cheap.png"),
	"cheap-friendly planet-":preload("res://images/cards/effects/cheap.png"),
	"production 1-friendly planet-":preload("res://images/cards/effects/points_1.png"),
	"production 2-friendly planet-":preload("res://images/cards/effects/points_2.png"),
	"reduce cost 4-friendly-":preload("res://images/cards/effects/points_4.png"),
	"draw 2-player-spawn":preload("res://images/cards/effects/cards_2.png"),
	"draw 3-player-":preload("res://images/cards/effects/cards_3.png"),
	"remove 2-opposite-":preload("res://images/cards/effects/discard_2.png"),
	"direct damage 4-enemy-":preload("res://images/cards/effects/damage_4.png"),
	"direct damage 6-enemy-":preload("res://images/cards/effects/damage_6.png"),
	"bombardment 2-self-attack":preload("res://images/cards/effects/bombardment_2.png"),
	"mines 1-friendly planet-player turn":preload("res://images/cards/effects/mines.png"),
	"mines 2-friendly planet-player turn":preload("res://images/cards/effects/mines.png"),
	"counterattack-attacker-attacked":preload("res://images/cards/effects/counter.png"),
	"partisan-self-":preload("res://images/cards/effects/counter.png"),
	"penetrate shield-self-attack":preload("res://images/cards/effects/no_shield.png"),
	"capture-target-attack":null,
	"take over-enemy planet-":null,
	"revolt-enemy planet-":null,
	"spawn light_fighter-friendly planet-player turn":preload("res://images/cards/effects/spawn_fighter.png"),
	"points 2-player-attack":preload("res://images/cards/effects/points_2.png"),
	"unmoveable-self-":preload("res://images/cards/effects/movement0.png"),
	"no attack-self-":preload("res://images/cards/effects/attack0.png")
}
var icon_attack = [preload("res://images/cards/effects/attack0.png"),preload("res://images/cards/effects/attack1.png")]
var icon_movement = [preload("res://images/cards/effects/movement0.png"),preload("res://images/cards/effects/movement1.png")]


func create_card(ID):
	var card = Data.data[ID]
	var bi = base.instance()
	var ii = load("res://scenes/cards/"+card["file"]+".tscn")
	if (ii!=null):
		ii = ii.instance()
		bi.get_node("Image").add_child(ii)
	bi.set_name("Card")
	bi.get_node("Header").set_modulate(FACTION_COLOR[card["faction"]])
	bi.get_node("Colored").set_modulate(TYPE_COLOR[card["type"]])
	bi.get_node("Name").set_text(tr(card["name"].to_upper()))
	bi.get_node("Logo").set_texture(logo[card["faction"]])
	bi.get_node("Type").set_texture(icon_type[card["type"]])
	bi.ID = ID
	update_values(bi,card["level"],Data.calc_value(ID,"structure"),Data.calc_value(ID,"dmg"),Data.calc_value(ID,"shield"),Data.calc_value(ID,"production"))
	
	var effects = card["effects"]
	var targets = card["targets"]
	var events = card["events"]
	for i in range(effects.size()):
		var t = effects[i]+"-"+targets[i]+"-"+events[i]
		var pi = bi.get_node("Description/Effect").duplicate()
		if (icon_effect.has(t)):
			var ti = bi.get_node("Effects/Effect").duplicate()
			ti.set_texture(icon_effect[t])
			ti.set_name("Effect"+str(i))
			ti.show()
			bi.get_node("Effects").add_child(ti)
		else:
			print("No icon found for "+t+"!")
		pi.set_name("Effect"+str(i))
		pi.get_node("Name").set_text(tr(t.to_upper().replace(" ","_")))
		pi.get_node("Desc").set_text(tr(t.to_upper().replace(" ","_")+"_DESC"))
		pi.show()
		bi.get_node("Description/ScrollContainer/VBoxContainer").add_child(pi)
	if (card["type"]=="unit"):
		if ("no attack" in effects):
			bi.get_node("Effects/Attack").set_texture(icon_attack[0])
		if ("unmoveable" in effects):
			bi.get_node("Effects/Movement").set_texture(icon_movement[0])
	
	return bi

func update_values(node,level,structure,damage,shield,cards=0,points={}):
	node.get_node("VBoxContainer/Level/Number").set_text(str(level))
	node.get_node("VBoxContainer/Structure/Number").set_text(str(structure))
	if (structure<=0):
		node.get_node("VBoxContainer/Structure/Number").add_color_override("font_color",Color(1.0,0.1,0.1))
	else:
		node.get_node("VBoxContainer/Structure/Number").add_color_override("font_color",Color(0.0,0.0,0.0))
	if (structure!=0):
		node.get_node("VBoxContainer/Structure").show()
	node.get_node("VBoxContainer/Damage/Number").set_text(str(damage))
	if (damage!=0):
		node.get_node("VBoxContainer/Damage").show()
		if (damage<0):
			node.get_node("VBoxContainer/Damage/Number").add_color_override("font_color",Color(1.0,0.1,0.1))
		else:
			node.get_node("VBoxContainer/Damage/Number").add_color_override("font_color",Color(0.0,0.0,0.0))
	else:
		node.get_node("VBoxContainer/Damage").hide()
	node.get_node("VBoxContainer/Shield/Number").set_text(str(shield))
	if (shield!=0):
		node.get_node("VBoxContainer/Shield").show()
		if (shield<0):
			node.get_node("VBoxContainer/Shield/Number").add_color_override("font_color",Color(1.0,0.1,0.1))
		else:
			node.get_node("VBoxContainer/Shield/Number").add_color_override("font_color",Color(0.0,0.0,0.0))
	else:
		node.get_node("VBoxContainer/Shield").hide()
	node.get_node("VBoxContainer/Cards/Number").set_text(str(cards))
	if (cards!=0):
		node.get_node("VBoxContainer/Cards").show()
	else:
		node.get_node("VBoxContainer/Cards").hide()
	if (points!=null):
		for f in points.keys():
			node.get_node("VBoxContainer/Points"+f.capitalize()+"/Number").set_text(str(points[f]))
			node.get_node("VBoxContainer/Points"+f.capitalize()).show()
