extends Control

@onready var confirmation_panel  = $ConfirmationPanel
@onready var settings_panel = $SettingsPanel
@onready var help_panel = $HelpPanel

@onready var mute_button = $SettingsPanel/ColorRect/MarginContainer/VBoxContainer/HBoxContainer/Mute
@onready var volume_slider = $SettingsPanel/ColorRect/MarginContainer/VBoxContainer/HBoxContainer2/VolumeSlider
@onready var anim_kepala = $TextureRect/Kereta/Kepala
@onready var anim_rel = $TextureRect/Rel

func _ready() -> void:
	anim_kepala.play("default")
	anim_rel.play("default")
	AudioManager.putar_musik(AudioManager.musik_homescreen)
	settings_panel.hide()
	help_panel.hide()
	mute_button.button_pressed = AudioManager.is_muted
	volume_slider.value = AudioManager.current_volume

func _on_button_play_pressed() -> void:
	AudioManager.putar_sfx(AudioManager.sfx_klik)
	if ScoreManager.sudah_lihat_intro == false:
		# Pindah ke scene Storyboard
		SceneTransition.pindah_scene("res://Scenes/StoryboardScene.tscn")
	else:
		# Langsung pindah ke Gameplay utama
		SceneTransition.pindah_scene("res://Scenes/Upgradable.tscn")


func _on_button_settings_pressed() -> void:
	AudioManager.putar_sfx(AudioManager.sfx_klik)
	settings_panel.show()


func _on_button_exit_pressed() -> void:
	AudioManager.putar_sfx(AudioManager.sfx_klik)
	confirmation_panel.tampilkan("Quit Game?")


func _on_confirmation_panel_konfirmasi_ya() -> void:
	AudioManager.putar_sfx(AudioManager.sfx_klik)
	SceneTransition.animation_player.play("fade_in")
	await get_tree().create_timer(0.5).timeout
	get_tree().free()


func _on_back_settings_pressed() -> void:
	AudioManager.putar_sfx(AudioManager.sfx_klik)
	settings_panel.hide()


# Sinyal saat HSlider digeser
func _on_volume_slider_value_changed(value):
	AudioManager.putar_sfx(AudioManager.sfx_klik)
	AudioManager.set_volume(value)


func _on_mute_toggled(toggled_on: bool) -> void:
	AudioManager.putar_sfx(AudioManager.sfx_klik)
	AudioManager.set_mute(toggled_on)


func _on_button_help_pressed() -> void:
	AudioManager.putar_sfx(AudioManager.sfx_klik)
	help_panel.show()


func _on_back_help_pressed() -> void:
	AudioManager.putar_sfx(AudioManager.sfx_klik)
	help_panel.hide()
