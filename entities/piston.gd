extends Node3D

@onready var piston_collision_shape =  $StaticBody3D/CollisionShape3D2
@onready var old_position = piston_collision_shape.global_position

func _physics_process(delta):
	$StaticBody3D.constant_linear_velocity = (piston_collision_shape.global_position - old_position) / delta
	old_position = piston_collision_shape.global_position

func _on_area_3d_body_entered(body):
	if body.name == "Player":
		$AnimationPlayer.play("push")
