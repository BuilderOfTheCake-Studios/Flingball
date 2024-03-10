extends CanvasLayer

@onready var main = $".."

var stats

# Called when the node enters the scene tree for the first time.
func _ready():
	initialize()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func initialize():
	$Control/MusicLabel/CheckButton.button_pressed = Global.settings["Music on"]
	$Control/SoundLabel/CheckButton.button_pressed = Global.settings["Sound on"]
	stats = main.load_stats()
	
	print("STATS:", stats)
	
	$Control/StatsLabel/BallsFlungLabel/BallsFlungStatLabel.text = str(stats["Balls flung"])
	$Control/StatsLabel/FlingsLabel/FlingsStatLabel.text = str(stats["Flings"])
	$Control/StatsLabel/TotalCoinsLabel/TotalCoinsStatLabel.text = str(stats["Total coins"])
	$Control/StatsLabel/SpikesHitLabel/SpikesHitStatLabel.text = str(stats["Spikes hit"])
	$Control/StatsLabel/FallsLabel/FallsStatLabel.text = str(stats["Falls"])
	$Control/StatsLabel/OffScreenDeathsLabel/OffScreenDeathsStatLabel.text = str(stats["Off screen deaths"])


func _on_music_check_button_toggled(toggled_on):
	Global.settings["Music on"] = toggled_on
	Global.save_settings()

func _on_sound_check_button_toggled(toggled_on):
	Global.settings["Sound on"] = toggled_on
	Global.save_settings()
