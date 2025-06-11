extends Node2D


func _ready():
	var trashSprite = get_node("Sprite2D")
	trashSprite.position.x = randf_range(20, 600)
	trashSprite.position.y = randf_range(20, 600)
	
	
