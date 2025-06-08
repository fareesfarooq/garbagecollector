extends Node

var trash_scenes = [
	preload("res://OrganicTrash.tscn"),
	preload("res://PlasticTrash.tscn"),
	preload("res://PaperTrash.tscn")
]

var spawn_interval = 2.0

func spawn_loop() -> void:
	while true:
		spawn_trash()
		await get_tree().create_timer(spawn_interval).timeout

func spawn_trash() -> void:
	var trash_scene = trash_scenes[randi() % trash_scenes.size()]
	var trash_instance = trash_scene.instantiate()

	# Random spawn position (adjust bounds as needed)
	trash_instance.position = Vector2(randf() * 800, randf() * 600)

	add_child(trash_instance)
	
func _ready():
	spawn_loop()
