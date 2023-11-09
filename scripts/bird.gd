extends Area2D

var index 
var genome = {
	"nodes":[],
	"connections":[]
}

var tick = 0
var reaction_time = 0
var score = 0
var scene_gravity = Vector2(0,40)
var velocity = Vector2.ZERO
var jump_force = Vector2(0,-900)
# Called when the node enters the scene tree for the first time.
func _ready():
	area_entered.connect(die)
	pass # Replace with function body.

func jump(delta):
	velocity += jump_force*delta
	
	pass

func _physics_process(delta):
#	tick = tick - 1
	tick = max(tick-1,0)
	score += 0.05
	$Label.text = str(int(score*100))
	
	if(tick <= 0):
		tick = reaction_time
		var input1 = 1
		var input2 = 0
		var input3 = 0
		var input4 = global_position.y
		var u_col = ($upper_ray.is_colliding() and ($upper_ray.get_collider().is_in_group("pole")))
		var l_col = ($lower_ray.is_colliding() and ($lower_ray.get_collider().is_in_group("pole")))
		if(l_col and u_col):
			if($lower_ray.get_collider().global_position.x < $upper_ray.get_collider().global_position.x):
				input2 = $lower_ray.get_collider().upper_marker.global_position.y
				input3 = $lower_ray.get_collider().lower_marker.global_position.y
			else:
				input2 = $upper_ray.get_collider().upper_marker.global_position.y
				input3 = $upper_ray.get_collider().lower_marker.global_position.y
		elif(l_col):
			input2 = $lower_ray.get_collider().upper_marker.global_position.y
			input3 = $lower_ray.get_collider().lower_marker.global_position.y
		elif(u_col):
			input2 = $upper_ray.get_collider().upper_marker.global_position.y
			input3 = $upper_ray.get_collider().lower_marker.global_position.y
		
	#	print(name," ",solve_genome(input1,input2,input3,input4))
		var output = solve_genome(input1,input2,input3,input4)
	#	var output = solve_genome(input1,input2,input3)
	#	print(output)
		if(output > 0):
			jump(delta)
	
	velocity += scene_gravity*delta
	
	
#	if(Input.is_action_just_pressed("click")):
#		jump(delta)
	velocity.y = max(-7,velocity.y)
	velocity.y = min(40,velocity.y)
	global_position += velocity	
	pass
	
func solve_genome(input1,input2,input3,input4):
#func solve_genome(input1,input2,input3):
	var adj_matrix = {}
	var indegree = {}
	var value = {}
	var connections = genome["connections"]
	for connection in connections:
		if(connection[1] == true):
			var from = connection[0][0]
			var to = connection[0][1]
			value[from] = 0.0
			value[to] = 0.0
			if(!indegree.has(from)):
				indegree[from] = 0
			if(indegree.has(to)):
				indegree[to] += 1
			else:
				indegree[to] = 1
			if(adj_matrix.has(from)):
				adj_matrix[from].append([to,connection[2]])
			else:
				adj_matrix[from] = [[to,connection[2]]]
#	print(adj_matrix)		
	value[1] = input1
	value[2] = input2
	value[3] = input3
	value[4] = input4
	var curr = []
	for node in indegree:
		if((indegree.has(node)) and (indegree[node] == 0)):
			curr.append(node)
	
	for i in range(curr.size()):
		for node in adj_matrix[curr[i]]:
			indegree[node[0]] -= 1
			indegree[node[0]] = max(0,indegree[node[0]])
			value[node[0]] = float(value[node[0]]) + (float(value[curr[i]]) * float(node[1]))
			if(indegree[node[0]] == 0):
				curr.append(node[0])
				value[node[0]] = max(0,value[node[0]])
				
	if(value.has(5)):
#		print("ter")
		return value[5]
	else:
#		print("here========")
		return 0			


func die(area):
	get_parent().genomes_score[index] = int(score*100)
	get_parent().bird_died += 1
	get_parent().get_node("birds_died").text = str(get_parent().bird_died)
	queue_free()
#	print(self.name," is dead")
	pass
