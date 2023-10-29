extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _physics_process(delta):
	if(global_position.x <= -100):
		queue_free()
	
	global_position += get_parent().velocity
	pass
