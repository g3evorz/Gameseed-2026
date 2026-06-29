extends Control


func _on_button_play_pressed() -> void:
	SceneTransition.pindah_scene("res://Scenes/Upgradable.tscn")


func _on_button_settings_pressed() -> void:
	pass # Replace with function body.


func _on_button_exit_pressed() -> void:
	get_tree().free()
