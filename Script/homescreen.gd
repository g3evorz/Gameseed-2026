extends Control

@onready var confirmation_panel  = $ConfirmationPanel

func _on_button_play_pressed() -> void:
	SceneTransition.pindah_scene("res://Scenes/Upgradable.tscn")


func _on_button_settings_pressed() -> void:
	pass # Replace with function body.


func _on_button_exit_pressed() -> void:
	confirmation_panel.tampilkan("Quit Game?")


func _on_confirmation_panel_konfirmasi_ya() -> void:
	SceneTransition.animation_player.play("fade_in")
	await get_tree().create_timer(0.5).timeout
	get_tree().free()
