extends Node3D

signal player_hit

func _on_spike_area_body_entered(body):
	if body.name == "Player":
		player_hit.emit()
