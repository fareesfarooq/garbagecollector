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
var spawn_timer: Timer  # Reference to the spawning timer

func _ready():
	trash_scenes = [paper_trash_scene, plastic_trash_scene, organic_trash_scene, restmull_trash_scene]

func start_spawning():
	randomize()
	spawn_random_trash()
	start_timer()

func start_timer():
	# Remove existing timer if any
	if spawn_timer:
		spawn_timer.queue_free()
	
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.one_shot = false
	spawn_timer.autostart = true
	add_child(spawn_timer)
	spawn_timer.connect("timeout", Callable(self, "spawn_random_trash"))
# ADDED: Function to stop spawning trash
func stop_spawning():
	if spawn_timer:
		spawn_timer.stop()
		print("Trash spawning stopped")

# ADDED: Function to reset the spawner for game restart
func reset_spawner():
	# Stop current timer
	stop_spawning()
	
	# Reset counters
	trash_id_counter = 0
	active_trash_count = 0
	trash_history.clear()
	
	print("TrashSpawner reset")

@rpc("authority")
func spawn_random_trash():
	if active_trash_count >= max_trash_items:
		print("Maximum trash items reached (%d), skipping spawn" % max_trash_items)
		return
	
	var scene_index = randi() % trash_scenes.size()
	var chosen_scene = trash_scenes[scene_index]
	var temp_instance = chosen_scene.instantiate()
	var texture_index = randi() % temp_instance.get_texture_size()
	temp_instance.queue_free()  

	var pos = Vector2(randf_range(0, 1000), randf_range(0, 500))


	trash_id_counter += 1
	var trash_id = "Trash" + str(trash_id_counter)

	var instance = chosen_scene.instantiate()
	instance.name = trash_id 
	instance.position = pos
	instance.set_texture_index(texture_index)
	
	instance.connect("tree_exited", Callable(self, "_on_trash_removed"))
	
	get_parent().add_child(instance)
	
	active_trash_count += 1
	print("Spawned trash item. Active count: %d/%d" % [active_trash_count, max_trash_items])

	var trash_data = {
		"scene_index": scene_index,
		"pos": pos,
		"texture_index": texture_index,
		"trash_id": trash_id
	}
	trash_history.append(trash_data)

	
	rpc("rpc_spawn_trash", scene_index, [pos.x, pos.y], texture_index, trash_id)

@rpc("call_remote")
func rpc_spawn_trash(scene_index: int, pos_arr: Array, texture_index: int, trash_id: String):
	if is_multiplayer_authority():
		return  

	var pos = Vector2(pos_arr[0], pos_arr[1])
	var chosen_scene = trash_scenes[scene_index]
	var instance = chosen_scene.instantiate()
	instance.name = trash_id  # Set same unique name
	instance.position = pos
	instance.set_texture_index(texture_index)
	
	
	instance.connect("tree_exited", Callable(self, "_on_trash_removed"))
	
	get_parent().add_child(instance)
	
	
	active_trash_count += 1
	print("Received trash item. Active count: %d/%d" % [active_trash_count, max_trash_items])

func _on_trash_removed():
	active_trash_count -= 1
	print("Trash item removed. Active count: %d/%d" % [active_trash_count, max_trash_items])
	

	if active_trash_count < 0:
		active_trash_count = 0

func send_trash_history_to_peer(peer_id):
	for trash in trash_history:
		rpc_id(peer_id, "rpc_spawn_trash", trash.scene_index, [trash.pos.x, trash.pos.y], trash.texture_index, trash.trash_id)

func update_trash_count():
	var actual_count = 0
	for child in get_parent().get_children():
		if child.is_in_group("Trash"):
			actual_count += 1
	
	if actual_count != active_trash_count:
		print("Trash count mismatch! Tracked: %d, Actual: %d. Correcting..." % [active_trash_count, actual_count])
		active_trash_count = actual_count
		
		



	
