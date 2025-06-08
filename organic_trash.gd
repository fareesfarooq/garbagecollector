extends Node2D

var trash_textures = [
	preload("res://Assets/Standard Trash/trash_apple.png"),
	preload("res://Assets/Standard Trash/trash_bone.png"),
	preload("res://Assets/Standard Trash/trash_chese.png"),
	preload("res://Assets/Standard Trash/trash_chese.png")
]

var picked_up = false
var player_in_range = false
var player_ref = null

func _ready():
	$OrganicSprite.texture = trash_textures[randi() % trash_textures.size()]
	$Area2D.body_entered.connect(_on_body_entered)
	$Area2D.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player") and not picked_up:
		player_in_range = true
		player_ref = body

func _on_body_exited(body):
	if body == player_ref:
		player_in_range = false
		player_ref = null
		
		
func _input(event):
	if player_in_range and not picked_up:
		if Input.is_key_pressed(KEY_E):
			pickup()


func pickup():
	picked_up = true
	get_parent().remove_child(self)
	player_ref.add_child(self)

	position = Vector2(16, -16)  
	scale = Vector2(0.5, 0.5)    
	$Area2D.monitoring = false 
