extends Node3D

@export var world_sections: Array[PackedScene]

# functional
@onready var world_section_container = $WorldSectionContainer
@onready var original_link_marker = $HubWorld/LinkMarker
@onready var current_link_marker = $HubWorld/LinkMarker
@onready var fling_timer = $FlingTimer
@onready var death_reset_timer = $DeathResetTimer
@onready var on_screen_notifier = $Player/VisibleOnScreenNotifier3D

# objects
@onready var player = $Player
@onready var camera = $Camera3D

# ui 
@onready var mouse_start_marker = $HUD/MouseStartMarker
@onready var mouse_end_marker = $HUD/MouseEndMarker
@onready var fling_bar = $HUD/Control/FlingBar
@onready var score_label = $HUD/Control/ScoreLabel
@onready var off_screen_marker = $HUD/OffScreenMarker


# audio
@onready var audio = $Music
@onready var spike_hit_audio = $SpikeHitAudio

var game_state
var tween
var mouse_held = false
var can_fling = true
var score = 0
var original_player_position
var original_camera_position
var camera_speed = 3
var show_off_screen_marker = false
var off_screen_marker_padding = 35

func _ready():
	original_player_position = player.position
	original_camera_position = camera.position
	game_start()
	game_state = "main_menu"
	audio.stop()
	for i in range(10):	
		generate_new_section()
	var animation_player = player.get_node("AnimationPlayer")
	animation_player.play("idle")

func _process(delta):
	if mouse_held:
		mouse_end_marker.position = get_viewport().get_mouse_position()
		
	if game_state == "playing":	
		camera.position.z += camera_speed * delta
	
	fling_bar.value = 1 - (fling_timer.time_left / fling_timer.wait_time)
	
	# if map section is off-screen behind camera, delete it and generate a new section
	for child in world_section_container.get_children():
		if child.global_position.z < camera.global_position.z - 10:
			print("WORLD SECTION SHIFT")
			child.queue_free()
			generate_new_section()
			
	# show off screen marker
	off_screen_marker.visible = show_off_screen_marker
	off_screen_marker.position = camera.unproject_position(player.global_position)
	off_screen_marker.position.x = clamp(off_screen_marker.position.x, off_screen_marker_padding, get_viewport().get_visible_rect().size.x - off_screen_marker_padding)
	off_screen_marker.position.y = clamp(off_screen_marker.position.y, off_screen_marker_padding, get_viewport().get_visible_rect().size.y - off_screen_marker_padding)
	off_screen_marker.look_at(camera.unproject_position(player.global_position))
	off_screen_marker.rotation_degrees += 90
			
	# move the camera faster and accumulate more points when ball is far ahead
	#if player.position.z > camera.position.z + 4:
		#score += player.position.z - (camera.position.z + 4)
		#camera.position.z = player.position.z - 4
			
	# game over conditions
	if player.position.y < -5:
		$FallingAudio.play()
		game_end()
	if player.position.z < camera.position.z - 5 or player.position.z > camera.position.z + 30:
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
			$FlingAudio.play()
			
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
	
	# set signals for entities
	for child in scene.get_children():
		if "Spikes" == child.name:
			child.player_hit.connect(_on_spikes_player_hit)
	pass
	
func game_start():
	print("GAME START")
	player.state = "alive"
	game_state = "playing"
	audio.play()
	score = 0
	
func game_end():
	print("GAME END")
	game_state = "main_menu"
	player.state = "alive"
	player.linear_damp = 0
	var animation_player = player.get_node("AnimationPlayer")
	animation_player.play("idle")
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

func _on_spikes_player_hit():
	if player.state == "alive":
		player.state = "dead"
		$SpikeHitAudio.play()
		var animation_player = player.get_node("AnimationPlayer")
		var particles = player.get_node("Particles")
		player.linear_damp = 10
		particles.emitting = true
		animation_player.play("die")
		death_reset_timer.start()
		death_reset_timer.timeout.connect(game_end)

func _on_visible_on_screen_notifier_3d_screen_entered():
	show_off_screen_marker = false

func _on_visible_on_screen_notifier_3d_screen_exited():
	show_off_screen_marker = true
