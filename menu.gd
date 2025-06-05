extends Control

func _on_single_player_pressed() :
	get_tree().change_scene_to_file("res://main.tscn")

func _on_multi_player_pressed():
	get_tree().change_scene_to_file("res://main.tscn")


func _on_options_pressed():
	get_tree().change_scene_to_file("res://main.tscn")


func _on_quit_pressed():
	get_tree().quit()
	
