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
@onready var shop = $Shop
@onready var shop_animation_player = $Shop/Control/ShopAnimationPlayer
@onready var leaderboard_button = $HUD/Control/LeaderboardButton
@onready var settings = $Settings
@onready var shop_button = $HUD/Control/ShopButton
@onready var settings_button = $HUD/Control/SettingsButton
@onready var settings_animation_player = $Settings/Control/SettingsAnimationPlayer

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
var leaderboard_hold = false

# save data
var score = 0
var high_score = 0
var coins = 0
var _leaderboards_cache: Array[LeaderboardsClient.Leaderboard] = []
var leaderboard: LeaderboardsClient.Leaderboard
var stats = {
	"Balls flung": 0,
	"Flings": 0,
	"Total coins": 0,
	"Spikes hit": 0,
	"Falls": 0,
	"Off screen deaths": 0
}

# camera
var original_camera_position
@export var camera_max_speed = 4.56
@export var camera_start_speed = 2.6
@export var camera_acceleration = 0.016
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
	var animation_player = player.current_animation_player
	animation_player.play("idle")
	coins = load_coins()
	high_score = load_high_score()
	stats = load_stats()
	update_labels()
	load_title_screen()
	shop.visible = false
	if _leaderboards_cache.is_empty():
		LeaderboardsClient.load_all_leaderboards(true)
	LeaderboardsClient.all_leaderboards_loaded.connect(
		func cache_and_display(leaderboards: Array[LeaderboardsClient.Leaderboard]):
			_leaderboards_cache = leaderboards
			for leaderboard2: LeaderboardsClient.Leaderboard in _leaderboards_cache:
				leaderboard = leaderboard2
				update_labels()
	)
	LeaderboardsClient.score_submitted.connect(
		func refresh_score(is_submitted: bool, leaderboard_id: String):
			if is_submitted and leaderboard_id == leaderboard.leaderboard_id:
				_load_player_score()
	)	
	
func _load_player_score() -> void:
	LeaderboardsClient.load_player_score(
		leaderboard.leaderboard_id,
		LeaderboardsClient.TimeSpan.TIME_SPAN_ALL_TIME,
		LeaderboardsClient.Collection.COLLECTION_PUBLIC
	)

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
		if Global.settings["Sound on"]:
			$FallingAudio.play()
		stats["Falls"] += 1
		game_end()
	if player.position.z < camera.position.z - 5 or player.position.z > camera.position.z + 30:
		stats["Off screen deaths"] += 1
		game_end()
		
	# make the mouse indicators invisible when in the shop
	if game_state != "main_menu" and game_state != "playing":
		mouse_start_marker.visible = false
		mouse_end_marker.visible = false

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and leaderboard_hold:
			leaderboard_hold = false
			mouse_start_marker.modulate.a = 0
			mouse_end_marker.modulate.a = 0
			return
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and can_fling:
			mouse_start_marker.position = event.position
			mouse_held = true
			
			if tween:
				tween.kill()
			
			mouse_start_marker.visible = true
			mouse_end_marker.visible = true
			mouse_start_marker.modulate.a = 1
			mouse_end_marker.modulate.a = 1
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and can_fling and mouse_held and game_state != "shop" and game_state != "settings":
			if game_state == "main_menu":
				game_start()
			
			can_fling = false
			fling_timer.start()
			if Global.settings["Sound on"]:
				$FlingAudio.play()
			stats["Flings"] += 1
			
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
	var flipped = randi_range(0, 1) == 1
	if flipped:
		scene.scale.x *= -1
	current_link_marker = scene.get_node("LinkMarker")
	world_section_container.add_child(scene)
	
	# set signals for entities
	for child in scene.get_children():
		if "Spikes" in child.name:
			child.player_hit.connect(_on_spikes_player_hit)
		if "Coin" in child.name:
			child.signal_collected.connect(_on_coin_collected)
			
		if flipped and ("Crate" in child.name or "Spikes" in child.name or "Bumper" in child.name or "Platform" in child.name or "Piston" in child.name):
			child.scale.x *= -1
	pass
	
func game_start():
	print("GAME START")
	player.state = "alive"
	game_state = "playing"
	if Global.settings["Music on"]:
		audio.play()
	score = 0
	hide_title_screen()
	camera_speed = camera_start_speed
	stats["Balls flung"] += 1
	
