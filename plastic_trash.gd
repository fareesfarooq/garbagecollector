extends Node2D

var textures: Array[Texture2D] = [
	preload("res://Assets/Standard Trash/trash_plastic.png")
]
@onready var sprite = $PlasticSprite
var trash_type = "plastic"
func _ready():

	randomize()
	if textures.size() > 0:
		sprite.texture = textures[randi() % textures.size()]
