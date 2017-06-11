extends Control



func _draw():
	var num_points = 100
	for i in range(Campaign.POS.size()):
		var points = []
		points.resize(num_points)
		for j in range(num_points):
			var min_dist = 50.0
			var max_dist = min_dist
			var dir = Vector2(0,1).rotated(1.0*j/num_points*2.0*PI)
			for s in Campaign.stars:
				if (s.owner==i+1):
					var d = Campaign.POS[i].distance_to(s.position)
					var dist = (s.position-Campaign.POS[i]).dot(dir)/d
					dist *= (d+50)*dist*dist
					if (dist>max_dist):
						max_dist = dist
						points[j] = get_parent().get_size()/2+Campaign.POS[i]+dist*dir
			if (max_dist<=min_dist):
				points[j] = get_parent().get_size()/2+Campaign.POS[i]+min_dist*dir
		for j in range(num_points-1):
			draw_line(points[j],points[j+1],Campaign.FACTION_COLOUR[i+1],4.0)
		draw_line(points[num_points-1],points[0],Campaign.FACTION_COLOUR[i+1],4.0)
#		print(points)
