extends Node2D

@onready var multiplayer_ui = $UI/Multiplayer
@onready var score_sound = $ScoreSound
const PLAYER = preload("res://Player.tscn")
var player_instance = PLAYER.instantiate()
var peer = ENetMultiplayerPeer.new()
var score1_label
var score2_label
var victory_ui  
var ip_text 	
var player_scores = {} 
var game_ended = false  
const WINNING_SCORE = 20 

func _ready():
	
	score1_label = $UI/ScoreUI/Score1
	score2_label = $UI/ScoreUI/Score2
	victory_ui = $UI/VictoryScreen
	ip_text = $UI/Multiplayer/VBoxContainer/LineEdit

	
	score2_label.visible = false
	if victory_ui:
		victory_ui.visible = false
	else:
		print("Warning: VictoryScreen not found at $UI/VictoryScreen")
	
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
			send_scores_to_peer(pid)
			if player_scores.size() >= 2:
				score2_label.visible = true
	)
	
	multiplayer.peer_disconnected.connect(
		func(pid):
			print("Peer " + str(pid) + " has left the game!")
			remove_player(pid)

			if player_scores.size() <= 1:
				score2_label.visible = false
	)
	add_player(multiplayer.get_unique_id())
	multiplayer_ui.hide()
	$TrashSpawner.set_multiplayer_authority(1)
	if multiplayer.get_unique_id() == 1:
		$TrashSpawner.start_spawning()

func _on_join_pressed():
	peer.create_client(str(ip_text.text), 25565)
	multiplayer.multiplayer_peer = peer
	
	multiplayer.connected_to_server.connect(
		func():
			print("Connected to server!")
			multiplayer_ui.hide()
	)

func add_player(pid):
	var player = PLAYER.instantiate()
	player.name = str(pid)
	add_child(player)

	player_scores[pid] = 0
	update_score_display()

func remove_player(pid):
	var player = get_node_or_null(str(pid))
	if player:
		player.queue_free()
	
	if pid in player_scores:
		player_scores.erase(pid)
	
	update_score_display()

func update_player_score(player_id: int, new_score: int):
	player_scores[player_id] = new_score
	update_score_display()

@rpc("authority", "call_local", "reliable") 

func sync_score_update(player_id: int, new_score: int):
	if not player_id in player_scores:
		player_scores[player_id] = 0
	
	var old_score = player_scores[player_id]
	player_scores[player_id] = new_score
	
	# Play sound if score increased
	if new_score > old_score:
		score_sound.play()
	
	print("Score updated for player %d: %d (Total players: %d)" % [player_id, new_score, player_scores.size()])
	update_score_display()
	check_victory_condition()
	

	

@rpc("any_peer", "call_remote", "reliable")
func request_score_update(player_id: int, new_score: int):
	if multiplayer.is_server():
		print("Server received score update request for player %d: %d" % [player_id, new_score])
		rpc("sync_score_update", player_id, new_score)

func send_scores_to_peer(peer_id: int):
	for player_id in player_scores.keys():
		rpc_id(peer_id, "sync_score_update", player_id, player_scores[player_id])

@rpc("authority", "call_remote", "reliable")
func receive_score_state(scores_dict: Dictionary):
	player_scores = scores_dict.duplicate()
	update_score_display()

func check_victory_condition():
	if game_ended:
		return 
	
	for player_id in player_scores.keys():
		if player_scores[player_id] >= WINNING_SCORE:
			rpc("show_victory_screen", player_id)
			return

@rpc("authority", "call_local", "reliable")
func show_victory_screen(winning_player_id: int):
	game_ended = true
	
	$TrashSpawner.stop_spawning()
	if victory_ui:
		victory_ui.visible = true
	
	
	print("Victory! Player %d wins with %d points!" % [winning_player_id, player_scores[winning_player_id]])

func get_player_number(player_id: int) -> int:
	var player_ids = player_scores.keys()
	player_ids.sort()
	
	for i in range(player_ids.size()):
		if player_ids[i] == player_id:
			return i + 1
	
	return 1

	
	for child in get_children():
		if child.is_in_group("Trash"):
			child.queue_free()
	
	$TrashSpawner.reset_spawner()
	
	if victory_ui:
		victory_ui.visible = false
	
	
	update_score_display()
	
	if multiplayer.is_server():
		$TrashSpawner.start_spawning()



func update_score_display():
	var player_ids = player_scores.keys()
	player_ids.sort()
	
	print("Updating score display. Player IDs: %s, Scores: %s" % [player_ids, player_scores])
	
	if score1_label == null:
		print("ERROR: score1_label is null!")
		return
	if score2_label == null:
		print("ERROR: score2_label is null!")
		return
	
	if player_ids.size() >= 1:
		var first_player_id = player_ids[0]
		var new_text = str(player_scores[first_player_id])
		score1_label.text = new_text
		score1_label.visible = true
		print("Score1 label updated: %s (visible: %s)" % [new_text, score1_label.visible])
	else:
		score1_label.visible = false
	
	if player_ids.size() >= 2:
		var second_player_id = player_ids[1]
		var new_text = str(player_scores[second_player_id])
		score2_label.text = new_text
		score2_label.visible = true
		print("Score2 label updated: %s (visible: %s)" % [new_text, score2_label.visible])
	else:
		score2_label.visible = false
		print("Score2 label hidden")
