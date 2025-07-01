extends Area2D
@export var accepts_type: String = "paper"

signal trash_dropped(correct: bool)

func get_trash_type():
	return accepts_type
	
func validate_trash(trash_type : String):
	var correct = trash_type == accepts_type
	trash_dropped.emit(correct)
