extends Node2D

var bird_model = preload("res://scenes/bird.tscn")
var max_birds = 30
var bird_died = 0
var generation = 0
var threshold = 10
var target_species_count = 5
var c1 = 1.0
var c2 = 2.0
var c3 = 0.5
var genomes = []
var genomes_score = []
var innovation = {}
var cspecies = []
var i_num = 1
var new_privilage = 15
var rand = RandomNumberGenerator.new()
var id = 0
var orig_adj_mat = {
	1:[[6,0],[7,0]],
	2:[[6,0],[7,0]],
	3:[[6,0],[7,0]],
	4:[[6,0],[7,0]],
	6:[[5,0]],
	7:[[5,0]]
}

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
			"connections":[
				[[1,5],true,rand.randf_range(-3,3)],
				[[2,5],true,rand.randf_range(-3,3)],
				[[3,5],true,rand.randf_range(-3,3)],
				[[4,5],true,rand.randf_range(-3,3)]
			],
			"id":id
		})
		id += 1
#		genomes.append({ "nodes": [1, 2, 3, 4, 5, 6], "connections": [[[1, 5], true, 0], [[2, 5], true, -0.22505546281109], [[3, 5], true, -0.61630092680879], [[4, 5], true, 0.94433714567712]] })
#		genomes.append({ "nodes": [1, 2, 3, 4, 5, 6], "connections": [[[1, 5], true, 0], [[2, 5], true, -0.38889583973756], [[3, 5], true, -0.6306847079234], [[4, 5], true, 0.94433714567712]] })
		genomes_score.append(0)
	
	while(true):
		cspecies = initial_speciation(threshold)
		if(cspecies.size() < target_species_count):
			threshold -= 0.1
		else:
			break
	print(cspecies)
	print(cspecies.size())
	
	
	create_generation()
	pass 

func initial_speciation(threshold):
	var species = []
	var total_genomes = genomes.size()
	var added = []
	for genome in genomes:
		added.append(false)
	for i in range(total_genomes):
		if(added[i] == false):
			added[i] = true
			species.append([0,0,[i]])
			for j in range(i+1,total_genomes):
				if(added[j] == false):
					var dis = find_distance(genomes[i],genomes[j])
					if(dis <= threshold):
						added[j] = true
						(species.back())[2].append(j)

	return species
	pass


func create_generation():
#	print(genomes)
	print("birds spawned ",genomes.size())
	$poles.clear_poles()
	generation += 1
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
#	print(bird_died)
	if(bird_died == genomes.size()):
		bird_died = 0
		$birds_died.text = str(bird_died) 
		var new_genomes = []
		var new_genomes_score = []
		var maxi = 0
		for i in range(1,genomes_score.size()):
			if(genomes_score[i] > genomes_score[maxi]):
				maxi = i 
		print(maxi)	
		print("maximum_genome_num ",genomes[maxi]["id"])
		print("strongest genome ",genomes[maxi])
		print("maximum score ",genomes_score[maxi])
		$max_score_till_now.text = str(max(int($max_score_till_now.text),genomes_score[maxi]))
		
		
		#SPECIATING THE GENOMES ######################################
		print("Start speciating")

		print(genomes_score)
		#removing the species which not not improving
		for i in range(cspecies.size()-1,-1,-1):
			if(cspecies[i][0] > new_privilage):
				if(maxi not in cspecies[i][2]):
					cspecies.remove_at(i)
		
				
		#choosing representatives from each species		
		var genome_index_to_choose = []
		for species in cspecies:
			var bet = rand.randi_range(0,species[2].size()-1)
			if(species[2].size() > 1):
				for i in range(species[2].size()-1,-1,-1):
					if(bet != i):
						genome_index_to_choose.append(species[2][i])
						species[2].remove_at(i)
						
						
		# rearranging them into species 
		var change = 0.1
		var iteration = 100
		var new_cspecies = cspecies.duplicate(true)
		var indexes_to_choose = genome_index_to_choose.duplicate(true)
		new_cspecies = speciate(new_cspecies,indexes_to_choose,threshold)
		while(abs(new_cspecies.size() - target_species_count) > 0) and (iteration != 0):
			iteration -= 1
			if(new_cspecies.size() - target_species_count < 0):
				threshold -= change
			elif(new_cspecies.size() - target_species_count > 0):
				threshold += change
			new_cspecies = cspecies.duplicate(true)
			indexes_to_choose = genome_index_to_choose.duplicate(true)
			new_cspecies = speciate(new_cspecies,indexes_to_choose,threshold)
		print("threshold ",threshold)

		cspecies = new_cspecies
		
		#updating the details about the species and sorting all the members according to there score
		for species in cspecies:
			var max_score = species[1]
			for indexes in species[2]:
				max_score = max(max_score,genomes_score[indexes])
			if(max_score > species[1]):
				species[0] = 0
				species[1] = max_score
			else:
				species[0] += 1
			species[2].sort_custom(func(orgindex1,orgindex2): return genomes_score[orgindex1] > genomes_score[orgindex2] )
		
		#CREATING GENOMES FOR NEXT GENERATION ##########################
		# replacing fitness with adjusted fitness
		var total_FA = 0.0
		var count = 0
		for species in cspecies:
			for org_index in species[2]:
				count += 1
