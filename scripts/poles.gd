extends Node2D
var count = 0
var rng = RandomNumberGenerator.new()
var demo_pole = preload("res://scenes/demo_pole.tscn")
var last_pole = null
var starting_point = 1280
var threshold_point = 890
var velocity = Vector2(-4,0)
var start = false
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if(start):
		if((last_pole == null) or (last_pole.global_position.x <= threshold_point)):
			var new_pole = demo_pole.instantiate()
			new_pole.global_position = Vector2(starting_point,rng.randi_range(166,551))
			new_pole.name = str(count)
			count += 1
			add_child(new_pole)
			last_pole = new_pole
	
		
	
func clear_poles():
	for node in get_children():
		node.queue_free()
	last_pole = null
	pass
