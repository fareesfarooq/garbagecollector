extends Node2D
@onready var multiplayer_ui = $UI/Multiplayer
const PLAYER = preload("res://Player.tscn")
var player_instance = PLAYER.instantiate()
var peer = ENetMultiplayerPeer.new()
# CHANGED: Get labels more safely
var score1_label
var score2_label
	
var player_scores = {}  # Dictionary to track scores by player ID

func _ready():
	# CHANGED: Get labels in _ready instead of @onready
	score1_label = $ScoreUI/Score1
	score2_label = $ScoreUI/Score2
	
	# Initially hide score2 until second player joins
	score2_label.visible = false
	
	# Debug: Check if labels are found
	print("Score labels found - Score1: %s, Score2: %s" % [score1_label != null, score2_label != null])
	if score1_label:
		print("Score1 label initial text: '%s'" % score1_label.text)
	if score2_label:
		print("Score2 label initial text: '%s'" % score2_label.text)
	
func _on_host_pressed():
	peer.create_server(25565)
	multiplayer.multiplayer_peer = peer
	
	multiplayer.peer_connected.connect(
		func(pid):
			print("Peer " + str(pid) + " has joined the game!")
			add_player(pid)
			$TrashSpawner.send_trash_history_to_peer(pid)
			# Send current scores to the new peer
			send_scores_to_peer(pid)
			# Show second score when second player joins
			if get_child_count() >= 3:  # UI, TrashSpawner, Player1, Player2
				score2_label.visible = true
	)
	
	multiplayer.peer_disconnected.connect(
		func(pid):
			print("Peer " + str(pid) + " has left the game!")
			remove_player(pid)
			# Hide second score if only one player left
			if get_child_count() <= 3:  # UI, TrashSpawner, Player1
				score2_label.visible = false
	)
	add_player(multiplayer.get_unique_id())
	multiplayer_ui.hide()
	$TrashSpawner.set_multiplayer_authority(1)
	if multiplayer.get_unique_id() == 1:
		$TrashSpawner.start_spawning()

func _on_join_pressed():
	peer.create_client("localhost", 25565)
	multiplayer.multiplayer_peer = peer
	
	multiplayer.connected_to_server.connect(
		func():
			print("Connected to server!")
			# Hide multiplayer UI when connected
			multiplayer_ui.hide()
	)

func add_player(pid):
	var player = PLAYER.instantiate()
	player.name = str(pid)
	add_child(player)
	
	# Initialize score tracking
	player_scores[pid] = 0
	update_score_display()

func remove_player(pid):
	var player = get_node_or_null(str(pid))
	if player:
		player.queue_free()
	
	# Remove from score tracking
	if pid in player_scores:
		player_scores.erase(pid)
	
	update_score_display()

func update_player_score(player_id: int, new_score: int):
	player_scores[player_id] = new_score
	update_score_display()

# ADDED: New RPC method to synchronize score updates across all clients
@rpc("authority", "call_local", "reliable")  # CHANGED: Only authority can call this
func sync_score_update(player_id: int, new_score: int):
	# Ensure the player exists in the dictionary
	if not player_id in player_scores:
		player_scores[player_id] = 0
	
	player_scores[player_id] = new_score
	print("Score updated for player %d: %d (Total players: %d)" % [player_id, new_score, player_scores.size()])
	update_score_display()

# ADDED: New function for clients to request score updates
@rpc("any_peer", "call_remote", "reliable")
func request_score_update(player_id: int, new_score: int):
	# Only process on server
	if multiplayer.is_server():
		print("Server received score update request for player %d: %d" % [player_id, new_score])
		# Update locally and broadcast to all clients
		rpc("sync_score_update", player_id, new_score)

# ADDED: Send current scores to a newly connected peer
func send_scores_to_peer(peer_id: int):
	for player_id in player_scores.keys():
		rpc_id(peer_id, "sync_score_update", player_id, player_scores[player_id])

# ADDED: RPC to receive full score state (for clients)
@rpc("authority", "call_remote", "reliable")
func receive_score_state(scores_dict: Dictionary):
	player_scores = scores_dict.duplicate()
	update_score_display()

func update_score_display():
	var player_ids = player_scores.keys()
	player_ids.sort()
	
	print("Updating score display. Player IDs: %s, Scores: %s" % [player_ids, player_scores])
	
	# Check if labels exist
	if score1_label == null:
		print("ERROR: score1_label is null!")
		return
	if score2_label == null:
		print("ERROR: score2_label is null!")
		return
	
	# Always show at least the first player
	if player_ids.size() >= 1:
		var first_player_id = player_ids[0]
		var new_text = "Player 1: " + str(player_scores[first_player_id])
		score1_label.text = new_text
		score1_label.visible = true
		print("Score1 label updated: %s (visible: %s)" % [new_text, score1_label.visible])
	else:
		score1_label.visible = false
	
	# Show second player if exists
	if player_ids.size() >= 2:
		var second_player_id = player_ids[1]
		var new_text = "Player 2: " + str(player_scores[second_player_id])
		score2_label.text = new_text
		score2_label.visible = true
		print("Score2 label updated: %s (visible: %s)" % [new_text, score2_label.visible])
	else:
		score2_label.visible = false
		print("Score2 label hidden")
