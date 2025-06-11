extends CharacterBody2D

var horizontal_velocity = 0

var speed = 150  # Movement speed

@onready var pickup_area = $PickupArea
@onready var anchor = $TrashAnchor
var held_trash: Node2D = null
var nearby_trash: Array[Node2D] = []

var nearby_dustbins: Array[Node2D] = []
var score  = 0
func _enter_tree():
	set_multiplayer_authority(int(str(name)))

func _ready():
	$AnimatedSprite2D.play()
	pickup_area.connect("area_entered", _on_pickup_area_entered)
	pickup_area.connect("area_exited", _on_pickup_area_exited)
	$BinDetectArea.connect("area_entered", _on_bin_area_entered)
	$BinDetectArea.connect("area_exited", _on_bin_area_exited)
	add_child($Camera2D)
func _process(delta):
	if !is_multiplayer_authority():
		return
	var velocity = Vector2.ZERO
	if Input.is_key_pressed(KEY_D):
		velocity.x += 1
		$AnimatedSprite2D.animation = "walk_right"
	if Input.is_key_pressed(KEY_A):
		velocity.x -= 1
	if Input.is_key_pressed(KEY_W):
		velocity.y -= 1
	if Input.is_key_pressed(KEY_S):
		velocity.y += 1
	if Input.is_action_just_pressed("interact"):
		if held_trash == null:
			pickup_trash()

	if Input.is_action_just_pressed("drop"):
		drop_trash()

	if velocity == Vector2.ZERO:
		$AnimatedSprite2D.animation = "idle"
		
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.stop()
		
	position += velocity * delta

func pickup_trash():
	if nearby_trash.size() > 0:
		var trash = nearby_trash[0]
		trash.get_parent().remove_child(trash)
		anchor.add_child(trash)
		trash.position = Vector2.ZERO
		held_trash = trash
		print("Picked up:", trash.name)



func drop_trash():
	if held_trash == null:
		print("No trash to drop!")
		return
	
	if nearby_dustbins.size() == 0:
		print("No dustbin nearby!")
		return
	if nearby_dustbins.size() > 0:
		var target_bin = nearby_dustbins[0]
		var bin_type = target_bin.get_trash_type()
		var trash_type = held_trash.trash_type
		
		if trash_type == bin_type:
			score += 1
			
		else:
			score = score - 1
		print(trash_type)
		print(bin_type)
		print(score)
		held_trash.queue_free()
		held_trash = null
	
func _on_pickup_area_entered(area):
	var parent = area.get_parent()
	var trash = area.get_parent()
	if trash.is_in_group("Trash"):
		nearby_trash.append(trash)
			
func _on_pickup_area_exited(area):
	var parent = area.get_parent()	
	var trash = area.get_parent()
	if trash.is_in_group("Trash"):
		nearby_trash.erase(trash)

	
func _on_bin_area_entered(area):
	if area.is_in_group("Dustbin"):
		nearby_dustbins.append(area)

func _on_bin_area_exited(area):
	if area.is_in_group("Dustbin"):
		nearby_dustbins.erase(area)
