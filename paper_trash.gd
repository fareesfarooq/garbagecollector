extends Node2D

var textures: Array[Texture2D] = [
	preload("res://Assets/Standard Trash/trash_box.png"),
	preload("res://Assets/Standard Trash/trash_cup.png")
]

var trash_type = "paper"

@onready var sprite = $PaperSprite


func _ready():
	randomize()

	if textures.size() > 0:
		sprite.texture = textures[randi() % textures.size()]

	# You must get screen size here (after ready)
