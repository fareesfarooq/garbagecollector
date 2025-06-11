extends Node2D

@export var paper_trash_scene = preload("res://PaperTrash.tscn")
@export var plastic_trash_scene = preload("res://PlasticTrash.tscn")
@export var organic_trash_scene = preload("res://OrganicTrash.tscn")

@export var spawn_interval: float = 2.0  # seconds
var screen_size = get_viewport_rect().size

func _ready():
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

func spawn_random_trash():
	var trash_scenes = [paper_trash_scene, plastic_trash_scene, organic_trash_scene]
	var chosen_scene = trash_scenes[randi() % trash_scenes.size()]

	
	var instance = chosen_scene.instantiate()
	instance.position = Vector2(randf_range(0, 1000), randf_range(0, 1000))

	get_parent().add_child(instance)
