extends Control


func _on_button_play_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Upgradable.tscn")


func _on_button_settings_pressed() -> void:
	pass # Replace with function body.


func _on_button_exit_pressed() -> void:
	get_tree().free()
