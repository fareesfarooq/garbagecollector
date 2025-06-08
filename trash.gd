extends Node2D
var height : int = 1920
var width : int = 1080
var rng = RandomNumberGenerator.new()
@export var trash_scenes : Array[PackedScene]  # List of different trash types

func _ready():


	for child in get_children():
		print("Positioned ", child.name, " at ", child.position)

		var r_height = randf_range(1, height)
		var r_width = randf_range(1, width)
		child.position = Vector2(r_height, r_width)
		

	
	
