extends Node2D

@onready var score_manager = get_node("/root/main/Score")

func _ready():
	for bin in get_children():
		var area = bin.get_node("Area2D")
		if area and area.has_signal("trash_dropped"):
			area.trash_dropped.connect(_on_trash_dropped)

func _on_trash_dropped(correct: bool):
	score_manager.update_score(correct)
	
