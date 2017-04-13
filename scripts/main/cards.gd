
extends Node

const header_color = [Color(0.5,0.5,0.5),Color(0.1,0.5,0.25),Color(0.1,0.25,0.5),Color(0.5,0.5,0.0)]
const type_color = {"unit":Color(0.45,0.4,0.1),"effect":Color(0.2,0.5,0.1),"planet":Color(0.1,0.2,0.5)}

var base = preload("res://scenes/cards/card_base.tscn")

func create_card(ID):
	var bi = base.instance()
	var ii = load("res://scenes/cards/"+Data.data[ID]["file"]+".tscn")
	if (ii!=null):
		ii = ii.instance()
		bi.get_node("Image").add_child(ii)
	bi.set_name("Card")
	bi.get_node("Header").set_modulate(type_color[Data.data[ID]["type"]])
	bi.get_node("Colored").set_modulate(header_color[Data.data[ID]["grade"]])
	bi.get_node("Name").set_text(tr(Data.data[ID]["name"]))
	update_values(bi,Data.data[ID]["level"],Data.calc_value(ID,"structure"),Data.calc_value(ID,"dmg"),Data.calc_value(ID,"shield"),Data.calc_value(ID,"production"))
	
	var effects = Data.data[ID]["effects"]
	var targets = Data.data[ID]["targets"]
	var events = Data.data[ID]["events"]
	if (effects.size()>0):
		var text = ""
		for i in range(effects.size()):
			text += tr(effects[i]+"-"+targets[i]+"-"+events[i])+"\n"
		bi.get_node("Desc").set_text(text)
	else:
		bi.get_node("Desc").set_text("")
	
	return bi

func update_values(node,level,structure,damage,shield,production=0):
	node.get_node("VBoxContainer/Level/Number").set_text(str(level))
	node.get_node("VBoxContainer/Structure/Number").set_text(str(structure))
	if (structure<=0):
		node.get_node("VBoxContainer/Structure/Number").add_color_override("font_color",Color(1.0,0.1,0.1))
	else:
		node.get_node("VBoxContainer/Structure/Number").add_color_override("font_color",Color(0.0,0.0,0.0))
	if (structure!=0):
		node.get_node("VBoxContainer/Structure").show()
	if (damage!=0):
		node.get_node("VBoxContainer/Damage/Number").set_text(str(damage))
		node.get_node("VBoxContainer/Damage").show()
		if (damage<0):
			node.get_node("VBoxContainer/Damage/Number").add_color_override("font_color",Color(1.0,0.1,0.1))
		else:
			node.get_node("VBoxContainer/Damage/Number").add_color_override("font_color",Color(0.0,0.0,0.0))
	if (shield!=0):
		node.get_node("VBoxContainer/Shield/Number").set_text(str(shield))
		node.get_node("VBoxContainer/Shield").show()
		if (shield<0):
			node.get_node("VBoxContainer/Shield/Number").add_color_override("font_color",Color(1.0,0.1,0.1))
		else:
			node.get_node("VBoxContainer/Shield/Number").add_color_override("font_color",Color(0.0,0.0,0.0))
	if (production!=0):
		node.get_node("VBoxContainer/Production/Number").set_text(str(production))
		node.get_node("VBoxContainer/Production").show()
		if (production<0):
			node.get_node("VBoxContainer/Production/Number").add_color_override("font_color",Color(1.0,0.1,0.1))
		else:
			node.get_node("VBoxContainer/Production/Number").add_color_override("font_color",Color(0.0,0.0,0.0))
