extends Node3D

@export var horizontal = true
@export var distance = 1
@export var speed: float = 1

@onready var body = $StaticBody3D

var origin = position
var mirror = 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	body.linear_velocity.x = speed * delta * mirror
	position.x += speed * delta * mirror
	
	if position.x > origin.x + distance:
		mirror = -1
		position.x = origin.x + distance
	if position.x < origin.x - distance:
		mirror = 1
		position.x = origin.x - distance
