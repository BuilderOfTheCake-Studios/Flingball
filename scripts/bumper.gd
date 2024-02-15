extends Node3D

@export var force = 10

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_area_3d_body_entered(body):
	if body.name == "Player":
		$AnimationPlayer.play("bump")
		var direction = body.global_position - global_position
		direction.y = 0
		body.linear_velocity += direction * force
