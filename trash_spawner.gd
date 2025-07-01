extends Node2D
@export var paper_trash_scene = preload("res://PaperTrash.tscn")
@export var plastic_trash_scene = preload("res://PlasticTrash.tscn")
@export var organic_trash_scene = preload("res://OrganicTrash.tscn")
@export var restmull_trash_scene = preload("res://restmull_trash.tscn")
@export var spawn_interval: float = 2.0  # seconds
@export var max_trash_items: int = 10  # Maximum trash items on screen
var screen_size = get_viewport_rect().size
var trash_history = []  # Stores {index, pos, texture_index, trash_id} dictionaries
var trash_scenes = []
var trash_id_counter = 0  # For unique trash naming
var active_trash_count = 0  # Track how many trash items are currently active

func _ready():
	trash_scenes = [paper_trash_scene, plastic_trash_scene, organic_trash_scene, restmull_trash_scene]

func start_spawning():
	randomize()
	spawn_random_trash()
	start_timer()

func start_timer():
	var timer = Timer.new()
	timer.wait_time = spawn_interval
	timer.one_shot = false
	timer.autostart = true
	add_child(timer)
	timer.connect("timeout", Callable(self, "spawn_random_trash"))


@rpc("authority")
func spawn_random_trash():
	# Check if we've reached the maximum number of trash items
	if active_trash_count >= max_trash_items:
		print("Maximum trash items reached (%d), skipping spawn" % max_trash_items)
		return
	
	var scene_index = randi() % trash_scenes.size()
	var chosen_scene = trash_scenes[scene_index]
	var temp_instance = chosen_scene.instantiate()
	var texture_index = randi() % temp_instance.get_texture_size()
	temp_instance.queue_free()  # Clean up temp instance

	var pos = Vector2(randf_range(0, 1000), randf_range(0, 500))

	# Generate unique trash ID
	trash_id_counter += 1
	var trash_id = "Trash" + str(trash_id_counter)

	var instance = chosen_scene.instantiate()
	instance.name = trash_id  # Set unique name
	instance.position = pos
	instance.set_texture_index(texture_index)
	
	# Connect to the trash item's tree_exited signal to track when it's removed
	instance.connect("tree_exited", Callable(self, "_on_trash_removed"))
	
	get_parent().add_child(instance)
	
	# Increment active trash count
	active_trash_count += 1
	print("Spawned trash item. Active count: %d/%d" % [active_trash_count, max_trash_items])

	var trash_data = {
		"scene_index": scene_index,
		"pos": pos,
		"texture_index": texture_index,
		"trash_id": trash_id
	}
	trash_history.append(trash_data)

	# Send to other players
	rpc("rpc_spawn_trash", scene_index, [pos.x, pos.y], texture_index, trash_id)

@rpc("call_remote")
func rpc_spawn_trash(scene_index: int, pos_arr: Array, texture_index: int, trash_id: String):
	if is_multiplayer_authority():
		return  # prevent re-spawn on server

	var pos = Vector2(pos_arr[0], pos_arr[1])
	var chosen_scene = trash_scenes[scene_index]
	var instance = chosen_scene.instantiate()
	instance.name = trash_id  # Set same unique name
	instance.position = pos
	instance.set_texture_index(texture_index)
	
	# Connect to the trash item's tree_exited signal to track when it's removed
	instance.connect("tree_exited", Callable(self, "_on_trash_removed"))
	
	get_parent().add_child(instance)
	
	# Increment active trash count for non-authority clients too
	active_trash_count += 1
	print("Received trash item. Active count: %d/%d" % [active_trash_count, max_trash_items])

func _on_trash_removed():
	# Decrement active trash count when a trash item is removed
	active_trash_count -= 1
	print("Trash item removed. Active count: %d/%d" % [active_trash_count, max_trash_items])
	
	# Ensure count doesn't go below 0
	if active_trash_count < 0:
		active_trash_count = 0

func send_trash_history_to_peer(peer_id):
	for trash in trash_history:
		rpc_id(peer_id, "rpc_spawn_trash", trash.scene_index, [trash.pos.x, trash.pos.y], trash.texture_index, trash.trash_id)

# Function to manually update trash count (useful for debugging or synchronization)
func update_trash_count():
	var actual_count = 0
	for child in get_parent().get_children():
		if child.is_in_group("Trash"):
			actual_count += 1
	
	if actual_count != active_trash_count:
		print("Trash count mismatch! Tracked: %d, Actual: %d. Correcting..." % [active_trash_count, actual_count])
		active_trash_count = actual_count
