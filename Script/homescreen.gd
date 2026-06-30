extends Control

@onready var confirmation_panel  = $ConfirmationPanel
@onready var settings_panel = $SettingsPanel

@onready var mute_button = $SettingsPanel/ColorRect/MarginContainer/VBoxContainer/HBoxContainer/Mute
@onready var volume_slider = $SettingsPanel/ColorRect/MarginContainer/VBoxContainer/HBoxContainer2/VolumeSlider

func _ready() -> void:
	settings_panel.hide()
	mute_button.button_pressed = AudioManager.is_muted
	volume_slider.value = AudioManager.current_volume

func _on_button_play_pressed() -> void:
	SceneTransition.pindah_scene("res://Scenes/Upgradable.tscn")


func _on_button_settings_pressed() -> void:
	settings_panel.show()


func _on_button_exit_pressed() -> void:
	confirmation_panel.tampilkan("Quit Game?")


func _on_confirmation_panel_konfirmasi_ya() -> void:
	SceneTransition.animation_player.play("fade_in")
	await get_tree().create_timer(0.5).timeout
	get_tree().free()


func _on_back_settings_pressed() -> void:
	settings_panel.hide()


# Sinyal saat HSlider digeser
func _on_volume_slider_value_changed(value):
	AudioManager.set_volume(value)


func _on_mute_toggled(toggled_on: bool) -> void:
	AudioManager.set_mute(toggled_on)
