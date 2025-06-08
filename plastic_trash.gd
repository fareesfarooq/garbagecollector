extends Node2D

var trash_textures = [
	preload("res://Assets/Standard Trash/trash_plastic.png")
]

func _ready():
	$PlasticSprite.texture = trash_textures[randi() % trash_textures.size()]
