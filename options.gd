extends Control


func _on_multi_player_pressed():
	get_tree().change_scene_to_file("res://main.tscn")


func _on_options_pressed():
	get_tree().change_scene_to_file("res://options.tscn")


func _on_quit_pressed():
	get_tree().change_scene_to_file("res://menu.tscn")
	


func _on_volume_value_changed(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"),linear_to_db(value))
	AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master"))
	


func _on_resolution_item_selected(index):
	match index:
		0:
			DisplayServer.window_set_size(Vector2i(1920,1080))
		1:
			DisplayServer.window_set_size(Vector2i(1920,720))
		2:
			DisplayServer.window_set_size(Vector2i(800,600))
