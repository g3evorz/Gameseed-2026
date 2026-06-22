extends StaticBody2D

var game_manager: Node2D = null

func _physics_process(delta):
	# Posisi x berkurang berdasarkan kecepatan global
	if game_manager != null:
		position.x -= game_manager.current_world_speed * delta

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	print("Platform Terhapus !")
	queue_free()	
