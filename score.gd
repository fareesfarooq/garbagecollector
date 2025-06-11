extends Node

var score: int = 0

func update_score(correct: bool):
	if correct:
		score += 1
	else:
		score -= 1
	print("Score:", score)
