extends Control

@onready var main = $"../.."
@onready var player = $"../../Player"

var coins = 0
var shop_data = {}

func _ready():
	shop_data = load_shop_data()
	
	# shop data has not yet been saved
	for child in $ScrollContainer/ShopItems.get_children():
		if child.name not in shop_data.keys():
			shop_data[child.name] = {
				"item_name": child.item_name,
				"bought": child.bought,
				"used": child.used
			}
		save_shop_data()
		
	update_item_display()
	
	# connect buttons to functions from the shop items
	for shop_item in $ScrollContainer/ShopItems.get_children():
		var buy_button = shop_item.get_node("BuyButton")
		var use_button = shop_item.get_node("UseButton")
		buy_button.button_down.connect(buy_button_pressed.bind(shop_item))
		use_button.button_down.connect(use_button_pressed.bind(shop_item))
		
	update_player_nodes()

func _process(delta):
	pass
	
func buy_button_pressed(shop_item):
	print("BUY BUTTON PRESS!", shop_item.item_name, shop_item.price)
	if coins > shop_item.price:
		shop_data[shop_item.name].bought = true
		coins -= shop_item.price
		main.save_coins(coins)
		save_shop_data()
		update_item_display()
	
func use_button_pressed(shop_item):
	print("USE BUTTON PRESS!", shop_item.item_name, shop_item.price)
	for key in shop_data.keys():
		if shop_data[key].used:
			shop_data[key].used = false
	shop_data[shop_item.name].used = true
	save_shop_data()
	update_item_display()
	update_player_nodes()
	
func update_player_nodes():
	for key in shop_data.keys():
		if shop_data[key].used:
			var shop_item = $ScrollContainer/ShopItems.get_node(key)
			player.current_mesh = shop_item.mesh
			player.current_animation_player = shop_item.animation_player
			player.apply_current_nodes()
	
func update_item_display():
	coins = main.load_coins()
	$CoinPanel/CoinLabel.text = str(coins)
	for key in shop_data.keys():
		var shop_item = $ScrollContainer/ShopItems.get_node(key)
		if not shop_item:
			continue
		shop_item.bought = shop_data[key].bought
		shop_item.used = shop_data[key].used
		shop_item.draw_labels()
	
func save_shop_data():
	var file = FileAccess.open("user://shop_data.dat", FileAccess.WRITE)
	file.store_string(JSON.stringify(shop_data))
	
func load_shop_data():
	var file = FileAccess.open("user://shop_data.dat", FileAccess.READ)
	print("LOAD SHOP DATA FILE:", file)
	if file:
		var content = file.get_as_text()
		return JSON.parse_string(content)
	return {}


func _on_shop_button_button_down():
	update_item_display()
