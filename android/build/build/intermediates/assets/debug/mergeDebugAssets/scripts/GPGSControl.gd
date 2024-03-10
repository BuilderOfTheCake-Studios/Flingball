extends Control

@onready var title_label: Label = $ConnectionLabel

var player: PlayersClient.Player
var _sign_in_retries := 5

# Called when the node enters the scene tree for the first time.
func _ready():
	if not GodotPlayGameServices.android_plugin:
		title_label.text = "Plugin Not Found!"
	
	SignInClient.user_authenticated.connect(func(is_authenticated: bool):
		if _sign_in_retries > 0 and not is_authenticated:
			title_label.text = "Trying to sign in!"
			SignInClient.sign_in()
			_sign_in_retries -= 1
		
		if _sign_in_retries == 0:
			title_label.text = "Sign in attemps expired!"
		
		if is_authenticated:
			title_label.text = "Connected"
	)
	
	if not player:
		PlayersClient.load_current_player(true)
	PlayersClient.current_player_loaded.connect(func(current_player: PlayersClient.Player):
		title_label.text = "Welcome, " + current_player.display_name
	)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
