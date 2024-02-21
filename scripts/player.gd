extends RigidBody3D

@export var current_mesh: MeshInstance3D
@export var current_animation_player: AnimationPlayer
@export var actual_mesh: MeshInstance3D
@export var actual_animation_player: AnimationPlayer

var state = "alive"

# Called when the node enters the scene tree for the first time.
func _ready():
	print("PLAYER READY")
	#current_mesh = $MeshInstance3D
	#current_animation_player = $AnimationPlayer
	
	#current_mesh = $Skins/DefaultGreen/MeshInstance3D
	#current_animation_player = $Skins/DefaultGreen/AnimationPlayer
	apply_current_nodes()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func apply_current_nodes():
	if actual_mesh:
		actual_mesh.queue_free()
	if actual_animation_player:
		actual_animation_player.queue_free()
	actual_mesh = current_mesh.duplicate()
	actual_animation_player = current_animation_player.duplicate()
	add_child(actual_mesh)
	add_child(actual_animation_player)
	actual_mesh.name = "MeshInstance3D"
	actual_mesh.scale = Vector3(1, 1, 1)
	actual_animation_player.name = "AnimationPlayer"
