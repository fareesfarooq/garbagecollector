extends Node2D

var trash_textures = [
	preload("res://Assets/Standard Trash/trash_box.png"),
	preload("res://Assets/Standard Trash/trash_cup.png")
]

func _ready():
	$PaperSprite.texture = trash_textures[randi() % trash_textures.size()]
