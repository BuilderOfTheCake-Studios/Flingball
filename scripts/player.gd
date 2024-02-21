extends RigidBody3D

@export var current_mesh: MeshInstance3D
@export var current_animation_player: AnimationPlayer

var state = "alive"

# Called when the node enters the scene tree for the first time.
func _ready():
	print("PLAYER READY")
	current_mesh = $MeshInstance3D
	current_animation_player = $AnimationPlayer
	#$MeshInstance3D.queue_free()
	#$AnimationPlayer.queue_free()
	#print("MESH QUEUED FREE:", $MeshInstance3D)
	#var mesh_to_add = current_mesh.duplicate()
	#var animation_player_to_add = current_animation_player.duplicate()
	#add_child(mesh_to_add)
	#add_child(animation_player_to_add)
	#mesh_to_add.name = "MeshInstance3D"
	#animation_player_to_add.name = "AnimationPlayer"
	#print("MESH REPLACED:", mesh_to_add.name)
	#print("ANIMATION PLAYER REPLACED:", animation_player_to_add.name)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
