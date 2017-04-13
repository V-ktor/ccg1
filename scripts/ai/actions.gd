var actions = []

func reset():
	actions.clear()

func add_action(score,function,arg):
	actions.push_back({"score":score,"function":function,"arguments":arg})

func get_best_action():
	var score = 0
	var best
	for action in actions:
		if (action["score"]>score):
			score = action["score"]
			best = action
	
	return best
