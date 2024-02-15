extends Node3D

@onready var piston_collision_shape =  $StaticBody3D/CollisionShape3D2
@onready var old_position = piston_collision_shape.global_position

var player_in_range = false

func _physics_process(delta):
	$StaticBody3D.constant_linear_velocity = (piston_collision_shape.global_position - old_position) / delta
	old_position = piston_collision_shape.global_position

func _on_area_3d_body_entered(body):
	if body.name == "Player":
		$AnimationPlayer.play("push")
	player_in_range = true

func _on_animation_player_animation_finished(anim_name):
	print("ANIMATION FINISHED", player_in_range, anim_name)	
	if player_in_range and anim_name == "push":
		$AnimationPlayer.play("push")

func _on_area_3d_body_exited(body):
	if body.name == "Player":
		player_in_range = false
