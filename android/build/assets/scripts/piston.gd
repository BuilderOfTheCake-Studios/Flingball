extends Node3D

@onready var piston_collision_shape =  $StaticBody3D/CollisionShape3D2
@onready var old_position = piston_collision_shape.global_position

var player_in_range = false

func _physics_process(delta):
	$StaticBody3D.constant_linear_velocity = (piston_collision_shape.global_position - old_position) / delta
	old_position = piston_collision_shape.global_position

func _on_area_3d_body_entered(body):
	if body.name == "Player":
		print("HERE 1")
		$AnimationPlayer.play("push")
		if Global.settings["Sound on"]:
			$PistonAudio.play()
		print("Setting player_in_range to true")
		player_in_range = true
		$PushTimer.start()

func _on_area_3d_body_exited(body):
	if body.name == "Player":
		player_in_range = false
		print("EXITING AREA")

func _on_push_timer_timeout():
	print("Player in range:", player_in_range)
	if player_in_range:
		print("HERE 2")
		$AnimationPlayer.stop()
		$AnimationPlayer.play("push")
		$PistonAudio.play()
