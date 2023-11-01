extends Node2D

var bird_model = preload("res://scenes/bird.tscn")
var max_birds = 15
var bird_died = 0
var generation = 1
var c1 = 1.0
var c2 = 2.0
var c3 = 0.5
var genomes = []
var genomes_score = []
var innovation = {}
var i_num = 1
var rand = RandomNumberGenerator.new()

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
			"connections":[[[1,5],true,0.0],[[2,5],true,0.0],[[3,5],true,0.0],[[4,5],true,0.0]]
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
		bird_died = 0
#		var differences = []
#		for i in range(1,genomes.size()):
#			differences.append(find_distance(genomes[0],genomes[1]))
#		differences.sort()
#		print(differences)
		var new_genomes = []
		var new_genomes_score = []
		for i in range(5):
			var total_score = 0
			for index in range(genomes_score.size()):
				total_score += (genomes_score[index]+1)
			var r = rand.randi_range(0,total_score-1)
			var index = 0
			print(r)
			while(r >= genomes_score[index]):
				r -= (genomes_score[index]+1)
				index += 1
			new_genomes.append(genomes[index])
			new_genomes_score.append(genomes_score[index])
			genomes.remove_at(index)
			genomes_score.remove_at(index)
			

		var count_parent_genome = new_genomes.size()
		for i in range(count_parent_genome):
			for j in range(count_parent_genome):
				if((i != j) and (i<j)):
					var new_child
					if(new_genomes_score[i] > new_genomes_score[j]):
						new_child = crossover(new_genomes[i],new_genomes[j])
					else:
						new_child = crossover(new_genomes[j],new_genomes[i])	
					new_genomes.append(new_child)
		genomes = new_genomes
		for i in range(genomes_score.size()):
			genomes_score[i] = 0
		while(genomes_score.size() < genomes.size()):
			genomes_score.append(0)
		
		print("creating new generations")
		print(genomes.size())
		print(genomes_score.size())
		print(genomes)
		create_generation()
		
func crossover(genome1,genome2):
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
	var new_genome = {
		"nodes":[],
		"connections":[]
	}		
	
	new_genome["nodes"] = genome1["nodes"]
	for node in genome2["nodes"]:
		if !(new_genome["nodes"].has(node)):
			new_genome["nodes"].append(node)
	
	for connection1 in genome1["connections"]:
		var found = false
		for connection2 in genome2["connections"]:
			if(connection1[0] == connection2[0]):
				found = true
				var bet = rand.randi_range(0,1)
				if(bet == 1):
					new_genome["connections"].append(connection1)
				else:
					new_genome["connections"].append(connection2)
		if(found == false):
			new_genome["connections"].append(connection1)
	for connection in new_genome["connections"]:
		if(connection[1] == false):
			if(rand.randi_range(0,3) == 3):
				connection[2] = true
	
	var bet = rand.randi_range(0,9)
	if(bet <= 7):
		mutate(new_genome)
	
	return new_genome	
		
func mutate(genome):
	var bet = rand.randi_range(0,9)
	if(bet <= 7):
		mutate_weights(genome)
	else:
		mutate_configuration(genome)
	pass
	
func mutate_weights(genome):
	for connection in genome["connections"]:
		var bet = rand.randi_range(0,9)
		if(bet <= 6):
			if(rand.randi_range(0,1) == 0):
				connection[2] = float(connection[2]) + (float(connection[2]) * 0.2)
			else:
				connection[2] = float(connection[2]) - (float(connection[2]) * 0.2)
		else:
			connection[2] = randf_range(-2.0,2.0)

func mutate_configuration(genome):
	var bet = rand.randi_range(0,11)
	if bet <= 2:
		add_connection(genome)
	elif bet <= 5:
		remove_connection(genome)
	elif bet < 8:
		add_node(genome)
	elif bet <= 11:
		remove_node(genome)
	pass
		
