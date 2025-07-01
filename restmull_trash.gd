extends Node2D

var textures: Array[Texture2D] = [
	preload("res://Assets/png/garbage bag/1.png"),
]

var trash_type = "restmull"

@onready var sprite = $RestmullSprite

var pending_texture_index: int = -1

func _ready():
	if pending_texture_index != -1:
		set_texture_index(pending_texture_index)

func set_texture_index(index: int):
	if index < 0 or index >= textures.size():
		push_warning("Texture index %d out of bounds for %s (max index %d)" % [index, trash_type, textures.size()-1])
		return
	
	if is_inside_tree():
		sprite.texture = textures[index]
	else:
		pending_texture_index = index
		
func get_texture_size():
	return textures.size()