#				genomes_score[org_index] = float(genomes_score[org_index])/float(species[2].size())
				total_FA = total_FA + genomes_score[org_index]
		
		var global_AFA = float(total_FA)/float(count)
		
		#killing the weakest 80%(approximately) of the population
#		for species in cspecies:
#			var gets_to_live = ceil(species[2].size() * 0.2)
#			if(gets_to_live != species[2].size()):
#				for i in range(species[2].size()-1,gets_to_live-1,-1):
#					species[2].remove_at(i)

		#creating children
		new_cspecies = cspecies.duplicate(true)
		new_genomes.clear()
		new_genomes_score.clear()
		for species in new_cspecies:
			species[2].clear()
		for i in range(cspecies.size()):
			var species = cspecies[i]
			var species_fa = 0.0
			for org_index in species[2]:
				species_fa += genomes_score[org_index]
			var species_afa = float(species_fa)/float(species[2].size())
			var allowed_children = round((float(species_afa)/float(global_AFA))*float(species[2].size()))
			
			
			#killing the weakest 80%(approximately) of the population
			var gets_to_live = ceil(species[2].size() * 0.2)
			if(gets_to_live != species[2].size()):
				for index in range(species[2].size()-1,gets_to_live-1,-1):
					species[2].remove_at(index)
					
			print("allowed children from species ",i," ",allowed_children," ",max(0,allowed_children-species[2].size())," ",species[2].size())
					
			#creating the next generation of current species
			var new_children = create_children(species[2],max(0,allowed_children-species[2].size()))
			for org_index in species[2]:
				if(genomes[org_index]["id"] == genomes[maxi]["id"]):
					print("strongest ",genomes[maxi])
				new_cspecies[i][2].append(new_genomes.size())
				new_genomes.append(genomes[org_index])
				new_genomes_score.append(0)
			for genome in new_children:
				new_cspecies[i][2].append(new_genomes.size())
				new_genomes.append(genome)
				new_genomes_score.append(0)
				
		genomes = new_genomes
		genomes_score = new_genomes_score
		cspecies = new_cspecies
		print(cspecies)
		var no_array = []
		for gen in genomes:
			no_array.append(gen["id"])
		print(no_array)
		create_generation()


func create_children(indexes,count):
	var new_children = []
	
	var total_score = 0
	for index in indexes:
		total_score += (genomes_score[index]+1)
	for i in range(count):
		#choosing the first parent
		var r = rand.randi_range(0,total_score-1)
		var f_index = 0
		while(r >= genomes_score[f_index]+1):
			r -= (genomes_score[f_index]+1)
			f_index += 1
		#choosing the second parent
		r = rand.randi_range(0,total_score-1)
		var s_index = 0
		while(r >= genomes_score[s_index]+1):
			r -= (genomes_score[s_index]+1)
			s_index += 1
		if(genomes_score[f_index] >= genomes_score[s_index]):
			new_children.append(crossover(genomes[f_index],genomes[s_index]))
		else:
			new_children.append(crossover(genomes[s_index],genomes[f_index]))
	
	return new_children
	
