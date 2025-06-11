extends Node2D

var textures: Array[Texture2D] = [
	preload("res://Assets/Standard Trash/trash_apple.png"),
	preload("res://Assets/Standard Trash/trash_bone.png"),
	preload("res://Assets/Standard Trash/trash_chese.png"),
	preload("res://Assets/Standard Trash/trash_bread.png")
]
@onready var sprite = $OrganicSprite
var trash_type = "organic"
func _ready():

	randomize()
	if textures.size() > 0:
		sprite.texture = textures[randi() % textures.size()]
		
