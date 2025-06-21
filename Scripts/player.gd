extends CharacterBody2D

var horizontal_velocity = 0
var speed = 150  # Movement speed
@onready var pickup_area = $PickupArea
@onready var anchor = $TrashAnchor
var held_trash: Node2D = null
var nearby_trash: Array[Node2D] = []
var nearby_dustbins: Array[Node2D] = []
var score = 0

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
		print("Drop key pressed by player %d" % multiplayer.get_unique_id())
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
		# Check if trash is already held by someone
		if trash.get_parent() != get_parent():  # If it's not in the main scene anymore
			print("Trash already picked up by someone else!")
			return
			
		# Send RPC to all players about pickup
		rpc("sync_pickup_trash", trash.get_path(), multiplayer.get_unique_id())

@rpc("any_peer", "call_local", "reliable")
func sync_pickup_trash(trash_path: NodePath, player_id: int):
	var trash = get_node(trash_path)
	if trash == null:
		print("Trash not found at path: ", trash_path)
		return
		
	# Find the player who picked it up
	var player = get_parent().get_node(str(player_id))
	if player == null:
		print("Player not found: ", player_id)
		return
		
	# Move trash to player's anchor
	trash.get_parent().remove_child(trash)
	player.anchor.add_child(trash)
	trash.position = Vector2.ZERO
	
	# Update held_trash for the picking player
	if player_id == multiplayer.get_unique_id():
		held_trash = trash
		
	print("Player %d picked up: %s" % [player_id, trash.name])

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
		var trash_name = held_trash.name
		
		print("Player %d attempting to drop trash: %s into %s bin" % [multiplayer.get_unique_id(), trash_type, bin_type])
		
		# Send RPC to sync the drop and score update
		rpc("sync_drop_trash", trash_name, multiplayer.get_unique_id(), bin_type, trash_type)

@rpc("any_peer", "call_local", "reliable")
func sync_drop_trash(trash_name: String, player_id: int, bin_type: String, trash_type: String):
	print("sync_drop_trash called: Player %d, Trash: %s, Bin: %s, Type: %s" % [player_id, trash_name, bin_type, trash_type])
	
	# Find the player who dropped the trash
	var player = get_parent().get_node_or_null(str(player_id))
	if player == null:
		print("Player not found: ", player_id)
		return
	
	# Find the trash in the player's anchor
	var trash = player.anchor.get_node_or_null(trash_name)
	if trash == null:
		print("Trash %s not found in player %d's anchor" % [trash_name, player_id])
		return
	
	# Calculate if it was correct
	var correct = (trash_type == bin_type)
	
	# Update score for the dropping player
	if correct:
		player.score += 1
	else:
		player.score -= 1
	
	print("Player %d dropped trash - Type: %s, Bin: %s, Correct: %s, New Score: %d" % [player_id, trash_type, bin_type, correct, player.score])
	
	# Remove the trash from the game
	trash.queue_free()
	
	# Clear held_trash for the dropping player
	if player_id == multiplayer.get_unique_id():
		held_trash = null
	else:
		player.held_trash = null
	
	# CHANGED: Request score update through server
	print("Requesting score update for player %d with score %d" % [player_id, player.score])
	get_parent().rpc("request_score_update", player_id, player.score)

func _on_pickup_area_entered(area):
	var trash = area.get_parent()
	if trash.is_in_group("Trash"):
		nearby_trash.append(trash)
			
func _on_pickup_area_exited(area):
	var trash = area.get_parent()	
	if trash.is_in_group("Trash"):
		nearby_trash.erase(trash)
	
func _on_bin_area_entered(area):
	if area.is_in_group("Dustbin"):
		nearby_dustbins.append(area)
		
func _on_bin_area_exited(area):
	if area.is_in_group("Dustbin"):
		nearby_dustbins.erase(area)
