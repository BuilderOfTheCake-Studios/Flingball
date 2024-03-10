extends Control

# shop data
@export var item_name: String
@export var price: int
@export var bought: bool
@export var used: bool
@export var preview_image: Texture2D

# player mesh and animation data
@export var mesh: MeshInstance3D
@export var animation_player: AnimationPlayer

func _ready():
	draw_labels()

func _process(delta):
	pass
	
func draw_labels():
	$ItemNameLabel.text = item_name
	$PriceLabel.text = str(price)
	$BuyButton.disabled = bought
	$UseButton.disabled = used or not bought
	$PreviewSprite.texture = preview_image

	if $BuyButton.disabled:
		$BuyButton.focus_mode = FOCUS_NONE
	else:
		$BuyButton.focus_mode = FOCUS_CLICK
		
	if $UseButton.disabled:
		$UseButton.focus_mode = FOCUS_NONE
	else:
		$UseButton.focus_mode = FOCUS_CLICK
