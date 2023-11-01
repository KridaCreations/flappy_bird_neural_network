extends Node


for i in range(max_birds):
		var new_genome = {
			"nodes":[],
			"connections":[]
		}
		for node in orig_adj_mat:
			for data in orig_adj_mat[node]:
				var to = data[0]
				var weight = data[1]
				if(!new_genome["nodes"].has(to)):
					new_genome["nodes"].append(to)
				if(!new_genome["nodes"].has(node)):
					new_genome["nodes"].append(node)
				var hash = get_hash([node,to])
				if(!innovation.has(hash)):
					innovation[hash] = i_num
					i_num += 1
				new_genome["connections"].append([[node,to],true,weight])
		genomes.append(new_genome)
		genomes_score.append(0)
