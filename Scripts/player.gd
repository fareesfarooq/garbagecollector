extends CharacterBody2D

var horizontal_velocity = 0
var speed = 150  # Movement speed

func _enter_tree():
	set_multiplayer_authority(int(str(name)))

@onready var trash_sprite = get_node("/root/Node2D/TrashScene/Sprite2D")
@onready var animated_sprite = $AnimatedSprite2D
var pickup_range = 200

func pickup():
	trash_sprite.reparent(self) 
	trash_sprite.position = Vector2.ZERO
	
		
func _ready():
	$AnimatedSprite2D.play()

var screen_size
func _process(delta):
	if !is_multiplayer_authority():
		return
	var velocity = Vector2.ZERO
	if Input.is_key_pressed(KEY_D):
		velocity.x += 1
		$AnimatedSprite2D.animation = "walk_right"
	if Input.is_key_pressed(KEY_A):
		velocity.x -= 1
		$AnimatedSprite2D.animation = "walk_left"
	if Input.is_key_pressed(KEY_W):
		velocity.y -= 1
		$AnimatedSprite2D.animation = "walk_up"

	if Input.is_key_pressed(KEY_S):
		velocity.y += 1
		$AnimatedSprite2D.animation = "walk_down"

	if velocity == Vector2.ZERO:
		$AnimatedSprite2D.animation = "idle"
		
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.stop()
		
	position += velocity * delta


		
