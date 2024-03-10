extends Node

var settings = {
	"Music on": true,
	"Sound on": true
}

func _ready():
	settings = load_settings()

func save_settings():
	var file = FileAccess.open("user://settings.dat", FileAccess.WRITE)
	file.store_string(JSON.stringify(settings))
	
func load_settings():
	var file = FileAccess.open("user://settings.dat", FileAccess.READ)
	if file:
		var content = file.get_as_text()
		return JSON.parse_string(content)
	return settings
