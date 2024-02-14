extends Node3D

var collected = false

func _ready():
	# make all materials unique on instantiation
	$Mesh.set_surface_override_material(0, $Mesh.get_surface_override_material(0).duplicate())
	$Mesh.set_surface_override_material(1, $Mesh.get_surface_override_material(1).duplicate())

func _on_area_3d_body_entered(body):
	if collected or body.name != "Player":
		return
		
	collected = true
	$AnimationPlayer.play("collected")
	$CollectTimer.start()
	
func _on_collect_timer_timeout():
	queue_free()