func speciate(new_cspecies,genome_index_to_choose,threshold):
	for i in range(genome_index_to_choose.size()-1,-1,-1):
		var closest_species = -1
		var closest_species_distance = -1
		var index = genome_index_to_choose[i]
		for species_index in range(new_cspecies.size()):
			var representative_index = new_cspecies[species_index][2][0]
			var dis = find_distance(genomes[index],genomes[representative_index])
			if(dis <= threshold):
				if((closest_species == -1) || (closest_species_distance > dis)):
					closest_species = species_index
					closest_species_distance = dis
		if(closest_species != -1):
			new_cspecies[closest_species][2].append(index)
			genome_index_to_choose.remove_at(i)
	if(genome_index_to_choose.size() > 0):
		new_cspecies.append([0,0,[]])
		for genome_index in genome_index_to_choose:
			(new_cspecies.back())[2].append(genome_index)
			
	return new_cspecies
				
	
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
			max2 = max(max2,innovation[get_hash(connection[0])])
			n2 += 1
	var new_genome = {
		"nodes":[],
		"connections":[]
	}		

	
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
		if(rand.randi_range(0,3) == 3):
			connection[1] = !connection[1]
#		if(connection[1] == false):
#			if(rand.randi_range(0,3) == 3):
#				connection[1] = true
	
	for i in range(1,6):
		new_genome["nodes"].append(i)
		
	for connections in new_genome["connections"]:
		if(connections[0][0] not in new_genome["nodes"]):
			new_genome["nodes"].append(connections[0][0])
		if(connections[0][1] not in new_genome["nodes"]):
			new_genome["nodes"].append(connections[0][1])
	
	var bet = rand.randi_range(0,9)
	if(bet <= 7):
		mutate(new_genome)
	
	new_genome["id"] = id
	id += 1
	return new_genome	
		
func mutate(genome):
	var bet = rand.randi_range(0,9)
#	if(bet <= 100):
	if(bet <= 8):
		mutate_weights(genome)
	else:
		mutate_configuration(genome)
	pass
	
func mutate_weights(genome):
	for connection in genome["connections"]:
		var bet = rand.randi_range(0,9)
		if(bet <= 9):
			if(rand.randi_range(0,1) == 0):
				connection[2] = float(connection[2]) + (float(connection[2]) * 0.2)
			else:
				connection[2] = float(connection[2]) - (float(connection[2]) * 0.2)
		else:
			connection[2] = randf_range(-2,2)

func mutate_configuration(genome):
	var bet = rand.randi_range(0,11)
	if bet <= 3:
		add_connection(genome)
	elif bet <= 6:
		remove_connection(genome)
	elif bet < 10:
		add_node(genome)
	elif bet <= 11:
		remove_node(genome)
	pass
		
func add_connection(genome):
#	print(genome)
	var layer_data = {}
	var layers = []
	var indegree = {}
	var adj_matrix = {}
	
	for connection in genome["connections"]:
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
			if(layers.size() <= 0):
				layers.append([])
			layers[0].append(node)
	
	
	#arranging in layers
	for i in range(queue.size()):
		for node in adj_matrix[queue[i]]:
			indegree[node] -= 1
			indegree[node] = max(0,indegree[node])
			if(layer_data.has(node)):
				layer_data[node] = max(layer_data[node],layer_data[queue[i]]+1)
			else:
				layer_data[node] = layer_data[queue[i]]+1
			if(indegree[node] <= 0):
				if(layers.size() <= layer_data[node]):
#					print(layers.size()," ",layer_data[node])
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
		for temp in range(0,bet+1):
			layers_to_chose.pop_front()
