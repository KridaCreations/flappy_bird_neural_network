extends Area2D

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
	
	velocity += scene_gravity*delta
	if(Input.is_action_just_pressed("click")):
		jump(delta)
	velocity.y = max(-7,velocity.y)
	velocity.y = min(40,velocity.y)
	global_position += velocity	
	pass

func die(area):
	print("dead")
	pass
