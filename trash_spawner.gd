extends Node2D

@export var paper_trash_scene = preload("res://PaperTrash.tscn")
@export var plastic_trash_scene = preload("res://PlasticTrash.tscn")
@export var organic_trash_scene = preload("res://OrganicTrash.tscn")
@export var spawn_interval: float = 2.0  # seconds

var screen_size = get_viewport_rect().size
var trash_history = []  # Stores {index, pos, texture_index, trash_id} dictionaries
var trash_scenes = []
var trash_id_counter = 0  # For unique trash naming

func _ready():
	trash_scenes = [paper_trash_scene, plastic_trash_scene, organic_trash_scene]
	
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
	var scene_index = randi() % trash_scenes.size()
	var chosen_scene = trash_scenes[scene_index]
	var temp_instance = chosen_scene.instantiate()
	var texture_index = randi() % temp_instance.get_texture_size()
	temp_instance.queue_free()  # Clean up temp instance
	
	var pos = Vector2(randf_range(0, 1000), randf_range(0, 1000))
	
	# Generate unique trash ID
	trash_id_counter += 1
	var trash_id = "Trash_" + str(trash_id_counter)
	
	var instance = chosen_scene.instantiate()
	instance.name = trash_id  # Set unique name
	instance.position = pos
	instance.set_texture_index(texture_index)
	get_parent().add_child(instance)
	
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
	get_parent().add_child(instance)
		
func send_trash_history_to_peer(peer_id):
	for trash in trash_history:
		rpc_id(peer_id, "rpc_spawn_trash", trash.scene_index, [trash.pos.x, trash.pos.y], trash.texture_index, trash.trash_id)