func game_end():
	print("GAME END")
	game_state = "main_menu"
	player.state = "alive"
	player.linear_damp = 0
	var animation_player = player.current_animation_player
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
	save_stats()
	
	# generate new map
	previous_world_sections = []
	current_link_marker = original_link_marker
	for i in range(10):	
		generate_new_section()
		
	load_title_screen()
	
	# save high score
	high_score = load_high_score()
	if not high_score or score > high_score:
		high_score = score
		save_high_score()
		update_labels()
		
	# submit score to google play services
	if leaderboard:
		var score_official = float(score_label.text) * 10
		LeaderboardsClient.submit_score(leaderboard.leaderboard_id, score_official)

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
		if Global.settings["Sound on"]:
			$SpikeHitAudio.play()
		var animation_player = player.current_animation_player
		var particles = player.get_node("Particles")
		player.linear_damp = 10
		particles.emitting = true
		animation_player.play("die")
		death_reset_timer.start()
		death_reset_timer.timeout.connect(game_end)
		player.play_death_animation()
		stats["Spikes hit"] += 1

func _on_visible_on_screen_notifier_3d_screen_entered():
	show_off_screen_marker = false

func _on_visible_on_screen_notifier_3d_screen_exited():
	show_off_screen_marker = true
	
func _on_coin_collected():
	coins += 1
	score += 1
	stats["Total coins"] += 1
	$HUD/Control/ScoreLabel/ScoreAnimationPlayer.stop()
	$HUD/Control/ScoreLabel/ScoreAnimationPlayer.play("jump")
	$HUD/Control/CoinLabel/CoinLabelAnimationPlayer.stop()
	$HUD/Control/CoinLabel/CoinLabelAnimationPlayer.play("jump")
	save_coins()
	update_labels()
	
func update_labels():
	coin_label.text = str(coins)
	score_label.text = "%.1f" % score
	high_score_label.text = "High: " +  "%.1f" % high_score
	
var load_tween
func load_title_screen():
	title_animation_player.play("fade in")
	var load_tween = get_tree().create_tween()
	load_tween.set_ease(Tween.EASE_OUT)
	load_tween.set_trans(Tween.TRANS_SINE)
	load_tween.parallel().tween_property(shop_button, "global_position:x", 20, 0.5)
	load_tween.parallel().tween_property(shop_button, "global_position:y", get_viewport().get_visible_rect().size.y - 200, 0.5)
	load_tween.parallel().tween_property(settings_button, "global_position:x", 319, 0.5)
	load_tween.parallel().tween_property(settings_button, "global_position:y", get_viewport().get_visible_rect().size.y - 200, 0.5)
	
func hide_title_screen():
	title_animation_player.play("slide out")
	if load_tween:
		load_tween.pause()
		load_tween.custom_step(1)
		load_tween.remove_all()
	var button_tween = get_tree().create_tween()
	button_tween.set_ease(Tween.EASE_IN)
	button_tween.set_trans(Tween.TRANS_SINE)
	button_tween.parallel().tween_property(shop_button, "global_position:x", -450, 0.4)
	button_tween.parallel().tween_property(shop_button, "global_position:y", get_viewport().get_visible_rect().size.y + 250, 0.4)
	button_tween.parallel().tween_property(settings_button, "global_position:x", 700, 0.4)
	button_tween.parallel().tween_property(settings_button, "global_position:y", get_viewport().get_visible_rect().size.y + 250, 0.4)
	
# save data
func save_coins(coins=coins):
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
		return float(content)
	return 0
	
func save_stats():
	var file = FileAccess.open("user://stats.dat", FileAccess.WRITE)
	file.store_string(JSON.stringify(stats))
	
func load_stats():
	var file = FileAccess.open("user://stats.dat", FileAccess.READ)
	if file:
		var content = file.get_as_text()
		return JSON.parse_string(content)
	return stats

# gui
func _on_shop_button_button_down():
	game_state = "shop"
	shop.visible = true
	hide_title_screen()
	shop_animation_player.play("fly in")
	settings.visible = false

func _on_back_button_button_down():
	load_title_screen()
	shop_animation_player.play("slide out")

func _on_back_button_button_up():
	game_state = "main_menu"
	
func _on_settings_back_button_button_up():
	game_state = "main_menu"
	settings.visible = false
	
func _on_settings_button_button_down():
	game_state = "settings"
	settings.visible = true
	hide_title_screen()
	settings_animation_player.play("fly in")
	settings.initialize()
	shop.visible = false

func _on_settings_back_button_button_down():
	load_title_screen()
	settings_animation_player.play("slide out")

func _on_leaderboard_button_button_down():
	leaderboard_hold = true
	LeaderboardsClient.show_all_leaderboards()