#		layers_to_chose.remove_at(bet)
		if (layers_to_chose.size() == 0):
			break
		bet = rand.randi_range(0,layers_to_chose.size()-1)
		var end_layer = layers_to_chose[bet]
		bet = rand.randi_range(0,layers[start_layer].size()-1)
		var start_node = layers[start_layer][bet]
		bet = rand.randi_range(0,layers[end_layer].size()-1)
		var end_node = layers[end_layer][bet]
		var found = false
		for connection in genome["connections"]:
			if((connection[0][0] == start_node) and (connection[0][1] == end_node)):
				found = true
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
			genome["connections"].append([[start_node,end_node],true,randf_range(-2,2)])
			
			
		if(done == true):
			break
#	print(genome)
	return genome
	
	
	
func remove_connection(genome):
	var active_connections = []
	for i in range(genome["connections"].size()):
		if(genome["connections"][i][1]):
			active_connections.append(i)
	if(active_connections.size() > 0):
		var bet = rand.randi_range(0,active_connections.size()-1)
		genome["connections"][active_connections[bet]][1] = false
	
	return genome
	
func add_node(genome):
#	print(genome)
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
			
	if(active_connections.size() > 0):
		var bet = rand.randi_range(0,active_connections.size()-1)
		genome["connections"][active_connections[bet]][1] = false
		var from = genome["connections"][active_connections[bet]][0][0]
		var to = genome["connections"][active_connections[bet]][0][1]
		var weight = genome["connections"][active_connections[bet]][2]
		
		genome["nodes"].append(mex)
		if(!innovation.has(get_hash([from,mex]))):
			innovation[get_hash([from,mex])] = i_num
			i_num += 1
		genome["connections"].append([[from,mex],true,1])
		
		if(!innovation.has(get_hash([mex,to]))):
			innovation[get_hash([mex,to])] = i_num
			i_num += 1
		genome["connections"].append([[mex,to],true,weight])
#	print(genome)
	return genome
	
func remove_node(genome):
	if(genome["nodes"].size() == 5):
		return
	var bet = rand.randi_range(5,genome["nodes"].size()-1)
	var deleting_node = genome["nodes"][bet]
	for index in range(genome["connections"].size()):
		if((genome["connections"][index][0][0] == deleting_node) or (genome["connections"][index][0][1] == deleting_node)):
			genome["connections"][index][1] = false
	
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
			max2 = max(max2,innovation[get_hash(connection[0])])
			n2 += 1
	
	var n = max(n1,n2)
	var excess = 0
	var disjoint = 0
	var weights = 0
	var common_connections = 0
	if(n == n1):
		for connection in genome1["connections"]:
			if(connection[1] == false):
				continue
			var curr_i_num = innovation[get_hash(connection[0])]
			if(curr_i_num > n2):
				excess += 1
	else:
		for connection in genome2["connections"]:
			if(connection[1] == false):
				continue
			var curr_i_num = innovation[get_hash(connection[0])]
			if(curr_i_num > n1):
				excess += 1	
	for connection in genome1["connections"]:
		if(connection[1] == false):
			continue
		var found = false
		for connection2 in genome2["connections"]:
			if(connection2[1] == false):
				continue
			if(connection[0] == connection2[0]):
				found = true
				weights += abs(connection[2] - connection2[2])
				common_connections += 1
				break
		if(found == false):
			disjoint += 1
	for connection in genome1["connections"]:
		if(connection[1] == false):
			continue
		var found = false
		for connection2 in genome2["connections"]:
			if(connection2[1] == false):
				continue
			found = true
			break
		if(found == false):
			disjoint += 1
#	print(excess," ",disjoint," ",weights," ",common_connections)
	var temp = 0
	if(n != 0):
		temp = ((float(excess) * c1)/float(n)) + ((float(disjoint) * c2)/float(n))
	
	if(common_connections != 0):
		temp = temp + ((float(weights) * c3)/(float(common_connections)))
	return temp#((float(excess) * c1)/float(n)) + ((float(disjoint) * c2)/float(n)) + ((float(weights) * c3)/(float(common_connections)))
	

	
