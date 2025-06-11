extends CharacterBody2D

var speed = 150  # Movement speed
var pickup_range = 200

@onready var trash_sprite = get_node("/root/Node2D/TrashContainer/Sprite2D")
@onready var animated_sprite = $AnimatedSprite2D

func _enter_tree():
	set_multiplayer_authority(int(str(name)))

func _ready():
	animated_sprite.play()

func pickup():
	trash_sprite.reparent(self)
	trash_sprite.position = Vector2.ZERO

func _process(delta):
	if !is_multiplayer_authority():
		return

	var direction = Vector2.ZERO
	
	# Movement Input
	if Input.is_key_pressed(KEY_D):
		direction.x += 1
		animated_sprite.animation = "walk_right"
	if Input.is_key_pressed(KEY_A):
		direction.x -= 1
	if Input.is_key_pressed(KEY_W):
		direction.y -= 1
	if Input.is_key_pressed(KEY_S):
		direction.y += 1
	
	# Pickup Input
	if Input.is_key_pressed(KEY_E):
		var dist = global_position.distance_to(trash_sprite.global_position)
		if dist < pickup_range:
			pickup()

	# Animation & Movement
	if direction != Vector2.ZERO:
		direction = direction.normalized()
		animated_sprite.play()
	else:
		animated_sprite.animation = "idle"
		animated_sprite.stop()
	
	velocity = direction * speed
	move_and_slide()
