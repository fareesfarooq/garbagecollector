extends Node2D

var textures: Array[Texture2D] = [
	preload("res://Assets/Standard Trash/trash_apple.png"),
	preload("res://Assets/Standard Trash/trash_bone.png"),
	preload("res://Assets/Standard Trash/trash_chese.png"),
	preload("res://Assets/Standard Trash/trash_bread.png")
]
@onready var sprite = $OrganicSprite

var trash_type = "organic"

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
