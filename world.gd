extends Node3D

@export var world_sections: Array[PackedScene]

@onready var player = $Player
@onready var mouse_start_marker = $HUD/MouseStartMarker
@onready var mouse_end_marker = $HUD/MouseEndMarker
@onready var camera = $Camera3D
@onready var original_link_marker = $HubWorld/LinkMarker
@onready var current_link_marker = $HubWorld/LinkMarker
@onready var fling_timer = $FlingTimer
@onready var fling_bar = $HUD/Control/FlingBar
@onready var audio = $AudioStreamPlayer
@onready var score_label = $HUD/Control/ScoreLabel
@onready var world_section_container = $WorldSectionContainer

var game_state
var tween
var mouse_held = false
var can_fling = true
var score = 0
var original_player_position
var original_camera_position

func _ready():
	original_player_position = player.position
	original_camera_position = camera.position
	game_start()
	game_state = "main_menu"
	audio.stop()
	for i in range(10):	
		generate_new_section()

func _process(delta):
	if mouse_held:
		mouse_end_marker.position = get_viewport().get_mouse_position()
		
	if game_state == "playing":	
		camera.position.z += 3 * delta
	
	fling_bar.value = 1 - (fling_timer.time_left / fling_timer.wait_time)
	
	# if map section is off-screen behind camera, delete it and generate a new section
	for child in world_section_container.get_children():
		if child.global_position.z < camera.global_position.z - 10:
			print("WORLD SECTION SHIFT")
			child.queue_free()
			generate_new_section()
			
	if player.position.y < -5:
		game_end()
	if player.position.z < camera.position.z - 5 or player.position.z > camera.position.z + 15:
		game_end()

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and can_fling:
			print("Left button was clicked at ", event.position)
			mouse_start_marker.position = event.position
			mouse_held = true
			
			if tween:
				tween.kill()
			
			mouse_start_marker.modulate.a = 1
			mouse_end_marker.modulate.a = 1
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and can_fling and mouse_held:
			print("Left button was released at ", event.position)
			if game_state == "main_menu":
				game_start()
			
			can_fling = false
			fling_timer.start()
			
			mouse_end_marker.position = event.position
			mouse_held = false
			
			# shoot player
			var difference = -(mouse_end_marker.position - mouse_start_marker.position) / 20
			print("Shooting at:", difference)
		
			player.linear_velocity.x += difference.x
			player.linear_velocity.z += difference.y
			player.angular_velocity = Vector3.ZERO
			
			# make markers disappear
			tween = get_tree().create_tween()
			tween.tween_property(mouse_start_marker, "modulate:a", 0, 0.1)
			tween.tween_property(mouse_end_marker, "modulate:a", 0, 0.1)

func generate_new_section():
	var section = world_sections.pick_random()
	var scene = section.instantiate()
	scene.position = current_link_marker.global_position
	current_link_marker = scene.get_node("LinkMarker")
	world_section_container.add_child(scene)
	
func game_start():
	game_state = "playing"
	audio.play()
	score = 0
	
func game_end():
	game_state = "main_menu"
	for child in world_section_container.get_children():
		child.queue_free()
	player.position = original_player_position
	player.linear_velocity = Vector3.ZERO
	player.angular_velocity = Vector3.ZERO
	camera.position = original_camera_position
	audio.stop()
	current_link_marker = original_link_marker
	for i in range(10):	
		generate_new_section()

func draw_score_label():
	score_label.text = "Score: " + "%.1f" % score

func _on_fling_timer_timeout():
	print("Fling timeout!")
	can_fling = true

func _on_score_timer_timeout():
	if game_state == "playing":
		score += 0.1
	draw_score_label()
