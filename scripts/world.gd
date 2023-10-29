extends Node2D

var bird_model = preload("res://scenes/bird.tscn")
var max_birds = 10
var bird_died = 0
var generation = 1
var c1 = 1.0
var c2 = 2.0
var c3 = 0.5
var genomes = []
var genomes_score = []
var innovation = {}
var i_num = 1


func _ready():
	innovation["1#5"] = i_num
	i_num += 1
	innovation["2#5"] = i_num
	i_num += 1
	innovation["3#5"] = i_num
	i_num += 1
	innovation["4#5"] = i_num
	i_num += 1
	for i in range(max_birds):
		genomes.append({
			"nodes":[1,2,3,4,5],
			"connections":[[[1,5],true,0],[[2,5],true,0],[[3,5],true,0],[[4,5],true,0]]
		})
		genomes_score.append(0)
	create_generation()
	pass 

func create_generation():
	$Label.text = str(generation)
	bird_died = 0
	for i in range(genomes.size()):
		var new_bird = bird_model.instantiate()
		new_bird.global_position = Vector2(147,300)
		new_bird.index = i
		new_bird.genome = genomes[i]
		new_bird.name = "bird" + str(i)
		add_child(new_bird)
	$poles.start = true
	pass


func _process(delta):
	
	if(bird_died == max_birds):
		var differences = []
		for i in range(1,genomes.size()):
			differences.append(find_distance(genomes[0],genomes[1]))
		differences.sort()
		
		
	
func get_hash(connection):
	return str(connection[0]) + "#" + str(connection[1])

func find_distance(genome1,genome2):
	var n1 = 0 
	var max1 = null
	var n2 = 0
	var max2 = null
	for connection in genome1["connections"]:
		if(connection[1] == true):
			if(max1 == null):
				max1 = innovation[get_hash(connection[0])]
			max1 = max(max1,innovation[get_hash(connection[0])])
			n1 += 1
	for connection in genome2["connections"]:
		if(connection[1] == true):
			if(max2 == null):
				max2 = innovation[get_hash(connection[0])]
			max2 = max(max1,innovation[get_hash(connection[0])])
			n2 += 1
	var n = max(n1,n2)
	var excess = 0
	var disjoint = 0
	var weights = 0
	var common_connections = 0
	if(n == n1):
		for connection in genome1["connections"]:
			var curr_i_num = innovation[get_hash(connection[0])]
			if(curr_i_num > n2):
				excess += 1
	else:
		for connection in genome2["connections"]:
			var curr_i_num = innovation[get_hash(connection[0])]
			if(curr_i_num > n1):
				excess += 1	
	for connection in genome1["connections"]:
		var found = false
		for connection2 in genome2["connections"]:
			if(connection == connection2):
				found = true
				weights += abs(connection[0][0] - connection[0][1])
				common_connections += 1
				break
		if(found == false):
			disjoint += 1
	for connection in genome1["connections"]:
		var found = false
		for connection2 in genome2["connections"]:
			found = true
			break
		if(found == false):
			disjoint += 1
	
	return ((float(excess) * c1)/float(n)) + ((float(disjoint) * c2)/float(n)) + ((float(weights) * c3)/(float(common_connections)))
	
	
