extends StaticBody2D

@export var data: ObstacleData

var game_manager: Node2D = null
var current_hp: int

func _ready():
	current_hp = data.max_hp

func _physics_process(delta):
	# Object berjalan sendiri berdasarkan kecepatan global
	if game_manager != null:
		position.x -= game_manager.current_world_speed * delta

func take_damage(damage_amount: int):
	current_hp -= damage_amount
	
	if current_hp <= 0:
		die()

# DESTROY OBJECT

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	print("Platform Terhapus !")
	queue_free()	

func die():
	queue_free()
