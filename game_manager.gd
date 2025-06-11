extends Node

var score = 0

func handle_trash_drop(correct: bool):
	score += correct ? 1 : -1
	print("Score is now:", score)
