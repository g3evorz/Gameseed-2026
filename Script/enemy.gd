extends StaticBody2D

@export var data: ObstacleData

var current_hp: int

func _ready():
	current_hp = data.max_hp
	
func take_damage(damage_amount: int):
	current_hp -= damage_amount
	
	print("CURRENT HP : ", current_hp)
	
	if current_hp <= 0:
		die()

# DESTROY OBJECT

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	print("Platform Terhapus !")
	queue_free()	

func die():
	queue_free()
