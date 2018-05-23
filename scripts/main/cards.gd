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
	update_values(bi,card["level"],Data.calc_value(ID,"structure"),Data.calc_value(ID,"damage"),Data.calc_value(ID,"shield"),Data.calc_value(ID,"cards"))
	
	for i in range(card["effects"].size()):
		var effect = card["effects"][i]
		if (!effect.has("icon")):
			continue
		
		var pi = bi.get_node("Description/Effect").duplicate()
		var texture = load("res://images/effects/"+effect["icon"]+".png")
		if (texture!=null):
			var ti = bi.get_node("Effects/Effect").duplicate()
			ti.set_texture(texture)
			ti.set_name("Effect"+str(i))
			ti.show()
			bi.get_node("Effects").add_child(ti)
		else:
			print("Icon "+effect["icon"]+" not found!")
		pi.set_name("Effect"+str(i))
		pi.get_node("Name").set_text(tr(effect["name"]))
		pi.get_node("Desc").set_text(tr(effect["rule"]))
		pi.show()
		bi.get_node("Description/ScrollContainer/VBoxContainer").add_child(pi)
		bi.get_node("Effects/Attack").set_texture(load("res://images/effects/attack"+str(card["attack_points"])+".png"))
		bi.get_node("Effects/Movement").set_texture(load("res://images/effects/movement"+str(card["movement_points"])+".png"))
	
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
