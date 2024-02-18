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
@onready var directional_light = $DirectionalLight3D
@onready var start_line = $HubWorld/StartLine

# ui 
@onready var mouse_start_marker = $HUD/MouseStartMarker
@onready var mouse_end_marker = $HUD/MouseEndMarker
@onready var fling_bar = $HUD/Control/FlingBar
@onready var score_label = $HUD/Control/ScoreLabel
@onready var high_score_label = $HUD/Control/HighScoreLabel
@onready var coin_label = $HUD/Control/CoinLabel
@onready var off_screen_marker = $HUD/OffScreenMarker
@onready var title_panel = $HUD/Control/TitlePanel
@onready var instruction_label = $HUD/Control/InstructionLabel
@onready var title_animation_player = $HUD/Control/TitleAnimationPlayer

# audio
@onready var audio = $Music
@onready var spike_hit_audio = $SpikeHitAudio

# functional
var game_state
var tween
var original_player_position
var previous_world_sections = []
var previous_world_section_cap = 3

# controls
var mouse_held = false
var can_fling = true

# save data
var score = 0
var high_score = 0
var coins = 0

# camera
var original_camera_position
var camera_max_speed = 5
var camera_start_speed = 3
var camera_acceleration = 0.02
var camera_speed = camera_start_speed
var show_off_screen_marker = false
var off_screen_marker_padding = 35


func _ready():
	load_all_resources()
	original_player_position = player.position
	original_camera_position = camera.position
	game_start()
	game_state = "main_menu"
	audio.stop()
	for i in range(10):	
		generate_new_section()
	var animation_player = player.get_node("AnimationPlayer")
	animation_player.play("idle")
	coins = load_coins()
	high_score = load_high_score()
	update_labels()
	title_animation_player.play("fade in")

func _process(delta):
	directional_light.global_position = camera.global_position
	
	if mouse_held:
		mouse_end_marker.position = get_viewport().get_mouse_position()
		
	if game_state == "playing":	
		camera.position.z += camera_speed * delta
		camera_speed = min(camera_speed + camera_acceleration * delta, camera_max_speed)
		
		# set player trail
		var total_velocity = abs(player.linear_velocity.x) + abs(player.linear_velocity.y) + abs(player.linear_velocity.z)
		var trail_threshold = 10
		var player_trail = player.get_node("Trail3D")
		player_trail.material_override.albedo_color.a = min(1, total_velocity / trail_threshold)
	
	fling_bar.value = 1 - (fling_timer.time_left / fling_timer.wait_time)
	
	# if map section is off-screen behind camera, delete it and generate a new section
	for child in world_section_container.get_children():
		if child.global_position.z < camera.global_position.z - 30:
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
			mouse_start_marker.position = event.position
			mouse_held = true
			
			if tween:
				tween.kill()
			
			mouse_start_marker.modulate.a = 1
			mouse_end_marker.modulate.a = 1
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and can_fling and mouse_held:
			if game_state == "main_menu":
				game_start()
			
			can_fling = false
			fling_timer.start()
			$FlingAudio.play()
			
			mouse_end_marker.position = event.position
			mouse_held = false
			
			# shoot player
			var difference = -(mouse_end_marker.position - mouse_start_marker.position) / 20
		
			player.linear_velocity.x += difference.x
			player.linear_velocity.z += difference.y
			player.angular_velocity = Vector3.ZERO
			
			# make markers disappear
			tween = get_tree().create_tween()
			tween.tween_property(mouse_start_marker, "modulate:a", 0, 0.1)
			tween.tween_property(mouse_end_marker, "modulate:a", 0, 0.1)
			
func load_all_resources():
	return
	print("Loading all resources")
	for section in world_sections:
		var scene = section.instantiate()
		world_section_container.add_child(scene)
	for child in world_section_container.get_children():
		child.queue_free()
	_on_spikes_player_hit()
	print("Loading finished")

func generate_new_section():
	var section = world_sections.pick_random()
	
	while section in previous_world_sections:
		section = world_sections.pick_random()
	
	previous_world_sections.append(section)
	
	if len(previous_world_sections) > previous_world_section_cap:
		previous_world_sections.pop_front()
		
	var scene = section.instantiate()
	scene.position = current_link_marker.global_position
	current_link_marker = scene.get_node("LinkMarker")
	world_section_container.add_child(scene)
	
	# set signals for entities
	for child in scene.get_children():
		if "Spikes" in child.name:
			child.player_hit.connect(_on_spikes_player_hit)
		if "Coin" in child.name:
			child.signal_collected.connect(_on_coin_collected)
	pass
	
func game_start():
	print("GAME START")
	player.state = "alive"
	game_state = "playing"
	audio.play()
	score = 0
	title_animation_player.play("slide out")
	camera_speed = camera_start_speed
	
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
	var player_trail = player.get_node("Trail3D")
	player_trail.material_override.albedo_color.a = 0
	
	# generate new map
	previous_world_sections = []
	current_link_marker = original_link_marker
	for i in range(10):	
		generate_new_section()
		
	title_animation_player.play("fade in")
	
	# save high score
	high_score = load_high_score()
	if not high_score or score > high_score:
		high_score = score
		save_high_score()
		update_labels()

func _on_fling_timer_timeout():
	print("Fling timeout!")
	can_fling = true

func _on_score_timer_timeout():
	if game_state == "playing":
		score += 0.1
	update_labels()

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
	
func _on_coin_collected():
	coins += 1
	save_coins()
	update_labels()
	
func update_labels():
	coin_label.text = str(coins)
	score_label.text = "%.1f" % score
	high_score_label.text = "High: " +  "%.1f" % high_score
	
func save_coins():
	var file = FileAccess.open("user://coins.dat", FileAccess.WRITE)
	file.store_string(JSON.stringify(coins))
	
func load_coins():
	var file = FileAccess.open("user://coins.dat", FileAccess.READ)
	if file:
		var content = file.get_as_text()
		return int(content)
	return 0
	
func save_high_score():
	var file = FileAccess.open("user://high_score.dat", FileAccess.WRITE)
	file.store_string(JSON.stringify(high_score))
	
func load_high_score():
	var file = FileAccess.open("user://high_score.dat", FileAccess.READ)
	if file:
		var content = file.get_as_text()
		return int(content)
	return 0


func _on_shop_button_button_down():
	pass # Replace with function body.


func _on_settings_button_button_down():
	pass # Replace with function body.