func add_connection(genome):
	var layer_data = {}
	var layers = []
	var indegree = {}
	var adj_matrix = {}
	
	for connection in genome["connections"]:
		if(connection[1]):
			var from = connection[0][0]
			var to = connection[0][1]
			if(!indegree.has(from)):
				indegree[from] = 0
			if(indegree.has(to)):
				indegree[to] += 1
			else:
				indegree[to] = 1
			# creatind an adjacent list
			if(adj_matrix.has(from)):
				adj_matrix[from].append(to)
			else:
				adj_matrix[from] = [to]
	var queue = []
	for node in indegree:
		if(indegree[node] == 0):
			queue.append(node)
			layer_data[node] = 0
			layers.append([])
			layers[0].append(node)
	
	
	#arranging in layers
	for i in range(queue.size()):
		for node in adj_matrix[queue[i]]:
			indegree[node] -= 1
			indegree[node] = max(0,indegree[node])
			layer_data[node] = layer_data[queue[i]]+1
			if(layer_data.size() <= layer_data[node]):
				layers.append([])
			layers[layer_data[node]].append(node)
		
	#trying 20 times to create new connection
	var done = false
	for i in range(20):
		var layers_to_chose = []
		for index in range(layers.size()):
			layers_to_chose.append(index)
		
		var bet = rand.randi_range(0,layers_to_chose.size()-1)
		var start_layer = layers_to_chose[bet]
		bet = rand.randi_range(0,layers_to_chose.size()-1)
		var end_layer = layers_to_chose[bet]
		var start_node = layers[start_layer][rand.randi_range(0,layers[start_layer].size()-1)]
		var end_node = layers[end_layer][rand.randi_range(0,layers[end_layer].size()-1)]
		var found = false
		for connection in genome["connections"]:
			if((connection[0][0] == start_node) and (connection[0][1] == end_node)):
				if(connection[1] == false):
					connection[1] = true
					done = true
				break
		if(found == false):
			done = true
			var hash = get_hash([start_node,end_node])
			if(!innovation.has(hash)):
				innovation[hash] = i_num
				i_num += 1
			genome["connections"].append([[start_node,end_node],true,0])
			
			
		if(done == true):
			break
	return genome
	
	
	
func remove_connection(genome):
	var active_connections = []
	for i in range(genome["connections"].size()):
		if(genome["connections"][i][1]):
			active_connections.append(i)
			
	var bet = rand.randi_range(0,active_connections.size()-1)
	genome["connections"][active_connections[bet]][1] = false
	
	return genome
	
func add_node(genome):
	var node_array = genome["nodes"]
	node_array.sort()
	var mex = 1
	for node in node_array:
		if(mex == node):
			mex += 1
		else:
			break
			
	var active_connections = []
	for i in range(genome["connections"].size()):
		if(genome["connections"][i][1]):
			active_connections.append(i)
	
	var bet = rand.randi_range(0,active_connections.size()-1)
	genome["connections"][active_connections[bet]][1] = false
	var from = genome["connections"][active_connections[bet]][0][0]
	var to = genome["connections"][active_connections[bet]][0][1]
	var weight = genome["connections"][active_connections[bet]][2]
	genome["connections"].append([[from,mex],true,1])
	genome["connections"].append([[mex,to],true,weight])
	
	return genome
	
func remove_node(genome):
	if(genome["nodes"].size() == 5):
		return
	var bet = rand.randi_range(5,genome["nodes"].size()-1)
	var deleting_node = genome["node"][bet]
	for connection in genome["connections"]:
		if((genome["connnections"][0][1] == deleting_node) or (genome["connnections"][0][2] == deleting_node)):
			genome["connections"][1] = false
	
	return genome

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
				weights += abs(connection[2] - connection2[2])
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
	print(excess," ",disjoint," ",weights)
	return ((float(excess) * c1)/float(n)) + ((float(disjoint) * c2)/float(n)) + ((float(weights) * c3)/(float(common_connections)))
	

	
